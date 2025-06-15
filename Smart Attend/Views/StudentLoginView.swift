import SwiftUI

// MARK: - Student Model
struct Student {
    let name: String
    let rollNumber: String
    let className: String
}

// MARK: - Login View
struct LoginView: View {
    @State private var name = ""
    @State private var rollNumber = ""
    @State private var className = ""
    @State private var showingAlert = false
    @State private var alertMessage = ""
    
    let onLoginSuccess: (Student) -> Void
    
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
                        
                        Text("Student Portal")
                            .font(.system(size: 18, weight: .medium))
                            .foregroundColor(.white.opacity(0.9))
                    }
                    
                    // Login Form
                    VStack(spacing: 20) {
                        Text("Sign In to Continue")
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
                        }
                        
                        // Roll Number Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Roll Number")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., 2021001", text: $rollNumber)
                                .textFieldStyle(CustomTextFieldStyle())
                                .keyboardType(.numberPad)
                        }
                        
                        // Class Field
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Class")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.secondary)
                            
                            TextField("e.g., 2S12", text: $className)
                                .textFieldStyle(CustomTextFieldStyle())
                                .autocapitalization(.allCharacters)
                        }
                        
                        // Login Button
                        Button(action: handleLogin) {
                            HStack {
                                Image(systemName: "arrow.right.circle.fill")
                                Text("Sign In")
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
                        .disabled(!isFormValid)
                        .opacity(isFormValid ? 1.0 : 0.6)
                    }
                    .padding(.horizontal, 24)
                    .padding(.vertical, 32)
                    .background(
                        RoundedRectangle(cornerRadius: 20)
                            .fill(Color(.systemBackground))
                            .shadow(color: .black.opacity(0.1), radius: 20, x: 0, y: 10)
                    )
                    .padding(.horizontal, 20)
                    
                    // Testing Note
                    VStack(spacing: 8) {
                        Text("Testing Mode")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(.white)
                        
                        Text("Use any valid details for testing. Your session will be saved locally.")
                            .font(.system(size: 14))
                            .foregroundColor(.white.opacity(0.8))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .padding(.vertical, 16)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(Color.black.opacity(0.2))
                    )
                    .padding(.horizontal, 20)
                    
                    Spacer(minLength: 30)
                }
            }
        }
        .alert("Login Error", isPresented: $showingAlert) {
            Button("OK") { }
        } message: {
            Text(alertMessage)
        }
    }
    
    private var isFormValid: Bool {
        !name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !rollNumber.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty &&
        !className.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    
    private func handleLogin() {
        let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedRoll = rollNumber.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedClass = className.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        // Basic validation
        guard trimmedName.count >= 2 else {
            showError("Please enter a valid name (at least 2 characters)")
            return
        }
        
        guard trimmedRoll.count >= 4 else {
            showError("Please enter a valid roll number (at least 4 characters)")
            return
        }
        
        guard trimmedClass.count >= 2 else {
            showError("Please enter a valid class name")
            return
        }
        
        let student = Student(
            name: trimmedName,
            rollNumber: trimmedRoll,
            className: trimmedClass
        )
        
        // Success - call completion handler
        onLoginSuccess(student)
    }
    
    private func showError(_ message: String) {
        alertMessage = message
        showingAlert = true
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
    LoginView { student in
        print("Logged in: \(student.name) - \(student.rollNumber) - \(student.className)")
    }
}
