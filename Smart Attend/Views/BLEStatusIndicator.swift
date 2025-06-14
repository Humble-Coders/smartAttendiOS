import SwiftUI

struct BLEStatusIndicator: View {
    let status: BLEStatus
    let isScanning: Bool
    let deviceCount: Int
    
    var body: some View {
        HStack(spacing: 12) {
            // Status indicator circle
            Circle()
                .fill(statusColor)
                .frame(width: 12, height: 12)
                .overlay(
                    Circle()
                        .stroke(statusColor.opacity(0.3), lineWidth: 4)
                        .scaleEffect(isScanning ? 1.5 : 1.0)
                        .opacity(isScanning ? 0 : 1)
                        .animation(
                            isScanning ?
                            Animation.easeInOut(duration: 1.0).repeatForever(autoreverses: false) :
                            .default,
                            value: isScanning
                        )
                )
            
            VStack(alignment: .leading, spacing: 2) {
                Text(status.rawValue)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.primary)
                
                if deviceCount > 0 {
                    Text("\(deviceCount) Humble Coders device\(deviceCount == 1 ? "" : "s") found")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                }
            }
            
            Spacer()
            
            // Bluetooth icon
            Image(systemName: bluetoothIcon)
                .font(.system(size: 20))
                .foregroundColor(statusColor)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(
            RoundedRectangle(cornerRadius: 12)
                .fill(Color(.systemGray6))
        )
    }
    
    private var statusColor: Color {
        switch status {
        case .poweredOn:
            return .green
        case .scanning:
            return .blue
        case .deviceFound:
            return .orange
        case .poweredOff, .unauthorized, .unsupported:
            return .red
        default:
            return .gray
        }
    }
    
    private var bluetoothIcon: String {
        switch status {
        case .poweredOn, .scanning, .deviceFound:
            return "bluetooth"
        case .poweredOff:
            return "bluetooth.slash"
        case .unauthorized:
            return "bluetooth.trianglebadge.exclamationmark"
        default:
            return "bluetooth"
        }
    }
}

#Preview {
    VStack(spacing: 16) {
        BLEStatusIndicator(status: .scanning, isScanning: true, deviceCount: 0)
        BLEStatusIndicator(status: .deviceFound, isScanning: false, deviceCount: 2)
        BLEStatusIndicator(status: .poweredOff, isScanning: false, deviceCount: 0)
    }
    .padding()
}
