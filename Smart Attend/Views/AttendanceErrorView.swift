import SwiftUI

struct AttendanceErrorView: View {
    let errorType: FaceIOError
    let session: AttendanceSession?
    let onDismiss: () -> Void
    let onRetry: () -> Void
    
    @State private var showingIcon = false
    @State private var showingContent = false
    
    var body: some View {
        VStack(spacing: 32) {
            Spacer()
            
            // Error Animation
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [errorColor.opacity(0.1), errorColor.opacity(0.05)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 120, height: 120)
                    .scaleEffect(showingIcon ? 1.0 : 0.5)
                    .opacity(showingIcon ? 1.0 : 0.0)
                
                Image(systemName: errorIcon)
                    .font(.system(size: 64))
                    .foregroundColor(errorColor)
                    .scaleEffect(showingIcon ? 1.0 : 0.1)
                    .opacity(showingIcon ? 1.0 : 0.0)
            }
            
            if showingContent {
                VStack(spacing: 24) {
                    // Error Message
                    VStack(spacing: 8) {
                        Text("Authentication Failed")
                            .font(.system(size: 28, weight: .bold))
                            .foregroundColor(.primary)
                        
                        Text(errorType.errorDescription ?? "An error occurred during face authentication")
                            .font(.system(size: 16))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                    }
                    .opacity(showingContent ? 1.0 : 0.0)
                    .offset(y: showingContent ? 0 : 20)
                    
                    // Session Details Card (if available)
                    if let session = session {
                        VStack(spacing: 16) {
                            VStack(spacing: 8) {
                                Text("Session Information")
                                    .font(.system(size: 14, weight: .medium))
                                    .foregroundColor(.secondary)
                                
                                Text(session.subjectCode)
                                    .font(.system(size: 20, weight: .bold, design: .monospaced))
                                    .foregroundColor(.blue)
                                    .padding(.horizontal, 20)
                                    .padding(.vertical, 8)
                                    .background(
                                        RoundedRectangle(cornerRadius: 12)
                                            .fill(Color.blue.opacity(0.1))
                                    )
                            }
                            
                            Divider()
                                .padding(.horizontal, 20)
                            
                            // Session Information
                            VStack(spacing: 12) {
                                ErrorDetailRow(
                                    icon: "wifi",
                                    title: "Device",
                                    value: session.device.name,
                                    color: .blue
                                )
                                
                                ErrorDetailRow(
                                    icon: "clock.fill",
                                    title: "Time",
                                    value: formatTime(session.startTime),
                                    color: .green
                                )
                                
                                ErrorDetailRow(
                                    icon: "exclamationmark.triangle.fill",
                                    title: "Error",
                                    value: errorType.shortDescription,
                                    color: errorColor
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
                    
                    // Error-specific guidance
                    if let guidance = errorGuidance {
                        Text(guidance)
                            .font(.system(size: 14))
                            .foregroundColor(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 12)
                            .background(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(Color(.systemGray6))
                            )
                            .opacity(showingContent ? 1.0 : 0.0)
                            .offset(y: showingContent ? 0 : 20)
                    }
                }
            }
            
            Spacer()
            
            // Action Buttons
            if showingContent {
                VStack(spacing: 12) {
                    // Retry button (for retryable errors)
                    if isRetryableError {
                        Button(action: onRetry) {
                            HStack {
                                Image(systemName: "arrow.clockwise")
                                Text("Try Again")
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
                    }
                    
                    // Back to Home button
                    Button(action: onDismiss) {
                        HStack {
                            Image(systemName: "house.fill")
                            Text("Back to Home")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(isRetryableError ? .secondary : .white)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            isRetryableError ?
                            AnyView(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color(.systemGray4), lineWidth: 1)
                            ) :
                            AnyView(
                                LinearGradient(
                                    gradient: Gradient(colors: [errorColor, errorColor.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                        )
                        .cornerRadius(12)
                    }
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
                    errorColor.opacity(0.05)
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
        // First show error icon
        withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
            showingIcon = true
        }
        
        // Then show content
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            withAnimation(.easeOut(duration: 0.8)) {
                showingContent = true
            }
        }
    }
    
    // MARK: - Computed Properties
    
    private var errorColor: Color {
        switch errorType {
        case .cameraPermissionDenied, .unauthorized:
            return .orange
        case .networkError, .initializationFailed:
            return .red
        case .noFaceDetected, .faceNotRecognized, .multipleFacesDetected:
            return .blue
        case .faceSpoofingDetected:
            return .purple
        default:
            return .red
        }
    }
    
    private var errorIcon: String {
        switch errorType {
        case .cameraPermissionDenied:
            return "camera.fill.badge.ellipsis"
        case .noFaceDetected:
            return "person.crop.circle.badge.questionmark"
        case .faceNotRecognized:
            return "person.crop.circle.badge.exclamationmark"
        case .multipleFacesDetected:
            return "person.2.crop.square.stack"
        case .faceSpoofingDetected:
            return "exclamationmark.shield"
        case .networkError:
            return "wifi.exclamationmark"
        case .unauthorized:
            return "lock.trianglebadge.exclamationmark"
        case .sessionExpired, .operationTimedOut:
            return "clock.badge.exclamationmark"
        case .tooManyRequests:
            return "hand.raised"
        default:
            return "exclamationmark.triangle"
        }
    }
    
    private var isRetryableError: Bool {
        switch errorType {
        case .noFaceDetected, .faceNotRecognized, .multipleFacesDetected,
             .faceSpoofingDetected, .networkError, .processingError,
             .operationTimedOut, .sessionExpired:
            return true
        case .cameraPermissionDenied, .unauthorized, .initializationFailed, .tooManyRequests:
            return false
        default:
            return true
        }
    }
    
    private var errorGuidance: String? {
        switch errorType {
        case .cameraPermissionDenied:
            return "Please go to Settings > Smart Attend > Camera and allow camera access"
        case .noFaceDetected:
            return "Make sure your face is clearly visible and well-lit"
        case .faceNotRecognized:
            return "Ensure you are registered in the system and try again"
        case .multipleFacesDetected:
            return "Make sure only one person is visible in the camera"
        case .faceSpoofingDetected:
            return "Please use your actual face, not a photo or video"
        case .networkError:
            return "Check your internet connection and try again"
        case .sessionExpired:
            return "The session has expired. Please start again"
        case .tooManyRequests:
            return "Please wait a moment before trying again"
        default:
            return nil
        }
    }
    
    private func formatTime(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

struct ErrorDetailRow: View {
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
                .lineLimit(1)
        }
    }
}

// MARK: - FaceIOError Extension
extension FaceIOError {
    var shortDescription: String {
        switch self {
        case .cameraPermissionDenied:
            return "Camera Access Denied"
        case .noFaceDetected:
            return "No Face Detected"
        case .faceNotRecognized:
            return "Face Not Recognized"
        case .multipleFacesDetected:
            return "Multiple Faces"
        case .faceSpoofingDetected:
            return "Spoofing Detected"
        case .networkError:
            return "Network Error"
        case .wrongPinCode:
            return "Wrong PIN"
        case .processingError:
            return "Processing Error"
        case .unauthorized:
            return "Unauthorized"
        case .termsNotAccepted:
            return "Terms Not Accepted"
        case .uiNotReady:
            return "UI Not Ready"
        case .sessionExpired:
            return "Session Expired"
        case .operationTimedOut:
            return "Timeout"
        case .tooManyRequests:
            return "Too Many Requests"
        case .initializationFailed:
            return "Initialization Failed"
        case .unknown(let code):
            return "Error \(code)"
        }
    }
}
