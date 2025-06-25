import Foundation

final class UserDefaultsManager {
    
    // MARK: - Keys
    private enum Keys {
        static let studentName = "student_name"
        static let studentClassName = "student_class_name"
        static let isLoggedIn = "is_logged_in"
        static let lastLoginDate = "last_login_date"
        static let faceRegistrationId = "face_registration_id"
        static let faceRegistrationDate = "face_registration_date"
    }
    
    // MARK: - Student Data Methods
    
    /// Save student data (non-sensitive)
    static func saveStudentData(name: String, className: String) {
        UserDefaults.standard.set(name, forKey: Keys.studentName)
        UserDefaults.standard.set(className, forKey: Keys.studentClassName)
        UserDefaults.standard.set(true, forKey: Keys.isLoggedIn)
        UserDefaults.standard.set(Date(), forKey: Keys.lastLoginDate)
    }
    
    /// Get student name
    static func getStudentName() -> String? {
        return UserDefaults.standard.string(forKey: Keys.studentName)
    }
    
    /// Get student class name
    static func getStudentClassName() -> String? {
        return UserDefaults.standard.string(forKey: Keys.studentClassName)
    }
    
    /// Check if user is logged in
    static func isLoggedIn() -> Bool {
        return UserDefaults.standard.bool(forKey: Keys.isLoggedIn)
    }
    
    /// Get last login date
    static func getLastLoginDate() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.lastLoginDate) as? Date
    }
    
    // MARK: - Face Registration Methods
    
    /// Save face registration data
    static func saveFaceRegistrationData(faceId: String) {
        UserDefaults.standard.set(faceId, forKey: Keys.faceRegistrationId)
        UserDefaults.standard.set(Date(), forKey: Keys.faceRegistrationDate)
    }
    
    /// Get face registration ID
    static func getFaceRegistrationId() -> String? {
        return UserDefaults.standard.string(forKey: Keys.faceRegistrationId)
    }
    
    /// Get face registration date
    static func getFaceRegistrationDate() -> Date? {
        return UserDefaults.standard.object(forKey: Keys.faceRegistrationDate) as? Date
    }
    
    /// Check if face is registered
    static func isFaceRegistered() -> Bool {
        return getFaceRegistrationId() != nil
    }
    
    // MARK: - Logout Methods
    
    /// Clear all user data
    static func clearUserData() {
        UserDefaults.standard.removeObject(forKey: Keys.studentName)
        UserDefaults.standard.removeObject(forKey: Keys.studentClassName)
        UserDefaults.standard.removeObject(forKey: Keys.isLoggedIn)
        UserDefaults.standard.removeObject(forKey: Keys.lastLoginDate)
        UserDefaults.standard.removeObject(forKey: Keys.faceRegistrationId)
        UserDefaults.standard.removeObject(forKey: Keys.faceRegistrationDate)
    }
    
    // MARK: - Validation Methods
    
    /// Check if stored data is valid and recent
    static func isStoredDataValid() -> Bool {
        guard isLoggedIn(),
              getStudentName() != nil,
              getStudentClassName() != nil,
              let lastLogin = getLastLoginDate() else {
            return false
        }
        
        // Check if login is not older than 30 days for security
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        return lastLogin > thirtyDaysAgo
    }
}
