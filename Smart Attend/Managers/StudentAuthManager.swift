import Foundation
import Combine
import FirebaseFirestore

final class StudentAuthManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStudent: Student?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    @Published var faceRegistrationResult: FaceRegistrationResult?
    @Published var faceRecognitionEnabled: Bool = true // New property for face recognition toggle
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Initialization
    init() {
        checkExistingLogin()
    }
    
    // MARK: - Public Methods
    
    /// Login student and save credentials
    func login(name: String, rollNumber: String, className: String, faceRegistrationResult: FaceRegistrationResult? = nil) -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRoll = rollNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClass = className.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Validation
        guard validateLoginData(name: trimmedName, rollNumber: trimmedRoll, className: trimmedClass) else {
            return false
        }
        
        // Save to secure storage
        guard KeychainHelper.saveRollNumber(trimmedRoll) else {
            print("❌ Failed to save roll number to keychain")
            return false
        }
        
        UserDefaultsManager.saveStudentData(name: trimmedName, className: trimmedClass)
        
        // Save face registration result if provided
        if let faceResult = faceRegistrationResult {
            self.faceRegistrationResult = faceResult
            UserDefaultsManager.saveFaceRegistrationData(faceId: faceResult.faceId)
        }
        
        // Update current state
        let student = Student(
            name: trimmedName,
            rollNumber: trimmedRoll,
            className: trimmedClass
        )
        
        DispatchQueue.main.async {
            self.currentStudent = student
            self.isLoggedIn = true
        }
        
        print("✅ Student login successful:")
        print("   👤 Name: \(trimmedName)")
        print("   🎓 Roll: \(trimmedRoll)")
        print("   📚 Class: \(trimmedClass)")
        print("   🔧 Face Recognition: \(faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
        
        return true
    }
    
    /// Logout student and clear all data
    func logout() {
        // Clear secure storage
        _ = KeychainHelper.clearAllKeychainData()
        UserDefaultsManager.clearUserData()
        
        self.faceRegistrationResult = nil
        
        // Update state
        DispatchQueue.main.async {
            self.currentStudent = nil
            self.isLoggedIn = false
        }
        
        print("👋 Student logged out successfully")
    }
    
    /// Check for existing login on app start with face recognition toggle check
    func checkExistingLogin() {
        isLoading = true
        let startTime = Date()
        
        // Minimum splash duration for branding and toggle checking (4 seconds)
        let minimumSplashDuration: TimeInterval = 4
        
        // Perform login check and face recognition toggle check concurrently
        DispatchQueue.global(qos: .userInitiated).async {
            // Create a task group to handle both operations
            Task {
                // Check face recognition toggle first
                await self.checkFaceRecognitionToggleInternal()
                
                // Then check existing login
                let hasValidLogin = self.hasValidStoredLogin()
                
                if hasValidLogin {
                    // Restore student session
                    let (name, rollNumber, className) = self.getStoredLoginData()!
                    let student = Student(
                        name: name,
                        rollNumber: rollNumber,
                        className: className
                    )
                    
                    // Restore face registration data if available
                    let faceId = UserDefaultsManager.getFaceRegistrationId()
                    if let faceId = faceId {
                        self.faceRegistrationResult = FaceRegistrationResult(
                            rollNumber: rollNumber,
                            faceId: faceId
                        )
                    }
                    
                    // Calculate remaining time to show splash
                    let elapsed = Date().timeIntervalSince(startTime)
                    let remainingTime = max(0, minimumSplashDuration - elapsed)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                        self.currentStudent = student
                        self.isLoggedIn = true
                        self.isLoading = false
                    }
                    
                    print("✅ Restored student session:")
                    print("   👤 Name: \(name)")
                    print("   🎓 Roll: \(rollNumber)")
                    print("   📚 Class: \(className)")
                    print("   🔧 Face Recognition: \(self.faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
                    if let faceId = faceId {
                        print("   🔐 Face ID: \(String(faceId.prefix(8)))...")
                    }
                } else {
                    // Calculate remaining time to show splash
                    let elapsed = Date().timeIntervalSince(startTime)
                    let remainingTime = max(0, minimumSplashDuration - elapsed)
                    
                    DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                        self.isLoading = false
                        self.isLoggedIn = false
                        self.currentStudent = nil
                        self.faceRegistrationResult = nil
                    }
                    
                    print("ℹ️ No valid stored login found")
                    print("🔧 Face Recognition: \(self.faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
                }
            }
        }
    }
    
    /// Force refresh login check
    func refreshLoginStatus() {
        checkExistingLogin()
    }
    
    // MARK: - Private Methods
    
    /// Check face recognition toggle from Firebase
    private func checkFaceRecognitionToggleInternal() async {
        do {
            let document = try await db.collection("adminToggles").document("faceRecognition").getDocument()
            
            await MainActor.run {
                if document.exists, let data = document.data() {
                    let toggles = AdminToggles(from: data)
                    self.faceRecognitionEnabled = toggles.faceRecognitionEnabled
                    
                    print("🔧 Auth Manager - Face Recognition Toggle: \(toggles.faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
                } else {
                    self.faceRecognitionEnabled = true // Default to enabled if document doesn't exist
                    print("🔧 Auth Manager - Face Recognition Toggle document not found - defaulting to ENABLED")
                }
            }
        } catch {
            await MainActor.run {
                self.faceRecognitionEnabled = true // Default to enabled on error
                print("❌ Auth Manager - Error checking face recognition toggle: \(error) - defaulting to ENABLED")
            }
        }
    }
    
    /// Check if we have valid stored login data
    private func hasValidStoredLogin() -> Bool {
        return UserDefaultsManager.isStoredDataValid() &&
               UserDefaultsManager.getStudentName() != nil &&
               UserDefaultsManager.getStudentClassName() != nil &&
               KeychainHelper.getRollNumber() != nil
    }
    
    /// Get stored login data
    private func getStoredLoginData() -> (String, String, String)? {
        guard let name = UserDefaultsManager.getStudentName(),
              let className = UserDefaultsManager.getStudentClassName(),
              let rollNumber = KeychainHelper.getRollNumber() else {
            return nil
        }
        
        return (name, rollNumber, className)
    }
    
    private func validateLoginData(name: String, rollNumber: String, className: String) -> Bool {
        guard name.count >= 2 else {
            print("❌ Invalid name: too short")
            return false
        }
        
        guard rollNumber.count >= 4 else {
            print("❌ Invalid roll number: too short")
            return false
        }
        
        guard className.count >= 2 else {
            print("❌ Invalid class name: too short")
            return false
        }
        
        // Additional validation for roll number format
        guard rollNumber.allSatisfy({ $0.isNumber || $0.isLetter }) else {
            print("❌ Invalid roll number: contains invalid characters")
            return false
        }
        
        return true
    }
}


