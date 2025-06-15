import SwiftUI

struct StudentHomeView: View {
    let student: Student
    let onLogout: () -> Void
    
    @StateObject private var firebaseManager = FirebaseManager()
    @StateObject private var bleManager = StudentBLEManager()
    @StateObject private var attendanceManager = AttendanceManager()
    
    @State private var showingClassroomDetected = false
    @State private var currentStatus = "Checking for active sessions..."
    @State private var showingLogoutAlert = false
    @State private var showingRoomDetectionStart = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background
                Color(.systemGroupedBackground)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header Section
                        headerSection
                        
                        // Session Status Card
                        sessionStatusCard
                        
                        // Action Buttons
                        actionButtonsSection
                        
                        // Current Activity Section
                        if firebaseManager.isSessionActive {
                            currentActivitySection
                        }
                        
                        // Recent Attendance
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
                    Menu {
                        Button("Logout", role: .destructive) {
                            showingLogoutAlert = true
                        }
                    } label: {
                        Image(systemName: "person.circle")
                            .font(.title2)
                    }
                }
            }
        }
        .onAppear {
            setupBLECallbacks()
            checkForActiveSession()
        }
        .alert("Logout", isPresented: $showingLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout", role: .destructive) {
                onLogout()
            }
        } message: {
            Text("Are you sure you want to logout?")
        }
        .overlay(
            Group {
                if showingRoomDetectionStart {
                    roomDetectionStartOverlay
                } else if showingClassroomDetected {
                    classroomDetectedOverlay
                }
            }
        )
        // Face Authentication Sheet
        .fullScreenCover(isPresented: $attendanceManager.showingFaceAuthentication) {
            NavigationView {
                FaceIOWebView(
                    onAuthenticated: { rollNumber in
                        handleFaceAuthenticationSuccess(rollNumber: rollNumber)
                    },
                    onError: { error in
                        attendanceManager.handleFaceAuthenticationError(error)
                        resetToHomeState()
                    },
                    onClose: {
                        attendanceManager.handleFaceAuthenticationError("User cancelled")
                        resetToHomeState()
                    }
                )
                .navigationTitle("Face Authentication")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            attendanceManager.handleFaceAuthenticationError("User cancelled")
                            resetToHomeState()
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
                        resetToHomeState()
                        checkForActiveSession() // Refresh session status
                    }
                )
            }
        }
    }
    
    // MARK: - Header Section
    var headerSection: some View {
        VStack(spacing: 12) {
            // Welcome message
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Welcome back,")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                    
                    Text(student.name)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.primary)
                }
                
                Spacer()
                
                // Student avatar
                Image(systemName: "person.crop.circle.fill")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
            }
            
            // Student details
            HStack(spacing: 20) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Roll Number")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(student.rollNumber)
                        .font(.system(size: 16, weight: .semibold, design: .monospaced))
                        .foregroundColor(.blue)
                }
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Class")
                        .font(.system(size: 12, weight: .medium))
                        .foregroundColor(.secondary)
                    Text(student.className)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.orange)
                }
                
                Spacer()
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Session Status Card
    var sessionStatusCard: some View {
        VStack(spacing: 16) {
            HStack {
                Image(systemName: sessionStatusIcon)
                    .font(.system(size: 24))
                    .foregroundColor(sessionStatusColor)
                
                VStack(alignment: .leading, spacing: 4) {
                    Text("Session Status")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text(currentStatus)
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                if firebaseManager.isLoading {
                    ProgressView()
                        .scaleEffect(0.8)
                }
            }
            
            // Active session details
            if let session = firebaseManager.activeSession, session.isActive {
                Divider()
                
                VStack(spacing: 12) {
                    SessionDetailRow(title: "Subject", value: session.subject, icon: "book.fill")
                    SessionDetailRow(title: "Room", value: session.room, icon: "building.fill")
                    SessionDetailRow(title: "Type", value: session.type.capitalized, icon: "doc.fill")
                }
            }
        }
        .padding(20)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.05), radius: 8, x: 0, y: 4)
        )
    }
    
    // MARK: - Action Buttons Section
    var actionButtonsSection: some View {
        HStack(spacing: 12) {
            // Refresh Button
            Button(action: checkForActiveSession) {
                HStack {
                    Image(systemName: "arrow.clockwise")
                    Text("Refresh")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .padding(.horizontal, 20)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            .disabled(firebaseManager.isLoading)
            
            // Manual Start Detection Button (only show when scanning hasn't started)
            if firebaseManager.isSessionActive && !bleManager.isScanning && !showingRoomDetectionStart {
                Button(action: startBLEDetection) {
                    HStack {
                        Image(systemName: "wifi.circle")
                        Text("Manual Detection")
                    }
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.orange)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 10)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.orange, lineWidth: 1)
                    )
                }
            }
            
            Spacer()
        }
    }
    
    // MARK: - Current Activity Section
    var currentActivitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text("Current Activity")
                .font(.system(size: 20, weight: .bold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                // BLE Status
                HStack {
                    Image(systemName: bleStatusIcon)
                        .font(.system(size: 20))
                        .foregroundColor(bleStatusColor)
                        .frame(width: 24)
                    
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Bluetooth Detection")
                            .font(.system(size: 14, weight: .medium))
                            .foregroundColor(.primary)
                        
                        Text(bleStatusText)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                    }
                    
                    Spacer()
                    
                    if bleManager.isScanning {
                        ProgressView()
                            .scaleEffect(0.8)
                    }
                }
                
                // Room Detection Status
                if bleManager.isScanning || bleManager.targetRoomDetected {
                    HStack {
                        Image(systemName: bleManager.targetRoomDetected ? "checkmark.circle.fill" : "magnifyingglass.circle")
                            .font(.system(size: 20))
                            .foregroundColor(bleManager.targetRoomDetected ? .green : .orange)
                            .frame(width: 24)
                        
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Room Detection")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.primary)
                            
                            Text(roomDetectionText)
                                .font(.system(size: 12))
                                .foregroundColor(.secondary)
                        }
                        
                        Spacer()
                    }
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
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
                .fill(Color(.systemBackground))
        )
    }
    
    // MARK: - Room Detection Start Overlay
    var roomDetectionStartOverlay: some View {
        ZStack {
            Color.black.opacity(0.3)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                Image(systemName: "wifi.circle")
                    .font(.system(size: 48))
                    .foregroundColor(.blue)
                    .scaleEffect(showingRoomDetectionStart ? 1.0 : 0.1)
                
                VStack(spacing: 8) {
                    Text("Room Presence Detection Starting")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let room = firebaseManager.activeSession?.room {
                        Text("Looking for room: \(room)")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                }
                .opacity(showingRoomDetectionStart ? 1.0 : 0.0)
            }
            .scaleEffect(showingRoomDetectionStart ? 1.0 : 0.5)
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.8), value: showingRoomDetectionStart)
        .onAppear {
            // Auto-start BLE detection after 1.5 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                actuallyStartBLEDetection()
                showingRoomDetectionStart = false
            }
        }
    }
    
    // MARK: - Classroom Detected Overlay
    var classroomDetectedOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 24) {
                Image(systemName: "location.circle.fill")
                    .font(.system(size: 64))
                    .foregroundColor(.green)
                    .scaleEffect(showingClassroomDetected ? 1.0 : 0.1)
                
                VStack(spacing: 12) {
                    Text("Classroom Presence Detected!")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.white)
                        .multilineTextAlignment(.center)
                    
                    if let room = firebaseManager.activeSession?.room {
                        Text("Room: \(room)")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    Text("Starting face authentication...")
                        .font(.system(size: 16))
                        .foregroundColor(.white.opacity(0.8))
                }
                .opacity(showingClassroomDetected ? 1.0 : 0.0)
            }
            .scaleEffect(showingClassroomDetected ? 1.0 : 0.5)
        }
        .animation(.spring(response: 0.6, dampingFraction: 0.8), value: showingClassroomDetected)
        .onAppear {
            // Auto-start face authentication after 2 seconds
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                startFaceAuthentication()
            }
        }
    }
    
    // MARK: - Computed Properties
    
    var sessionStatusIcon: String {
        if firebaseManager.isLoading {
            return "clock.fill"
        } else if firebaseManager.isSessionActive {
            return "checkmark.circle.fill"
        } else {
            return "xmark.circle.fill"
        }
    }
    
    var sessionStatusColor: Color {
        if firebaseManager.isLoading {
            return .orange
        } else if firebaseManager.isSessionActive {
            return .green
        } else {
            return .red
        }
    }
    
    var bleStatusIcon: String {
        switch bleManager.status {
        case .poweredOn:
            return bleManager.isScanning ? "wifi.circle" : "wifi"
        case .scanning:
            return "wifi.circle"
        case .deviceFound:
            return "checkmark.circle.fill"
        default:
            return "wifi.slash"
        }
    }
    
    var bleStatusColor: Color {
        switch bleManager.status {
        case .poweredOn:
            return bleManager.isScanning ? .blue : .green
        case .scanning:
            return .blue
        case .deviceFound:
            return .green
        default:
            return .red
        }
    }
    
    var bleStatusText: String {
        if bleManager.isScanning {
            return "Scanning for room signal..."
        } else if bleManager.targetRoomDetected {
            return "Room detected successfully"
        } else if bleManager.status == .poweredOn {
            return "Ready to scan"
        } else {
            return "Bluetooth issue"
        }
    }
    
    var roomDetectionText: String {
        if let session = firebaseManager.activeSession {
            return bleManager.targetRoomDetected ?
                "Found room \(session.room)" :
                "Looking for room \(session.room)..."
        }
        return "No target room"
    }
    
    // MARK: - Methods
    
    private func setupBLECallbacks() {
        bleManager.onRoomDetected = { device in
            DispatchQueue.main.async {
                self.handleRoomDetected(device: device)
            }
        }
    }
    
    private func checkForActiveSession() {
        currentStatus = "Checking for active sessions..."
        
        Task {
            await firebaseManager.checkActiveSession(for: student.className)
            
            await MainActor.run {
                if firebaseManager.isSessionActive {
                    currentStatus = "Active session found! Starting room detection..."
                    
                    // Automatically start BLE detection with overlay
                    DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                        self.startBLEDetectionWithOverlay()
                    }
                } else {
                    currentStatus = "No active session for your class."
                    // Stop any ongoing BLE scanning
                    bleManager.stopScanning()
                    bleManager.resetDetection()
                }
            }
        }
    }
    
    private func startBLEDetectionWithOverlay() {
        guard let session = firebaseManager.activeSession, session.isActive else {
            print("❌ No active session to start BLE detection")
            return
        }
        
        print("🚀 Showing room detection start overlay...")
        showingRoomDetectionStart = true
    }
    
    private func actuallyStartBLEDetection() {
        guard let session = firebaseManager.activeSession, session.isActive else {
            print("❌ No active session to start BLE detection")
            return
        }
        
        print("🚀 Actually starting BLE detection for room: \(session.room)")
        bleManager.startScanningForRoom(session.room)
    }
    
    private func startBLEDetection() {
        // This is now for manual override only
        actuallyStartBLEDetection()
    }
    
    private func handleRoomDetected(device: BLEDevice) {
        print("🎯 Room detected! Starting attendance process...")
        
        // Show classroom detected overlay
        showingClassroomDetected = true
    }
    
    private func startFaceAuthentication() {
        showingClassroomDetected = false
        
        // Create attendance session
        if let device = bleManager.detectedDevice,
           let session = firebaseManager.activeSession {
            attendanceManager.currentSession = AttendanceSession(
                device: device,
                subjectCode: session.subject
            )
            
            // Start face authentication
            attendanceManager.showingFaceAuthentication = true
        }
    }
    
    private func handleFaceAuthenticationSuccess(rollNumber: String) {
        guard var currentSession = attendanceManager.currentSession,
              let activeSession = firebaseManager.activeSession else {
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
        
        currentSession.complete(with: result)
        attendanceManager.currentSession = currentSession
        
        // Mark attendance in Firebase
        firebaseManager.markAttendance(
            student: student,
            session: activeSession,
            detectedDevice: self.bleManager.detectedDevice ?? currentSession.device
        ) { result in
            DispatchQueue.main.async {
                switch result {
                case .success:
                    print("✅ Attendance marked in Firebase successfully")
                    // Add to completed sessions
                    self.attendanceManager.completedSessions.insert(currentSession, at: 0)
                    
                    // Hide face authentication and show success
                    self.attendanceManager.showingFaceAuthentication = false
                    self.attendanceManager.showingSuccess = true
                    
                case .failure(let error):
                    print("❌ Failed to mark attendance in Firebase: \(error)")
                    // Show error and reset
                    self.attendanceManager.handleFaceAuthenticationError("Failed to mark attendance: \(error.localizedDescription)")
                    self.resetToHomeState()
                }
            }
        }
    }
    
    private func resetToHomeState() {
        showingClassroomDetected = false
        showingRoomDetectionStart = false
        bleManager.stopScanning()
        bleManager.resetDetection()
        attendanceManager.currentSession = nil
    }
    
    private func formatRelativeTime(_ date: Date) -> String {
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
}

// MARK: - Supporting Views
struct SessionDetailRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 14))
                .foregroundColor(.blue)
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

#Preview {
    StudentHomeView(
        student: Student(
            name: "John Doe",
            rollNumber: "2021001",
            className: "2S12"
        ),
        onLogout: {
            print("Logout tapped")
        }
    )
}
