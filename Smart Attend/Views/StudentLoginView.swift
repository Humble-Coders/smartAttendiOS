import SwiftUI

// MARK: - Student Model (keep existing)
struct Student {
    let name: String
    let rollNumber: String
    let className: String
}

// MARK: - Enhanced Login View with Face Registration
struct LoginView: View {
    @State private var name = ""
    @State private var rollNumber = ""
    @State private var className = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    @State private var isLoggingIn = false
    
    // Face Registration States
    @State private var showingFaceRegistration = false
    @State private var faceRegistrationResult: FaceRegistrationResult?
    @State private var registrationStep: RegistrationStep = .credentials
    
    let onLoginSuccess: (String, String, String, FaceRegistrationResult?) -> Bool
    
    enum RegistrationStep {
        case credentials
        case faceRegistration
        case completed
    }
    
    var body: some View {
        ZStack {
            // Background gradient
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.6),
                    Color.purple.opacity(0.4)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 30) {
                    Spacer(minLength: 50)
                    
                    // App Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "graduationcap.circle.fill")
                            .font(.system(size: 80))
                            .foregroundColor(.white)
                            .shadow(color: .black.opacity(0.2), radius: 10, x: 0, y: 5)
                        
                        Text("Smart Attend")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.white)
                        
                        Text("Student Registration")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Registration Progress Indicator
                    registrationProgressView
                    
