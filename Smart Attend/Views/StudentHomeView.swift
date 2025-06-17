import SwiftUI
import FirebaseFirestore

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
    @State private var showingAttendanceError = false
    @State private var attendanceErrorMessage = ""
    @State private var completedSessionId: String? // Track which session was completed
    
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
        .alert("Attendance Not Marked", isPresented: $showingAttendanceError) {
            Button("OK") {
                dismissAttendanceError()
            }
        } message: {
            Text(attendanceErrorMessage)
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
                } else if bleManager.showingBluetoothPrompt {
                    bluetoothPromptOverlay
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
        HStack {
            Spacer()
            
            // Single intelligent room detection button (centered)
            if !bleManager.isScanning && !showingRoomDetectionStart {
                Button(action: startIntelligentDetection) {
                    HStack {
                        Image(systemName: detectionButtonIcon)
                        Text(detectionButtonText)
                    }
                    .font(.system(size: 16, weight: .medium))
                    .foregroundColor(.white)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: detectionButtonColors),
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                    )
                    .cornerRadius(10)
                }
                .disabled(firebaseManager.isLoading)
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
            Color.black.opacity(0.8)
                .ignoresSafeArea()
                .opacity(showingRoomDetectionStart ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showingRoomDetectionStart)
            
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
            .opacity(showingRoomDetectionStart ? 1.0 : 0.0)
            .animation(.spring(response: 0.5, dampingFraction: 0.8).delay(0.1), value: showingRoomDetectionStart)
        }
        .onAppear {
            // Graceful entrance
            withAnimation(.easeInOut(duration: 0.4)) {
                showingRoomDetectionStart = true
            }
            
            // Auto-start BLE detection after 1.5 seconds with graceful exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
                actuallyStartBLEDetection()
                
                // Graceful exit animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingRoomDetectionStart = false
                }
            }
        }
    }
    
    // MARK: - Classroom Detected Overlay
    var classroomDetectedOverlay: some View {
        ZStack {
            Color.black.opacity(0.85)
                .ignoresSafeArea()
                .opacity(showingClassroomDetected ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.3), value: showingClassroomDetected)
            
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
            .opacity(showingClassroomDetected ? 1.0 : 0.0)
            .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: showingClassroomDetected)
        }
        .onAppear {
            // Graceful entrance
            withAnimation(.easeInOut(duration: 0.4)) {
                showingClassroomDetected = true
            }
            
            // Auto-start face authentication after 2 seconds with graceful exit
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                // Graceful exit animation
                withAnimation(.easeInOut(duration: 0.3)) {
                    showingClassroomDetected = false
                }
                
                // Start face authentication after exit completes
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    startFaceAuthentication()
                }
            }
        }
    }
    
    // MARK: - Attendance Error Overlay
    var attendanceErrorOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Error Icon
                ZStack {
                    Circle()
                        .fill(
                            LinearGradient(
                                gradient: Gradient(colors: [
                                    Color.orange.opacity(0.15),
                                    Color.red.opacity(0.1)
                                ]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .frame(width: 70, height: 70)
                    
                    Image(systemName: "exclamationmark.triangle.fill")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.red]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
                
                VStack(spacing: 12) {
                    Text("Attendance Not Marked")
                        .font(.system(size: 20, weight: .semibold, design: .rounded))
                        .foregroundColor(.primary)
                    
                    Text(attendanceErrorMessage)
                        .font(.system(size: 15))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 20)
                        .lineLimit(nil)
                }
                
                // Simple dismiss button
                Button(action: dismissAttendanceError) {
                    Text("OK")
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.white)
                        .frame(width: 100)
                        .padding(.vertical, 12)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.orange, Color.red]),
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .cornerRadius(10)
                }
            }
            .padding(24)
            .background(
                RoundedRectangle(cornerRadius: 16)
                    .fill(Color(.systemBackground))
                    .shadow(color: Color.black.opacity(0.1), radius: 15, x: 0, y: 8)
            )
            .padding(.horizontal, 40)
        }
        .animation(.easeInOut(duration: 0.3), value: showingAttendanceError)
    }
    // MARK: - Bluetooth Prompt Overlay
    var bluetoothPromptOverlay: some View {
        ZStack {
            Color.black.opacity(0.4)
                .ignoresSafeArea()
            
            BluetoothPromptView(
                promptType: bleManager.bluetoothPromptType,
                onOpenSettings: {
                    bleManager.openBluetoothSettings()
                },
                onRetry: {
                    bleManager.retryScanning()
                },
                onDismiss: {
                    bleManager.dismissBluetoothPrompt()
                    resetToHomeState()
                }
            )
        }
        .animation(.easeInOut(duration: 0.3), value: bleManager.showingBluetoothPrompt)
    }
    
    // MARK: - Computed Properties
    
    /// Check if the current session was just completed
    private var isCurrentSessionCompleted: Bool {
        guard let activeSession = firebaseManager.activeSession,
              let completedId = completedSessionId else {
            return false
        }
        return activeSession.sessionId == completedId
    }
    
    /// Dynamic button properties for intelligent detection
    private var detectionButtonIcon: String {
        if firebaseManager.isLoading {
            return "clock"
        } else if !firebaseManager.isSessionActive {
            return "arrow.clockwise"
        } else if isCurrentSessionCompleted {
            return "repeat"
        } else {
            return "wifi.circle"
        }
    }
    
    private var detectionButtonText: String {
        if firebaseManager.isLoading {
            return "Checking..."
        } else if !firebaseManager.isSessionActive {
            return "Check for Session"
        } else if isCurrentSessionCompleted {
            return "Mark Again"
        } else {
            return "Start Room Presence Detection"
        }
    }
    
    private var detectionButtonColors: [Color] {
        if !firebaseManager.isSessionActive {
            return [Color.orange, Color.red]  // Check for session
        } else if isCurrentSessionCompleted {
            return [Color.green, Color.blue]  // Mark again
        } else {
            return [Color.blue, Color.purple] // Start detection
        }
    }
    
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
                    // Check if this is a NEW session (different from completed one)
                    let isNewSession = !isCurrentSessionCompleted
                    
                    if isNewSession {
                        currentStatus = "Active session found! Starting room detection..."
                        
                        // Automatically start BLE detection for NEW sessions
                        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                            self.startBLEDetectionWithOverlay()
                        }
                    } else {
                        currentStatus = "Active session found! Ready for detection."
                        // Don't auto-start for completed sessions
                    }
                } else {
                    currentStatus = "No active session for your class."
                    // Clear completion state when no session
                    completedSessionId = nil
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
        
        // Check attendance rules BEFORE starting face authentication
        guard let device = bleManager.detectedDevice,
              let session = firebaseManager.activeSession else {
            showAttendanceError(message: "Session data not available")
            return
        }
        
        // Create attendance session for checking
        let tempSession = AttendanceSession(
            device: device,
            subjectCode: session.subject
        )
        
        // Check if attendance can be marked
        checkAttendanceEligibility(session: session, device: device) { canMark, errorMessage in
            DispatchQueue.main.async {
                if canMark {
                    // Attendance allowed - proceed with face authentication
                    self.attendanceManager.currentSession = tempSession
                    self.attendanceManager.showingFaceAuthentication = true
                } else {
                    // Attendance not allowed - show error
                    self.showAttendanceError(message: errorMessage ?? "Attendance cannot be marked")
                }
            }
        }
    }
    
    private func handleFaceAuthenticationSuccess(rollNumber: String) {
        guard var currentSession = attendanceManager.currentSession,
              let activeSession = firebaseManager.activeSession else {
            print("❌ No current session for face authentication success")
            return
        }
        
        print("✅ Face authentication successful for roll number: \(rollNumber)")
        
        // CRITICAL: Validate that face auth roll number matches logged-in student
        guard rollNumber == student.rollNumber else {
            print("❌ Roll number mismatch: Face auth returned \(rollNumber), but logged-in student is \(student.rollNumber)")
            
            // Hide face authentication
            attendanceManager.showingFaceAuthentication = false
            
            // Show security error
            showAttendanceError(message: "Face authentication failed: Roll number mismatch. Please ensure you are the logged-in student.")
            return
        }
        
        print("✅ Roll number validated: \(rollNumber) matches logged-in student")
        
        // Complete the session
        let result = FaceIOResult(
            rollNumber: rollNumber,
            success: true,
            message: "Face authentication successful"
        )
        
        currentSession.complete(with: result)
        attendanceManager.currentSession = currentSession
        
        // Mark attendance in Firebase (rules already checked)
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
                    
                    // Mark this specific session as completed
                    self.completedSessionId = activeSession.sessionId
                    
                case .failure(let error):
                    print("❌ Unexpected error after face auth: \(error)")
                    
                    // Hide face authentication
                    self.attendanceManager.showingFaceAuthentication = false
                    
                    // Show error (this should rarely happen since we pre-checked)
                    let errorMessage = self.formatAttendanceError(error)
                    self.showAttendanceError(message: errorMessage)
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
    
    // MARK: - New Methods for Enhanced Flow
    
    /// Show native attendance error alert
    private func showAttendanceError(message: String) {
        print("🚨 Showing attendance error: \(message)")
        attendanceErrorMessage = message
        showingAttendanceError = true
        resetToHomeState()
    }
    
    /// Dismiss attendance error alert
    private func dismissAttendanceError() {
        attendanceErrorMessage = ""
        // Alert automatically dismisses, no need to set showingAttendanceError = false
    }
    
    /// Restart detection for marking again (after successful attendance)
    private func restartDetection() {
        completedSessionId = nil // Clear completion state
        startBLEDetection()
    }
    
    /// Intelligent detection that handles all scenarios
    private func startIntelligentDetection() {
        if firebaseManager.isLoading {
            // Already loading, do nothing
            return
        } else if !firebaseManager.isSessionActive {
            // No active session - refresh to check for new sessions
            checkForActiveSession()
        } else if isCurrentSessionCompleted {
            // Session completed - restart for marking again
            restartDetection()
        } else {
            // Active session available - start BLE detection
            startBLEDetectionWithOverlay()
        }
    }
    
    /// Format attendance error for user-friendly display
    private func formatAttendanceError(_ error: Error) -> String {
        if let attendanceError = error as? AttendanceError {
            switch attendanceError {
            case .alreadyMarked:
                return "Attendance already marked for this session today"
            case .noActiveSession:
                return "No active session found"
            case .invalidSession:
                return "Invalid session data"
            }
        } else {
            // Handle other Firebase/network errors
            let errorDescription = error.localizedDescription
            if errorDescription.contains("network") || errorDescription.contains("internet") {
                return "Network connection error. Please check your internet."
            } else if errorDescription.contains("permission") {
                return "Permission denied. Please check app settings."
            } else {
                return "Failed to save attendance. Please try again."
            }
        }
    }
    
    /// Check attendance eligibility before face authentication
    private func checkAttendanceEligibility(session: ActiveSession, device: BLEDevice, completion: @escaping (Bool, String?) -> Void) {
        let currentDate = Date()
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let dateString = dateFormatter.string(from: currentDate)
        
        // Create monthly collection name
        let monthFormatter = DateFormatter()
        monthFormatter.dateFormat = "yyyy_MM"
        let monthString = monthFormatter.string(from: currentDate)
        let collectionName = "attendance_\(monthString)"
        
        // Use the same logic as FirebaseManager
        checkIfAttendanceAlreadyMarkedLocal(
            collectionName: collectionName,
            rollNumber: student.rollNumber,
            subject: session.subject,
            type: session.type,
            date: dateString,
            isExtra: session.isExtra ?? false
        ) { alreadyMarked in
            if alreadyMarked {
                let errorMessage = (session.isExtra ?? false) ?
                    "Extra class attendance already marked for \(session.subject) today" :
                    "Attendance already marked for \(session.type) today"
                completion(false, errorMessage)
            } else {
                completion(true, nil)
            }
        }
    }
    
    /// Local duplicate check method (mirrors FirebaseManager logic)
    private func checkIfAttendanceAlreadyMarkedLocal(
        collectionName: String,
        rollNumber: String,
        subject: String,
        type: String,
        date: String,
        isExtra: Bool,
        completion: @escaping (Bool) -> Void
    ) {
        let db = Firestore.firestore()
        let baseQuery = db.collection(collectionName)
            .whereField("rollNumber", isEqualTo: rollNumber)
            .whereField("subject", isEqualTo: subject)
            .whereField("date", isEqualTo: date)
            .whereField("present", isEqualTo: true)
        
        if isExtra {
            // For extra classes: Check if ANY extra class already marked for this subject today
            let extraQuery = baseQuery.whereField("isExtra", isEqualTo: true)
            
            extraQuery.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking existing extra attendance: \(error)")
                    completion(false) // Assume not marked to avoid blocking
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let alreadyMarked = !documents.isEmpty
                completion(alreadyMarked)
            }
        } else {
            // For regular classes: Check if same type already marked (exclude extra classes)
            let regularQuery = baseQuery
                .whereField("type", isEqualTo: type)
                .whereField("isExtra", isEqualTo: false)
            
            regularQuery.getDocuments { snapshot, error in
                if let error = error {
                    print("❌ Error checking existing regular attendance: \(error)")
                    completion(false) // Assume not marked to avoid blocking
                    return
                }
                
                let documents = snapshot?.documents ?? []
                let alreadyMarked = !documents.isEmpty
                completion(alreadyMarked)
            }
        }
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
