import SwiftUI

struct AttendanceConfirmationView: View {
    let device: BLEDevice
    let onConfirm: () -> Void
    let onCancel: () -> Void
    
    var body: some View {
        VStack(spacing: 24) {
            // Header Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.blue.opacity(0.2), Color.purple.opacity(0.2)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                Image(systemName: "person.badge.clock.fill")
                    .font(.system(size: 36))
                    .foregroundColor(.blue)
            }
            
            VStack(spacing: 8) {
                Text("Attendance Device Detected")
                    .font(.system(size: 22, weight: .bold))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text("Would you like to mark your attendance?")
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
            }
            
            // Device Information Card
            VStack(spacing: 12) {
                HStack {
                    Image(systemName: "wifi")
                        .foregroundColor(.blue)
                        .frame(width: 20)
                    Text("Device Name")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    Text(device.name)
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                }
                
                if let subjectCode = device.subjectCode, subjectCode != "No Data" {
                    HStack {
                        Image(systemName: "book.closed")
                            .foregroundColor(.orange)
                            .frame(width: 20)
                        Text("Subject Code")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.secondary)
                        Spacer()
                        Text(subjectCode)
                            .font(.system(size: 14, weight: .bold, design: .monospaced))
                            .foregroundColor(.orange)
                    }
                }
                
                HStack {
                    Image(systemName: "antenna.radiowaves.left.and.right")
                        .foregroundColor(.green)
                        .frame(width: 20)
                    Text("Signal Strength")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                    Spacer()
                    HStack(spacing: 4) {
                        SignalStrengthMini(rssi: device.rssi)
                        Text("\(device.rssi) dBm")
                            .font(.system(size: 12))
                            .foregroundColor(.green)
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Action Buttons
            VStack(spacing: 12) {
                Button(action: onConfirm) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Mark Attendance")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.blue, Color.purple]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                
                Button(action: onCancel) {
                    HStack {
                        Image(systemName: "xmark.circle")
                        Text("Cancel")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.secondary)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(Color(.systemGray4), lineWidth: 1)
                    )
                }
            }
            
            // Security Note
            HStack(spacing: 8) {
                Image(systemName: "lock.shield")
                    .font(.system(size: 12))
                    .foregroundColor(.blue)
                Text("Secure face authentication will be required")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            .padding(.top, 8)
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
}

struct SignalStrengthMini: View {
    let rssi: NSNumber
    
    var body: some View {
        HStack(spacing: 2) {
            ForEach(0..<3) { index in
                Rectangle()
                    .fill(barColor(for: index))
                    .frame(width: 2, height: CGFloat(4 + index * 2))
            }
        }
    }
    
    private func barColor(for index: Int) -> Color {
        let rssiValue = rssi.intValue
        let strength = signalStrength(rssi: rssiValue)
        
        if index < strength {
            return .green
        } else {
            return Color(.systemGray4)
        }
    }
    
    private func signalStrength(rssi: Int) -> Int {
        if rssi >= -50 {
            return 3 // Excellent
        } else if rssi >= -65 {
            return 2 // Good
        } else {
            return 1 // Fair
        }
    }
}

//#Preview {
//    ZStack {
//        Color(.systemGroupedBackground)
//            .ignoresSafeArea()
//        
//        AttendanceConfirmationView(
//            device: BLEDevice(
//                peripheral: CBPeripheral(),
//                name: "Humble Coders",
//                rssi: NSNumber(value: -45),
//                advertisementData: [:],
//                subjectCode: "UCS301",
//                rawSubjectData: nil,
//                discoveredAt: Date()
//            ),
//            onConfirm: {
//                print("Confirmed")
//            },
//            onCancel: {
//                print("Cancelled")
//            }
//        )
//    }
//}
