import Foundation
import Combine

class AttendanceManager: ObservableObject {
    
    // MARK: - Published Properties
    @Published var currentSession: AttendanceSession?
    @Published var showingConfirmation = false
    @Published var showingFaceAuthentication = false
    @Published var showingSuccess = false
    @Published var completedSessions: [AttendanceSession] = []
    
    // MARK: - Private Properties
    private var cancellables = Set<AnyCancellable>()
    
    // MARK: - Error State Properties (ADD TO EXISTING CLASS)
    @Published var showingError = false
    @Published var currentError: FaceIOError?
    
    // MARK: - Public Methods
    
    /// Start attendance process for detected device
    func startAttendanceProcess(for device: BLEDevice) {
        guard let subjectCode = device.subjectCode, subjectCode != "No Data" else {
            print("❌ Cannot start attendance - no valid subject code")
            return
        }
        
        print("🎯 Starting attendance process for subject: \(subjectCode)")
        
        // Create new session
        currentSession = AttendanceSession(device: device, subjectCode: subjectCode)
        
        // Show confirmation dialog
        showingConfirmation = true
    }
    
    /// User confirmed attendance marking
    func confirmAttendance() {
        guard currentSession != nil else { return }
        
        print("✅ User confirmed attendance marking")
        
        // Hide confirmation and show face authentication
        showingConfirmation = false
        
        // Small delay for smooth transition
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingFaceAuthentication = true
        }
    }
    
    /// User cancelled attendance marking
    func cancelAttendance() {
        print("❌ User cancelled attendance marking")
        
        showingConfirmation = false
        currentSession = nil
    }
    
    /// Handle successful face authentication
    func handleFaceAuthenticationSuccess(rollNumber: String) {
        guard var session = currentSession else {
            print("❌ No current session for face authentication success")
            return
        }
        
        print("✅ Face authentication successful for roll number: \(rollNumber)")
        
        // Complete the session
        let result = FaceIOResult(
            rollNumber: rollNumber,
            success: true,
            message: "Face authentication successful"
        )
        
        session.complete(with: result)
        currentSession = session
        
        // Add to completed sessions
        completedSessions.insert(session, at: 0)
        
        // Hide face authentication and show success
        showingFaceAuthentication = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingSuccess = true
        }
        
        // Log attendance marked
        logAttendanceMarked(session: session)
    }
    
    /// Handle face authentication error with proper error state management
    func handleFaceAuthenticationError(_ error: String) {
        print("❌ Face authentication error: \(error)")
        
        // Parse error to FaceIOError if it's a numeric code
        let faceIOError: FaceIOError
        if let errorCode = Int(error) {
            faceIOError = FaceIOError.fromErrorCode(errorCode)
        } else {
            // Handle string errors
            faceIOError = parseFaceIOError(from: error)
        }
        
        // Set error state
        currentError = faceIOError
        
        // Hide face authentication and show error
        showingFaceAuthentication = false
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingError = true
        }
    }
    
    /// Handle retry from error screen
    func retryFaceAuthentication() {
        print("🔄 Retrying face authentication")
        
        // Hide error screen
        showingError = false
        currentError = nil
        
        // Small delay for smooth transition, then show face authentication again
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.showingFaceAuthentication = true
        }
    }
    
    /// Dismiss error screen and return to home
    func dismissError() {
        print("🏠 Dismissing error and returning to home")
        
        showingError = false
        currentError = nil
        currentSession = nil
    }
    
    // MARK: - Private Helper Method (ADD TO EXISTING CLASS)

    /// Parse string errors to FaceIOError
    private func parseFaceIOError(from errorString: String) -> FaceIOError {
        let lowercaseError = errorString.lowercased()
        
        if lowercaseError.contains("camera") && lowercaseError.contains("permission") {
            return .cameraPermissionDenied
        } else if lowercaseError.contains("no face") || lowercaseError.contains("face not detected") {
            return .noFaceDetected
        } else if lowercaseError.contains("not recognized") || lowercaseError.contains("face not recognized") {
            return .faceNotRecognized
        } else if lowercaseError.contains("multiple") {
            return .multipleFacesDetected
        } else if lowercaseError.contains("spoof") {
            return .faceSpoofingDetected
        } else if lowercaseError.contains("network") || lowercaseError.contains("connection") {
            return .networkError
        } else if lowercaseError.contains("unauthorized") {
            return .unauthorized
        } else if lowercaseError.contains("timeout") || lowercaseError.contains("timed out") {
            return .operationTimedOut
        } else if lowercaseError.contains("session") && lowercaseError.contains("expired") {
            return .sessionExpired
        } else if lowercaseError.contains("too many") {
            return .tooManyRequests
        } else if lowercaseError.contains("initialization") || lowercaseError.contains("initialize") {
            return .initializationFailed
        } else if lowercaseError.contains("cancelled") || lowercaseError.contains("closed") {
            return .processingError
        } else {
            return .unknown(code: 0)
        }
    }
    
    /// Dismiss success screen and return to home
    func dismissSuccess() {
        print("🏠 Returning to home screen")
        
        showingSuccess = false
        currentSession = nil
    }
    
    /// Get attendance history for a specific subject
    func getAttendanceHistory(for subjectCode: String) -> [AttendanceSession] {
        return completedSessions.filter { $0.subjectCode == subjectCode }
    }
    
    /// Get total attendance count
    func getTotalAttendanceCount() -> Int {
        return completedSessions.count
    }
    
    /// Check if attendance was already marked today for a subject
    func isAttendanceMarkedToday(for subjectCode: String) -> Bool {
        let today = Calendar.current.startOfDay(for: Date())
        
        return completedSessions.contains { session in
            session.subjectCode == subjectCode &&
            Calendar.current.isDate(session.startTime, inSameDayAs: today)
        }
    }
    
    // MARK: - Private Methods
    
    private func logAttendanceMarked(session: AttendanceSession) {
        guard let result = session.faceIOResult else { return }
        
        print("📝 ATTENDANCE MARKED:")
        print("   👤 Roll Number: \(result.rollNumber)")
        print("   📚 Subject: \(session.subjectCode)")
        print("   📱 Device: \(session.device.name)")
        print("   🕐 Time: \(formatDateTime(session.startTime))")
        print("   📶 Signal: \(session.device.rssi) dBm")
    }
    
    private func formatDateTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    // MARK: - Data Persistence (Future Enhancement)
    
    /// Save attendance data to local storage
    private func saveAttendanceData() {
        // TODO: Implement local storage using UserDefaults or Core Data
        // This would persist attendance records between app launches
    }
    
    /// Load attendance data from local storage
    private func loadAttendanceData() {
        // TODO: Implement loading from local storage
        // This would restore attendance history when app launches
    }
}
