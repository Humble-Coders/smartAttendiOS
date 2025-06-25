import SwiftUI
import CoreBluetooth

struct AttendanceSuccessView: View {
    let session: AttendanceSession
    let onDismiss: () -> Void
    
    @State private var showingCheckmark = false
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Success Animation
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.1), Color.blue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showingCheckmark ? 1.0 : 0.5)
                    .opacity(showingCheckmark ? 1.0 : 0.0)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .scaleEffect(showingCheckmark ? 1.0 : 0.1)
                    .opacity(showingCheckmark ? 1.0 : 0.0)
            }
            
            if showingContent {
                VStack(spacing: 24) {
                    // Success Message
                    VStack(spacing: 8) {
                        Text("Attendance Marked!")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text("Your attendance has been successfully recorded")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .opacity(showingContent ? 1.0 : 0.0)
                    .offset(y: showingContent ? 0 : 20)
                    
                    // Session Details Card
                    VStack(spacing: 16) {
                        // Roll Number - Most Important
                        if let result = session.faceIOResult {
                            VStack(spacing: 8) {
                                Text("Student Roll Number")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(result.rollNumber)
                                    .font(.system(size: 24, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 12)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                        }
                        
                        Divider()
                            .padding(.horizontal, 20)
                        
                        // Session Information
                        VStack(spacing: 12) {
                            DetailRow(
                                icon: "book.closed.fill",
                                title: "Subject Code",
                                value: session.subjectCode,
                                color: .orange
                            )
                            
                            DetailRow(
                                icon: "building.fill",
                                title: "Room",
                                value: extractRoomNumber(from: session.device.name),
                                color: .purple
                            )
                            
                            DetailRow(
                                icon: "wifi",
                                title: "Device",
                                value: session.device.name,
                                color: .blue
                            )
                            
                            DetailRow(
                                icon: "clock.fill",
                                title: "Time",
                                value: formatTime(session.startTime),
                                color: .green
                            )
                            
                            DetailRow(
                                icon: "calendar",
                                title: "Date",
                                value: formatDate(session.startTime),
                                color: .indigo
                            )
                        }
                    }
                    .padding(20)
                    .background(
                        RoundedRectangle(cornerRadius: 16)
                            .fill(Color(.systemBackground))
                            .shadow(color: Color.black.opacity(0.05), radius: 10, x: 0, y: 5)
                    )
                    .opacity(showingContent ? 1.0 : 0.0)
                    .offset(y: showingContent ? 0 : 30)
                }
            }
            
            Spacer()
            
            // Done Button
            if showingContent {
                Button(action: onDismiss) {
                    HStack {
                        Image(systemName: "house.fill")
                        Text("Back to Home")
                    }
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 16)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color.green, Color.blue]),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(12)
                }
                .padding(.horizontal, 20)
                .opacity(showingContent ? 1.0 : 0.0)
                .offset(y: showingContent ? 0 : 20)
            }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(
            LinearGradient(
                gradient: Gradient(colors: [
                    Color(.systemBackground),
                    Color(.systemGray6).opacity(0.3)
                ]),
                startPoint: .top,
                endPoint: .bottom
            )
        )
        .onAppear {
            startAnimation()
        }
    }
    
    private func startAnimation() {
        // First show checkmark
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingCheckmark = true
        }
        
        // Then show content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showingContent = true
            }
        }
    }
    
    // Extract room number by removing last 3 digits from device name
    private func extractRoomNumber(from deviceName: String) -> String {
        let cleanName = deviceName.trimmingCharacters(in: .whitespacesAndNewlines)
        
        // Check if the device name has at least 3 characters and the last 3 are digits
        if cleanName.count >= 3 {
            let lastThreeIndex = cleanName.index(cleanName.endIndex, offsetBy: -3)
            let lastThree = String(cleanName[lastThreeIndex...])
            
            // If last 3 characters are digits, remove them
            if lastThree.allSatisfy({ $0.isNumber }) {
                let roomNumber = String(cleanName[..<lastThreeIndex])
                return roomNumber.isEmpty ? cleanName : roomNumber
            }
        }
        
        // If pattern doesn't match, return original name
        return cleanName
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
    
    private func formatDate(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }
}

struct DetailRow: View {
    let icon: String
    let title: String
    let value: String
    let color: Color
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
                .foregroundColor(color)
                .frame(width: 20)
            
            Text(title)
                .font(.system(size: 14, weight: .medium))
                .foregroundColor(.secondary)
            
            Spacer()
            
            Text(value)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(.primary)
        }
    }
}
