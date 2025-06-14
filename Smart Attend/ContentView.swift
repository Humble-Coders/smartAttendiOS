import SwiftUI

struct ContentView: View {
    @StateObject private var bleManager = BLEManager()
    @StateObject private var attendanceManager = AttendanceManager()
    @State private var showingProfile = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Header Section
                        headerSection
                        
                        // BLE Status Section
                        bleStatusSection
                        
                        // Devices Section
                        devicesSection
                        
                        // Recent Attendance Section
                        if !attendanceManager.completedSessions.isEmpty {
                            recentAttendanceSection
                        }
                        
                        Spacer(minLength: 100)
                    }
                    .padding(.horizontal, 16)
                    .padding(.top, 20)
                }
            }
            .navigationTitle("Attendance")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Profile") {
                        showingProfile = true
                    }
                    .font(.system(size: 16, weight: .medium))
                }
            }
        }
        .sheet(isPresented: $showingProfile) {
            ProfileView()
        }
        // Attendance Confirmation Dialog
        .overlay(
            Group {
                if attendanceManager.showingConfirmation, let session = attendanceManager.currentSession {
                    Color.black.opacity(0.4)
                        .ignoresSafeArea()
                        .onTapGesture {
                            attendanceManager.cancelAttendance()
                        }
                    
                    AttendanceConfirmationView(
                        device: session.device,
                        onConfirm: {
                            attendanceManager.confirmAttendance()
                        },
                        onCancel: {
                            attendanceManager.cancelAttendance()
                        }
                    )
                    .transition(.scale.combined(with: .opacity))
                }
            }
            .animation(.spring(response: 0.6, dampingFraction: 0.8), value: attendanceManager.showingConfirmation)
        )
        // Face Authentication Sheet
        .fullScreenCover(isPresented: $attendanceManager.showingFaceAuthentication) {
            NavigationView {
                FaceIOWebView(
                    onAuthenticated: { rollNumber in
                        attendanceManager.handleFaceAuthenticationSuccess(rollNumber: rollNumber)
                    },
                    onError: { error in
                        attendanceManager.handleFaceAuthenticationError(error)
                    },
                    onClose: {
                        attendanceManager.handleFaceAuthenticationError("User cancelled")
                    }
                )
                .navigationTitle("Face Authentication")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            attendanceManager.handleFaceAuthenticationError("User cancelled")
                        }
                    }
                }
            }
        }
        // Success Screen
        .fullScreenCover(isPresented: $attendanceManager.showingSuccess) {
            if let session = attendanceManager.currentSession {
                AttendanceSuccessView(
                    session: session,
                    onDismiss: {
                        attendanceManager.dismissSuccess()
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(spacing: 12) {
            Image(systemName: "person.badge.clock")
                .font(.system(size: 48))
                .foregroundColor(.blue)
            
            Text("Student Attendance")
                .font(.system(size: 24, weight: .bold))
                .foregroundColor(.primary)
            
            Text("Scanning for attendance devices...")
                .font(.system(size: 16))
                .foregroundColor(.secondary)
        }
        .padding(.vertical, 20)
    }
    
    // MARK: - BLE Status Section
    var bleStatusSection: some View {
        VStack(spacing: 16) {
            BLEStatusIndicator(
                status: bleManager.status,
                isScanning: bleManager.isScanning,
                deviceCount: bleManager.humbleCodersDevices.count
            )
            
            // Control buttons
            HStack(spacing: 12) {
                Button(action: {
                    if bleManager.isScanning {
                        bleManager.stopScanning()
                    } else {
                        bleManager.startScanning()
                    }
                }) {
                    HStack {
                        Image(systemName: bleManager.isScanning ? "stop.fill" : "play.fill")
                        Text(bleManager.isScanning ? "Stop Scan" : "Start Scan")
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 10)
                            .fill(bleManager.isScanning ? Color.red : Color.blue)
                    )
                }
                .disabled(bleManager.status == .poweredOff || bleManager.status == .unauthorized)
                
                Button("Refresh") {
                    bleManager.restartScanning()
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
                .disabled(bleManager.status == .poweredOff || bleManager.status == .unauthorized)
            }
        }
    }
    
    // MARK: - Devices Section
    var devicesSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            if !bleManager.humbleCodersDevices.isEmpty {
                Text("Humble Coders Devices")
                    .font(.system(size: 20, weight: .bold))
                    .foregroundColor(.primary)
                
                LazyVStack(spacing: 16) {
                    ForEach(bleManager.humbleCodersDevices) { device in
                        DeviceCardView(device: device)
                            .onTapGesture {
                                // Start attendance process when device is tapped
                                attendanceManager.startAttendanceProcess(for: device)
                            }
                    }
                }
            } else if bleManager.status == .scanning {
                scanningEmptyState
            } else if bleManager.status == .poweredOn {
                noDevicesEmptyState
            } else {
                bluetoothIssueEmptyState
            }
        }
    }
    
    // MARK: - Recent Attendance Section
    var recentAttendanceSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Recent Attendance")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 12) {
                ForEach(Array(attendanceManager.completedSessions.prefix(3)), id: \.id) { session in
                    recentAttendanceRow(session: session)
                }
            }
        }
    }
    
    func recentAttendanceRow(session: AttendanceSession) -> some View {
        HStack(spacing: 12) {
            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 20))
                .foregroundColor(.green)
            
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(session.subjectCode)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    if let rollNumber = session.faceIOResult?.rollNumber {
                        Text("• \(rollNumber)")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.blue)
                    }
                }
                
                Text(formatRelativeTime(session.startTime))
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
            }
            
            Spacer()
            
            Image(systemName: "chevron.right")
                .font(.system(size: 12))
                .foregroundColor(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
        )
    }
    
    func formatRelativeTime(_ date: Date) -> String {
        let interval = Date().timeIntervalSince(date)
        
        if interval < 60 {
            return "Just now"
        } else if interval < 3600 {
            let minutes = Int(interval / 60)
            return "\(minutes)m ago"
        } else if interval < 86400 {
            let hours = Int(interval / 3600)
            return "\(hours)h ago"
        } else {
            let days = Int(interval / 86400)
            return "\(days)d ago"
        }
    }
    
    // MARK: - Empty States
    var scanningEmptyState: some View {
        VStack(spacing: 16) {
            ProgressView()
                .scaleEffect(1.5)
                .padding(.bottom, 8)
            
            Text("Scanning for Devices...")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Looking for 'Humble Coders' devices nearby")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
        }
        .padding(.vertical, 40)
    }
    
    var noDevicesEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "wifi.slash")
                .font(.system(size: 48))
                .foregroundColor(.gray)
            
            Text("No Devices Found")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text("Make sure 'Humble Coders' devices are nearby and broadcasting")
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    
    var bluetoothIssueEmptyState: some View {
        VStack(spacing: 16) {
            Image(systemName: "bluetooth.slash")
                .font(.system(size: 48))
                .foregroundColor(.red)
            
            Text("Bluetooth Issue")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(.primary)
            
            Text(bluetoothIssueMessage)
                .font(.system(size: 14))
                .foregroundColor(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 20)
        }
        .padding(.vertical, 40)
    }
    
    var bluetoothIssueMessage: String {
        switch bleManager.status {
        case .poweredOff:
            return "Please turn on Bluetooth in Settings to scan for devices"
        case .unauthorized:
            return "Bluetooth permission is required. Please enable it in Settings > Privacy & Security > Bluetooth"
        case .unsupported:
            return "This device doesn't support Bluetooth Low Energy"
        default:
            return "Unknown Bluetooth issue. Please try restarting the app"
        }
    }
}

// MARK: - Profile View (Placeholder)
struct ProfileView: View {
    @Environment(\.dismiss) private var dismiss
    
    var body: some View {
        NavigationView {
            VStack(spacing: 20) {
                Text("Profile Setup")
                    .font(.largeTitle)
                    .fontWeight(.bold)
                
                Text("Profile functionality will be implemented later")
                    .foregroundColor(.secondary)
                
                Spacer()
            }
            .navigationTitle("Profile")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    ContentView()
}