                    // Main Content based on step
                    Group {
                        switch registrationStep {
                        case .credentials:
                            credentialsFormView
                        case .faceRegistration:
                            faceRegistrationInstructionsView
                        case .completed:
                            completedRegistrationView
                        }
                    }
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .alert("Registration Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
        // Face Registration Sheet
        .fullScreenCover(isPresented: $showingFaceRegistration) {
            NavigationView {
                FaceRegistrationWebView(
                    rollNumber: rollNumber,
                    onFaceRegistered: { faceId in
                        handleFaceRegistrationSuccess(faceId: faceId)
                    },
                    onError: { error in
                        handleFaceRegistrationError(error: error)
                    },
                    onClose: {
                        handleFaceRegistrationClose()
                    }
                )
                .navigationTitle("Face Registration")
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            handleFaceRegistrationClose()
                        }
                    }
                }
            }
        }
    }
    
    // MARK: - Registration Progress View
    var registrationProgressView: some View {
        HStack(spacing: 12) {
            ForEach(0..<3) { index in
                HStack(spacing: 8) {
                    Circle()
                        .fill(stepColor(for: index))
                        .frame(width: 12, height: 12)
                    
                    if index < 2 {
                        Rectangle()
                            .fill(stepColor(for: index).opacity(0.3))
                            .frame(width: 30, height: 2)
                    }
                }
            }
        }
        .padding(.horizontal, 20)
    }
    
    // MARK: - Credentials Form View
    var credentialsFormView: some View {
        VStack(spacing: 20) {
            Text("Personal Information")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
                .padding(.bottom, 10)
            
            // Name Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Full Name")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("Enter your full name", text: $name)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.words)
                    .disabled(isLoggingIn)
            }
            
            // Roll Number Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Roll Number")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("e.g., 2021001", text: $rollNumber)
                    .textFieldStyle(CustomTextFieldStyle())
                    .keyboardType(.numberPad)
                    .disabled(isLoggingIn)
            }
            
            // Class Field
            VStack(alignment: .leading, spacing: 8) {
                Text("Class")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                
                TextField("e.g., 2S12", text: $className)
                    .textFieldStyle(CustomTextFieldStyle())
                    .autocapitalization(.allCharacters)
                    .disabled(isLoggingIn)
            }
            
            // Continue to Face Registration Button
            Button(action: proceedToFaceRegistration) {
                HStack {
                    Image(systemName: "person.crop.circle.badge.plus")
                    Text("Continue to Face Registration")
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
                .shadow(color: .blue.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(!isFormValid || isLoggingIn)
            .opacity(isFormValid && !isLoggingIn ? 1.0 : 0.6)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Face Registration Instructions View
    var faceRegistrationInstructionsView: some View {
        VStack(spacing: 24) {
            Text("Face Registration")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.primary)
            
            VStack(spacing: 16) {
                Image(systemName: "faceid")
                    .font(.system(size: 60))
                    .foregroundColor(.blue)
                
                VStack(spacing: 12) {
                    Text("Secure Your Account")
                        .font(.system(size: 20, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    Text("Face registration is required for secure attendance marking. This ensures only you can mark your attendance.")
                        .font(.system(size: 16))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 16)
                }
                
                // Instructions
                VStack(alignment: .leading, spacing: 12) {
                    InstructionRow(
                        number: 1,
                        text: "Look directly at the camera",
                        icon: "eye"
                    )
                    InstructionRow(
                        number: 2,
                        text: "Ensure good lighting on your face",
                        icon: "sun.max"
                    )
                    InstructionRow(
                        number: 3,
                        text: "Keep your face centered in frame",
                        icon: "viewfinder"
                    )
                    InstructionRow(
                        number: 4,
                        text: "Avoid wearing masks or sunglasses",
                        icon: "exclamationmark.triangle"
                    )
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
                
                // Roll Number Display
                VStack(spacing: 4) {
                    Text("Registering for:")
                        .font(.system(size: 14))
                        .foregroundColor(.secondary)
                    Text(rollNumber)
                        .font(.system(size: 18, weight: .bold, design: .monospaced))
                        .foregroundColor(.blue)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 8)
                        .background(
                            RoundedRectangle(cornerRadius: 8)
                                .fill(Color.blue.opacity(0.1))
                        )
                }
            }
            
            VStack(spacing: 12) {
                // Start Face Registration Button
                Button(action: startFaceRegistration) {
                    HStack {
                        Image(systemName: "camera.fill")
                        Text("Start Face Registration")
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
                
                // Back Button
                Button(action: { registrationStep = .credentials }) {
                    HStack {
                        Image(systemName: "chevron.left")
                        Text("Back to Information")
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
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Completed Registration View
    var completedRegistrationView: some View {
        VStack(spacing: 24) {
            // Success Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [Color.green.opacity(0.2), Color.blue.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 100, height: 100)
                
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 60))
                    .foregroundColor(.green)
            }
            
            VStack(spacing: 12) {
                Text("Registration Complete!")
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(.primary)
                
                Text("Face registered successfully!")
                    .font(.system(size: 16))
                    .foregroundColor(.green)
            }
            
            // Student Summary
            VStack(spacing: 12) {
                SummaryRow(title: "Name", value: name, icon: "person.fill")
                SummaryRow(title: "Roll Number", value: rollNumber, icon: "number")
                SummaryRow(title: "Class", value: className, icon: "building.2")
                
                if let result = faceRegistrationResult {
                    SummaryRow(title: "Face ID", value: String(result.faceId.prefix(8)) + "...", icon: "faceid")
                }
            }
            .padding(16)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
            )
            
            // Complete Button
            Button(action: completeRegistration) {
                HStack {
                    if isLoggingIn {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(0.8)
                    } else {
                        Image(systemName: "arrow.right.circle.fill")
                        Text("Complete Registration")
                    }
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
                .shadow(color: .green.opacity(0.3), radius: 8, x: 0, y: 4)
            }
            .disabled(isLoggingIn)
        }
        .padding(.horizontal, 24)
        .padding(.vertical, 32)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    // MARK: - Helper Methods
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !rollNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func stepColor(for index: Int) -> Color {
        switch (index, registrationStep) {
        case (0, .credentials), (0, .faceRegistration), (0, .completed):
            return .green
        case (1, .faceRegistration), (1, .completed):
            return .green
        case (2, .completed):
            return .green
        case (1, .credentials), (2, .credentials), (2, .faceRegistration):
            return .gray.opacity(0.3)
        default:
            return .gray.opacity(0.3)
        }
    }
    
    private func proceedToFaceRegistration() {
        guard validateForm() else { return }
        
        withAnimation(.easeInOut(duration: 0.3)) {
            registrationStep = .faceRegistration
        }
    }
    
    private func startFaceRegistration() {
        showingFaceRegistration = true
    }
    
    private func handleFaceRegistrationSuccess(faceId: String) {
        let result = FaceRegistrationResult(
            rollNumber: rollNumber,
            faceId: faceId,
            success: true,
            message: "Face registered successfully"
        )
        
        faceRegistrationResult = result
        showingFaceRegistration = false
        
        withAnimation(.easeInOut(duration: 0.3)) {
            registrationStep = .completed
        }
    }
    
    private func handleFaceRegistrationError(error: String) {
        showingFaceRegistration = false
        showError("Face registration failed: \(error). Please try again.")
    }
    
    private func handleFaceRegistrationClose() {
        showingFaceRegistration = false
        // Stay on face registration step to allow retry
    }
    
    private func completeRegistration() {
        guard validateForm() else { return }
        
        // Ensure face registration is completed
        guard let _ = faceRegistrationResult else {
            showError("Face registration is required to complete signup.")
            return
        }
        
        isLoggingIn = true
        
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRoll = rollNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClass = className.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Attempt login with authentication manager
        let success = onLoginSuccess(trimmedName, trimmedRoll, trimmedClass, faceRegistrationResult)
        
        DispatchQueue.main.async {
            self.isLoggingIn = false
            
            if !success {
                self.showError("Failed to complete registration. Please try again.")
            }
        }
    }
    
    private func validateForm() -> Bool {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRoll = rollNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClass = className.trimmingCharacters(in: .whitespacesAndNewlines)
        
        guard trimmedName.count >= 2 else {
            showError("Please enter a valid name (at least 2 characters)")
            return false
        }
        
        guard trimmedRoll.count >= 4 else {
            showError("Please enter a valid roll number (at least 4 characters)")
            return false
        }
        
        guard trimmedClass.count >= 2 else {
            showError("Please enter a valid class name")
            return false
        }
        
        return true
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
    }
}

// MARK: - Supporting Views

struct InstructionRow: View {
    let number: Int
    let text: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(Color.blue)
                    .frame(width: 24, height: 24)
                
                Text("\(number)")
                    .font(.system(size: 12, weight: .bold))
                    .foregroundColor(.white)
            }
            
            HStack(spacing: 8) {
                Image(systemName: icon)
                    .font(.system(size: 14))
                    .foregroundColor(.blue)
                    .frame(width: 20)
                
                Text(text)
                    .font(.system(size: 14))
                    .foregroundColor(.primary)
            }
            
            Spacer()
        }
    }
}

struct SummaryRow: View {
    let title: String
    let value: String
    let icon: String
    
    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16))
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

// MARK: - Custom Text Field Style
struct CustomTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(Color(.systemGray6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 10)
                    .stroke(Color.blue.opacity(0.3), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView { name, rollNumber, className, faceResult in
        print("Registered: \(name) - \(rollNumber) - \(className)")
        if let faceResult = faceResult {
            print("Face ID: \(faceResult.faceId)")
        }
        return true
    }
}
