import SwiftUI
import CoreBluetooth

struct DeviceCardView: View {
    let device: BLEDevice
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header with device name and signal strength
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(device.name)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Device ID: \(device.peripheral.identifier.uuidString.prefix(8))...")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                // Signal strength indicator
                SignalStrengthView(rssi: device.rssi)
            }
            
            // Subject code section
            if let subjectCode = device.subjectCode, subjectCode != "No Data" {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Subject Code")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    
                    Text(subjectCode)
                        .font(.system(size: 20, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                    
                    // Show raw data for debugging
                    if let rawData = device.rawSubjectData {
                        Text("Raw Data: \(rawData)")
                            .font(.system(size: 10, design: .monospaced))
                            .foregroundColor(.secondary)
                            .padding(.top, 4)
                    }
                }
            }
            
            // Additional information
            VStack(alignment: .leading, spacing: 6) {
                InfoRow(title: "Signal Strength", value: "\(device.rssi) dBm")
                InfoRow(title: "Discovered", value: timeAgoString(from: device.discoveredAt))
                
                if device.peripheral.state != .disconnected {
                    InfoRow(title: "Connection", value: connectionStateString(device.peripheral.state))
                }
            }
            
            // Advertisement data preview (if available)
            if !device.advertisementData.isEmpty {
                DisclosureGroup("Advertisement Data") {
                    VStack(alignment: .leading, spacing: 4) {
                        ForEach(Array(device.advertisementData.keys.sorted()), id: \.self) { key in
                            if let value = device.advertisementData[key] {
                                HStack {
                                    Text(key)
                                        .font(.system(size: 12, weight: .medium))
                                        .foregroundColor(.secondary)
                                    Spacer()
                                    Text(String(describing: value))
                                        .font(.system(size: 12, design: .monospaced))
                                        .foregroundColor(.primary)
                                        .lineLimit(1)
                                        .truncationMode(.tail)
                                }
                            }
                        }
                    }
                    .padding(.top, 8)
                }
                .font(.system(size: 14))
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 8, x: 0, y: 4)
        )
    }
    
    private func timeAgoString(from date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes) minute\(minutes == 1 ? "" : "s") ago"
        } else {
            let hours = Int(interval / 3600)
            return "\(hours) hour\(hours == 1 ? "" : "s") ago"
        }
    }
    
    private func connectionStateString(_ state: CBPeripheralState) -> String {
        switch state {
        case .connected:
            return "Connected"
        case .connecting:
            return "Connecting..."
        case .disconnecting:
            return "Disconnecting..."
        case .disconnected:
            return "Disconnected"
        @unknown default:
            return "Unknown"
        }
    }
}

struct InfoRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .font(.system(size: 12))
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(size: 12, weight: .medium))
                .foregroundColor(.primary)
        }
    }
}

struct SignalStrengthView: View {
    let rssi: NSNumber
    
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<4) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 3, height: CGFloat(6 + index * 3))
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(
            RoundedRectangle(cornerRadius: 6)
                .fill(Color(.systemGray5))
        )
    }
    
    private func barColor(for index: Int) -> Color {
        let rssiValue = rssi.intValue
        let strength = signalStrength(rssi: rssiValue)
        
        if index < strength {
            switch strength {
            case 4:
                return .green
            case 3:
                return .yellow
            case 2:
                return .orange
            default:
                return .red
            }
        } else {
            return Color(.systemGray4)
        }
    }
    
    private func signalStrength(rssi: Int) -> Int {
        if rssi >= -50 {
            return 4 // Excellent
        } else if rssi >= -60 {
            return 3 // Good
        } else if rssi >= -70 {
            return 2 // Fair
        } else {
            return 1 // Poor
        }
    }
}
//
//#Preview {
//    DeviceCardView(device: BLEDevice(
//        peripheral: CBPeripheral(),
//        name: "Humble Coders",
//        rssi: NSNumber(value: -45),
//        advertisementData: [
//            "kCBAdvDataLocalName": "Humble Coders",
//            "kCBAdvDataManufacturerData": "CS101"
//        ],
//        subjectCode: "UCS301",
//        rawSubjectData: "Hex: FF FF 55 43 53 33 30 31 | Text: UCS301",
//        discoveredAt: Date()
//    ))
//    .padding()
//}
