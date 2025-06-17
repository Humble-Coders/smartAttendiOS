import Foundation
import Security

final class KeychainHelper {
    
    // MARK: - Constants
    private static let service = "com.smartattend.studentapp"
    private static let rollNumberKey = "student_roll_number"
    
    // MARK: - Save Methods
    
    /// Save roll number securely to keychain
    static func saveRollNumber(_ rollNumber: String) -> Bool {
        let data = rollNumber.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: rollNumberKey,
            kSecValueData as String: data,
            kSecAttrAccessible as String: kSecAttrAccessibleWhenUnlockedThisDeviceOnly
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        let status = SecItemAdd(query as CFDictionary, nil)
        return status == errSecSuccess
    }
    
    // MARK: - Retrieve Methods
    
    /// Retrieve roll number from keychain
    static func getRollNumber() -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: rollNumberKey,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var dataTypeRef: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &dataTypeRef)
        
        guard status == errSecSuccess,
              let data = dataTypeRef as? Data,
              let rollNumber = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return rollNumber
    }
    
    // MARK: - Delete Methods
    
    /// Delete roll number from keychain
    static func deleteRollNumber() -> Bool {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: rollNumberKey
        ]
        
        let status = SecItemDelete(query as CFDictionary)
        return status == errSecSuccess || status == errSecItemNotFound
    }
    
    /// Clear all keychain data for this app
    static func clearAllKeychainData() -> Bool {
        return deleteRollNumber()
    }
}
