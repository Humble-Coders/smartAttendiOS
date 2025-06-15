import Foundation
import FirebaseFirestore
import FirebaseCore
import Combine

// MARK: - Session Data Models
struct ActiveSession {
    let isActive: Bool
    let subject: String
    let room: String
    let type: String // "lect", "lab", "tut"
    let sessionId: String
    let date: String
    
    init(from data: [String: Any]) {
        self.isActive = data["isActive"] as? Bool ?? false
        self.subject = data["subject"] as? String ?? ""
        self.room = data["room"] as? String ?? ""
        self.type = data["type"] as? String ?? ""
        self.sessionId = data["sessionId"] as? String ?? ""
        self.date = data["date"] as? String ?? ""
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
    
    func toDictionary() -> [String: Any] {
        var dict: [String: Any] = [
            "date": date,
            "rollNumber": rollNumber,
            "subject": subject,
            "group": group,
            "type": type,
            "present": present
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

// MARK: - Firebase Manager
class FirebaseManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var activeSession: ActiveSession?
    @Published var isSessionActive: Bool = false
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // MARK: - Private Properties
    private let db = Firestore.firestore()
    
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
    
    // MARK: - Attendance Marking
    
    /// Mark attendance for a student
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
            deviceRoom: detectedDevice.name // Store the full device name (room + 3 digits)
        )
        
        // Check if attendance already marked today
        checkIfAttendanceAlreadyMarked(
            collectionName: collectionName,
            rollNumber: student.rollNumber,
            subject: session.subject,
            date: dateString
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
                        print("   🏢 Device Room: \(detectedDevice.name)")
                        print("   📅 Date: \(dateString)")
                        print("   🕐 Time: \(currentDate)")
                    }
                }
        }
    }
    
    private func checkIfAttendanceAlreadyMarked(
        collectionName: String,
        rollNumber: String,
        subject: String,
        date: String,
        completion: @escaping (Bool) -> Void
    ) {
        db.collection(collectionName)
            .whereField("rollNumber", isEqualTo: rollNumber)
            .whereField("subject", isEqualTo: subject)
            .whereField("date", isEqualTo: date)
            .whereField("present", isEqualTo: true)
            .getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking existing attendance: \(error)")
                    completion(false) // Assume not marked to avoid blocking
                    return
                }
                
                let alreadyMarked = !(snapshot?.documents.isEmpty ?? true)
                if alreadyMarked {
                    print("⚠️ Attendance already marked for today")
                }
                completion(alreadyMarked)
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

// MARK: - Custom Errors
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

// MARK: - Firebase Configuration Helper
class FirebaseConfig {
    static func configure() {
        // Configure Firebase here if not already done in AppDelegate
        if FirebaseApp.app() == nil {
            FirebaseApp.configure()
        }
    }
}
