import Foundation
import FirebaseFirestore
import FirebaseCore
import Combine

// MARK: - Admin Toggles Model
struct AdminToggles {
    let faceRecognitionEnabled: Bool
    
    init(from data: [String: Any]) {
        self.faceRecognitionEnabled = data["isActivated"] as? Bool ?? true // Default to true for safety
    }
}

// MARK: - Session Data Models (keep existing)
struct ActiveSession {
    let isActive: Bool
    let subject: String
    let room: String
    let type: String // "lect", "lab", "tut"
    let sessionId: String
    let date: String
    let isExtra: Bool? // New field for extra classes
    
    init(from data: [String: Any]) {
        self.isActive = data["isActive"] as? Bool ?? false
        self.subject = data["subject"] as? String ?? ""
        self.room = data["room"] as? String ?? ""
        self.type = data["type"] as? String ?? ""
        self.sessionId = data["sessionId"] as? String ?? ""
        self.date = data["date"] as? String ?? ""
        self.isExtra = data["isExtra"] as? Bool // New field
    }
}

struct AttendanceRecord {
    let date: String
    let rollNumber: String
    let subject: String
    let group: String
    let type: String
    let present: Bool
    let timestamp: Date?
    let deviceRoom: String? // Room number with 3 digits from BLE device
    let isExtra: Bool // New field for extra classes
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "date": date,
            "rollNumber": rollNumber,
            "subject": subject,
            "group": group,
            "type": type,
            "present": present,
            "isExtra": isExtra
        ]
        
        if let timestamp = timestamp {
            dict["timestamp"] = Timestamp(date: timestamp)
        }
        
        if let deviceRoom = deviceRoom {
            dict["deviceRoom"] = deviceRoom
        }
        
        return dict
    }
}

