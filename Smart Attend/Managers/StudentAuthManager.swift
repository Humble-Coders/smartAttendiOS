import Foundation
import Combine

final class StudentAuthManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentStudent: Student?
    @Published var isLoggedIn: Bool = false
    @Published var isLoading: Bool = true
    
    // MARK: - Initialization
    init() {
        checkExistingLogin()
    }
    
    // MARK: - Public Methods
    
    /// Login student and save credentials
    func login(name: String, rollNumber: String, className: String) -> Bool {
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
        
        return true
    }
    
    /// Logout student and clear all data
    func logout() {
        // Clear secure storage
        _ = KeychainHelper.clearAllKeychainData()
        UserDefaultsManager.clearUserData()
        
        // Update state
        DispatchQueue.main.async {
            self.currentStudent = nil
            self.isLoggedIn = false
        }
        
        print("👋 Student logged out successfully")
    }
    
    /// Check for existing login on app start
    func checkExistingLogin() {
        isLoading = true
        let startTime = Date()
        
        // Minimum splash duration for branding (2 seconds)
        let minimumSplashDuration: TimeInterval = 4
        
        // Perform actual login check
        DispatchQueue.global(qos: .userInitiated).async {
            // Check if we have valid stored data
            guard UserDefaultsManager.isStoredDataValid(),
                  let name = UserDefaultsManager.getStudentName(),
                  let className = UserDefaultsManager.getStudentClassName(),
                  let rollNumber = KeychainHelper.getRollNumber() else {
                
                // Calculate remaining time to show splash
                let elapsed = Date().timeIntervalSince(startTime)
                let remainingTime = max(0, minimumSplashDuration - elapsed)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + remainingTime) {
                    self.isLoading = false
                    self.isLoggedIn = false
                    self.currentStudent = nil
                }
                
                print("ℹ️ No valid stored login found")
                return
            }
            
            // Restore student session
            let student = Student(
                name: name,
                rollNumber: rollNumber,
                className: className
            )
            
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
        }
    }
    
    /// Force refresh login check
    func refreshLoginStatus() {
        checkExistingLogin()
    }
    
    // MARK: - Private Methods
    
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
