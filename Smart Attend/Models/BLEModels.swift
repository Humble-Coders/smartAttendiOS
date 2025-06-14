import Foundation
import CoreBluetooth

// MARK: - BLE Device Model
struct BLEDevice: Identifiable, Equatable {
    let id = UUID()
    let peripheral: CBPeripheral
    let name: String
    let rssi: NSNumber
    let advertisementData: [String: Any]
    let subjectCode: String?
    let rawSubjectData: String?
    let discoveredAt: Date
    
    static func == (lhs: BLEDevice, rhs: BLEDevice) -> Bool {
        return lhs.peripheral.identifier == rhs.peripheral.identifier
    }
}

// MARK: - BLE Status Enum
enum BLEStatus: String, CaseIterable {
    case poweredOff = "Bluetooth Off"
    case poweredOn = "Ready"
    case scanning = "Scanning..."
    case unauthorized = "Permission Denied"
    case unsupported = "Not Supported"
    case unknown = "Unknown"
    case deviceFound = "Device Found"
    
    var color: String {
        switch self {
        case .poweredOn:
            return "green"
        case .scanning:
            return "blue"
        case .deviceFound:
            return "orange"
        default:
            return "red"
        }
    }
}

// MARK: - Subject Data Model
struct SubjectData {
    let code: String
    let timestamp: Date
    let rawData: String?
    
    init(from advertisementData: [String: Any]) {
        self.timestamp = Date()
        
        // Priority order for extracting subject code:
        // 1. Manufacturer Data (where ESP32 puts the message)
        // 2. Local Name
        // 3. Service Data
        
        if let manufacturerData = advertisementData[CBAdvertisementDataManufacturerDataKey] as? Data {
            let extracted = SubjectData.extractSubjectCodeFromManufacturerData(manufacturerData)
            self.code = extracted.code
            self.rawData = extracted.rawData
        } else if let localName = advertisementData[CBAdvertisementDataLocalNameKey] as? String {
            self.code = SubjectData.extractSubjectCode(from: localName)
            self.rawData = localName
        } else if let serviceData = advertisementData[CBAdvertisementDataServiceDataKey] as? [CBUUID: Data],
                  let firstServiceData = serviceData.values.first {
            self.code = SubjectData.extractSubjectCode(from: firstServiceData)
            self.rawData = String(data: firstServiceData, encoding: .utf8)
        } else {
            self.code = "No Data"
            self.rawData = nil
        }
    }
    
    private static func extractSubjectCodeFromManufacturerData(_ data: Data) -> (code: String, rawData: String) {
        // ESP32 manufacturer data format:
        // Bytes 0-1: Manufacturer ID (0xFFFF)
        // Bytes 2+: Message content (UCS301)
        
        let rawHex = data.map { String(format: "%02X", $0) }.joined(separator: " ")
        
        if data.count >= 3 {
            // Skip first 2 bytes (manufacturer ID) and extract the message
            let messageData = data.subdata(in: 2..<data.count)
            
            if let messageString = String(data: messageData, encoding: .utf8) {
                return (code: messageString, rawData: "Hex: \(rawHex) | Text: \(messageString)")
            }
        }
        
        // Fallback: if we can't parse as UTF-8, return hex representation
        return (code: rawHex, rawData: "Raw Hex: \(rawHex)")
    }
    
    private static func extractSubjectCode(from string: String) -> String {
        // Extract subject code from string (assuming format like "SubjectCode:CS101")
        let components = string.components(separatedBy: ":")
        return components.count > 1 ? components[1] : string
    }
    
    private static func extractSubjectCode(from data: Data) -> String {
        // Convert data to string and extract subject code
        if let string = String(data: data, encoding: .utf8) {
            return extractSubjectCode(from: string)
        }
        // If not UTF-8, try to extract as hex
        return data.map { String(format: "%02X", $0) }.joined()
    }
}