// MARK: - Enhanced Firebase Manager
class FirebaseManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeSession: ActiveSession?
    @Published var isSessionActive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var faceRecognitionEnabled: Bool = true // New property for face recognition toggle
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
    // MARK: - Admin Toggles Checking
    
    /// Check face recognition toggle from Firebase
    func checkFaceRecognitionToggle() async {
        do {
            let document = try await db.collection("adminToggles").document("faceRecognition").getDocument()
            
            await MainActor.run {
                if document.exists, let data = document.data() {
                    let toggles = AdminToggles(from: data)
                    self.faceRecognitionEnabled = toggles.faceRecognitionEnabled
                    
                    print("🔧 Face Recognition Toggle Status: \(toggles.faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
                } else {
                    self.faceRecognitionEnabled = true // Default to enabled if document doesn't exist
                    print("🔧 Face Recognition Toggle document not found - defaulting to ENABLED")
                }
            }
        } catch {
            await MainActor.run {
                self.faceRecognitionEnabled = true // Default to enabled on error
                print("❌ Error checking face recognition toggle: \(error) - defaulting to ENABLED")
            }
        }
    }
    
    // MARK: - Session Checking
    
    /// Check if there's an active session for the student's class
    func checkActiveSession(for className: String) async {
        await MainActor.run {
            isLoading = true
            errorMessage = nil
        }
        
        do {
            let document = try await db.collection("activeSessions").document(className).getDocument()
            
            await MainActor.run {
                if document.exists, let data = document.data() {
                    let session = ActiveSession(from: data)
                    self.activeSession = session
                    self.isSessionActive = session.isActive
                    
                    print("📚 Session Status for \(className):")
                    print("   🔄 Active: \(session.isActive)")
                    print("   📖 Subject: \(session.subject)")
                    print("   🏢 Room: \(session.room)")
                    print("   📝 Type: \(session.type)")
                    print("   ⭐ Extra: \(session.isExtra ?? false)")
                } else {
                    self.activeSession = nil
                    self.isSessionActive = false
                    print("📚 No active session found for class: \(className)")
                }
                
                isLoading = false
            }
        } catch {
            await MainActor.run {
                self.errorMessage = "Failed to check session: \(error.localizedDescription)"
                self.isLoading = false
                print("❌ Error checking session: \(error)")
            }
        }
    }
    
    // MARK: - Enhanced Attendance Marking
    
    /// Mark attendance for a student with enhanced duplicate checking
    func markAttendance(
        student: Student,
        session: ActiveSession,
        detectedDevice: BLEDevice,
        completion: @escaping (Result<Void, Error>) -> Void
    ) {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate)
        
        // Create monthly collection name
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy_MM"
        let monthString = monthFormatter.string(from: currentDate)
        let collectionName = "attendance_\(monthString)"
        
        // Create attendance record
        let attendanceRecord = AttendanceRecord(
            date: dateString,
            rollNumber: student.rollNumber,
            subject: session.subject,
            group: student.className,
            type: session.type,
            present: true,
            timestamp: currentDate,
            deviceRoom: detectedDevice.name,
            isExtra: session.isExtra ?? false
        )
        
        // Enhanced duplicate check considering type and isExtra
        checkIfAttendanceAlreadyMarked(
            collectionName: collectionName,
            rollNumber: student.rollNumber,
            subject: session.subject,
            type: session.type,
            date: dateString,
            isExtra: session.isExtra ?? false
        ) { [weak self] alreadyMarked in
            
            if alreadyMarked {
                completion(.failure(AttendanceError.alreadyMarked))
                return
            }
            
            // Mark attendance
            self?.db.collection(collectionName)
                .addDocument(data: attendanceRecord.toDictionary()) { error in
                    if let error = error {
                        completion(.failure(error))
                        print("❌ Failed to mark attendance: \(error)")
                    } else {
                        completion(.success(()))
                        print("✅ Attendance marked successfully!")
                        print("   👤 Student: \(student.rollNumber)")
                        print("   📚 Subject: \(session.subject)")
                        print("   📝 Type: \(session.type)")
                        print("   🏢 Device Room: \(detectedDevice.name)")
                        print("   📅 Date: \(dateString)")
                        print("   ⭐ Extra: \(session.isExtra ?? false)")
                        print("   🕐 Time: \(currentDate)")
                        print("   🔧 Face Recognition: \(self?.faceRecognitionEnabled == true ? "ENABLED" : "DISABLED")")
                    }
                }
        }
    }
    
    /// Enhanced duplicate check with type and extra class support
    private func checkIfAttendanceAlreadyMarked(
        collectionName: String,
        rollNumber: String,
        subject: String,
        type: String,
        date: String,
        isExtra: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        // Build base query
        let baseQuery = db.collection(collectionName)
            .whereField("rollNumber", isEqualTo: rollNumber)
            .whereField("subject", isEqualTo: subject)
            .whereField("date", isEqualTo: date)
            .whereField("present", isEqualTo: true)
        
        if isExtra {
            // For extra classes: Check if ANY extra class already marked for this subject today
            let extraQuery = baseQuery.whereField("isExtra", isEqualTo: true)
            
            extraQuery.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking existing extra attendance: \(error)")
                    completion(false) // Assume not marked to avoid blocking
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let alreadyMarked = !documents.isEmpty
                
                if alreadyMarked {
                    print("⚠️ Extra class attendance already marked for \(subject) today")
                } else {
                    print("✅ No extra class attendance found for \(subject) today - proceeding")
                }
                completion(alreadyMarked)
            }
        } else {
            // For regular classes: Check if same type already marked (exclude extra classes)
            let regularQuery = baseQuery
                .whereField("type", isEqualTo: type)
                .whereField("isExtra", isEqualTo: false)
            
            regularQuery.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking existing regular attendance: \(error)")
                    completion(false) // Assume not marked to avoid blocking
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let alreadyMarked = !documents.isEmpty
                
                if alreadyMarked {
                    print("⚠️ Regular \(type) attendance already marked today")
                } else {
                    print("✅ No \(type) attendance found for today - proceeding")
                }
                completion(alreadyMarked)
            }
        }
    }
    
    // MARK: - Utility Methods
    
    /// Reset session state
    func resetSession() {
        activeSession = nil
        isSessionActive = false
        errorMessage = nil
    }
    
    /// Get current date string in Firebase format
    private func getCurrentDateString() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd"
        return formatter.string(from: Date())
    }
}

// MARK: - Custom Errors (keep existing)
enum AttendanceError: LocalizedError {
    case alreadyMarked
    case noActiveSession
    case invalidSession
    
    var errorDescription: String? {
        switch self {
        case .alreadyMarked:
            return "Attendance already marked for today"
        case .noActiveSession:
            return "No active session found"
        case .invalidSession:
            return "Invalid session data"
        }
    }
}

// MARK: - Firebase Configuration Helper (keep existing)
class FirebaseConfig {
    static func configure() {
        // Configure Firebase here if not already done in AppDelegate
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
