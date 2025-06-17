import SwiftUI

struct BluetoothPromptView: View {
    let promptType: BluetoothPromptType
    let onOpenSettings: () -> Void
    let onRetry: () -> Void
    let onDismiss: () -> Void
    
    var body: some View {
        if promptType.isSimplePrompt {
            simpleBluetoothPrompt
        } else {
            enhancedPermissionPrompt
        }
    }
    
    // MARK: - Simple Bluetooth Off Prompt
    var simpleBluetoothPrompt: some View {
        VStack(spacing: 20) {
            // Elegant Bluetooth Icon
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(
                            gradient: Gradient(colors: [
                                Color.blue.opacity(0.15),
                                Color.cyan.opacity(0.1)
                            ]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 70, height: 70)
                
                // Bluetooth logo with slash
                ZStack {
                    Image(systemName: "bluetooth")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(.blue.opacity(0.3))
                    
                    Image(systemName: "slash.circle")
                        .font(.system(size: 32, weight: .medium))
                        .foregroundStyle(
                            LinearGradient(
                                gradient: Gradient(colors: [Color.blue, Color.cyan]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                }
            }
            
            VStack(spacing: 12) {
                Text("Bluetooth is Off")
                    .font(.system(size: 20, weight: .semibold, design: .rounded))
                    .foregroundColor(.primary)
                
                Text("Please turn on Bluetooth to detect classroom devices")
                    .font(.system(size: 15))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                
                // Simple instruction without deep link
                Text("Settings → Bluetooth → Turn ON")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.blue)
                    .padding(.horizontal, 16)
                    .padding(.vertical, 8)
                    .background(
                        RoundedRectangle(cornerRadius: 8)
                            .fill(Color.blue.opacity(0.1))
                    )
            }
            
            // Simple retry button only
            Button(action: onRetry) {
                HStack(spacing: 8) {
                    Image(systemName: "arrow.clockwise")
                        .font(.system(size: 16))
                    Text("Retry")
                }
                .font(.system(size: 16, weight: .medium))
                .foregroundColor(.blue)
                .frame(maxWidth: .infinity)
                .padding(.vertical, 12)
                .background(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.blue, lineWidth: 2)
                )
            }
            
            Button(action: onDismiss) {
                Text("Cancel")
                    .font(.system(size: 14, weight: .medium))
                    .foregroundColor(.secondary)
                    .padding(.vertical, 4)
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.08), radius: 15, x: 0, y: 8)
        )
        .padding(.horizontal, 30)
    }
    
    // MARK: - Enhanced Permission Prompt
    var enhancedPermissionPrompt: some View {
        VStack(spacing: 24) {
            // Icon
            ZStack {
                Circle()
                    .fill(LinearGradient(
                        gradient: Gradient(colors: [iconColor.opacity(0.2), iconColor.opacity(0.1)]),
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ))
                    .frame(width: 80, height: 80)
                
                ZStack {
                    // Bluetooth logo background
                    Image(systemName: "bluetooth")
                        .font(.system(size: 28, weight: .medium))
                        .foregroundColor(iconColor.opacity(0.3))
                    
                    // Warning overlay
                    Image(systemName: iconName)
                        .font(.system(size: 36))
                        .foregroundColor(iconColor)
                }
            }
            
            VStack(spacing: 8) {
                Text(promptType.title)
                    .font(.system(size: 22, weight: .bold, design: .rounded))
                    .foregroundColor(.primary)
                    .multilineTextAlignment(.center)
                
                Text(promptType.message)
                    .font(.system(size: 16))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(nil)
            }
            
            // Instructions for Settings
            if promptType.showSettings {
                VStack(spacing: 12) {
                    Text("Quick Steps:")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(.primary)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        InstructionStep(number: 1, text: "Tap '\(promptType.actionTitle)' below")
                        
                        if promptType == .poweredOff {
                            InstructionStep(number: 2, text: "Find 'Bluetooth' in Settings")
                            InstructionStep(number: 3, text: "Turn ON the Bluetooth toggle")
                        } else {
                            InstructionStep(number: 2, text: "Find 'Smart Attend' in the list")
                            InstructionStep(number: 3, text: "Enable Bluetooth access")
                        }
                        
                        InstructionStep(number: 4, text: "Return to app and tap 'Retry'")
                    }
                }
                .padding(16)
                .background(
                    RoundedRectangle(cornerRadius: 12)
                        .fill(Color(.systemGray6))
                )
            }
            
            // Action Buttons
            VStack(spacing: 12) {
                if promptType.showSettings {
                    Button(action: onOpenSettings) {
                        HStack {
                            Image(systemName: "gear")
                            Text(promptType.actionTitle)
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
                    
                    Button(action: onRetry) {
                        HStack {
                            Image(systemName: "arrow.clockwise")
                            Text("Retry")
                        }
                        .font(.system(size: 16, weight: .medium))
                        .foregroundColor(.blue)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 12)
                        .background(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(Color.blue, lineWidth: 2)
                        )
                    }
                } else {
                    Button(action: onDismiss) {
                        Text("OK")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 16)
                            .background(
                                LinearGradient(
                                    gradient: Gradient(colors: [Color.gray, Color.gray.opacity(0.8)]),
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                }
                
                Button(action: onDismiss) {
                    Text("Cancel")
                        .font(.system(size: 14, weight: .medium))
                        .foregroundColor(.secondary)
                }
            }
        }
        .padding(24)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.1), radius: 20, x: 0, y: 10)
        )
        .padding(.horizontal, 20)
    }
    
    private var iconName: String {
        switch promptType {
        case .unauthorized:
            return "bluetooth.trianglebadge.exclamationmark"
        case .poweredOff:
            return "bluetooth.slash"
        case .unsupported:
            return "exclamationmark.triangle"
        }
    }
    
    private var iconColor: Color {
        switch promptType {
        case .poweredOff:
            return .blue
        case .unauthorized:
            return .orange
        case .unsupported:
            return .red
        }
    }
}

struct InstructionStep: View {
    let number: Int
    let text: String
    
    var body: some View {
        HStack(spacing: 12) {
            Text("\(number)")
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.white)
                .frame(width: 20, height: 20)
                .background(Circle().fill(Color.blue))
            
            Text(text)
                .font(.system(size: 14))
                .foregroundColor(.primary)
            
            Spacer()
        }
    }
}

#Preview {
    ZStack {
        Color(.systemGroupedBackground)
            .ignoresSafeArea()
        
        VStack(spacing: 30) {
            BluetoothPromptView(
                promptType: .poweredOff,
                onOpenSettings: { print("Open Settings") },
                onRetry: { print("Retry") },
                onDismiss: { print("Dismiss") }
            )
            
            BluetoothPromptView(
                promptType: .unauthorized,
                onOpenSettings: { print("Open Settings") },
                onRetry: { print("Retry") },
                onDismiss: { print("Dismiss") }
            )
        }
    }
}
