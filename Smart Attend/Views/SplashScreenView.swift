import SwiftUI
import FirebaseFirestore

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    @State private var brandingOpacity = 0.0
    @State private var logoScale = 0.8
    @State private var loadingProgress = 0.0
    @State private var statusMessage = "Initializing..."
    
    // Face recognition toggle state
    @State private var faceRecognitionEnabled: Bool = true
    
    var body: some View {
        ZStack {
            // Background gradient - deeper bluish tones
            LinearGradient(
                gradient: Gradient(colors: [
                    Color.blue.opacity(0.85),
                    Color.cyan.opacity(0.7),
                    Color.indigo.opacity(0.75)
                ]),
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            .ignoresSafeArea()
            
            VStack {
                Spacer()
                Spacer() // Extra spacer to push content more towards center
                
                VStack(spacing: 32) {
                    // App Icon with enhanced animation
                    Image(systemName: "graduationcap.circle.fill")
                        .font(.system(size: 110))
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.white, .white.opacity(0.9)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .scaleEffect(logoScale)
                        .shadow(color: .black.opacity(0.3), radius: 20, x: 0, y: 10)
                        .overlay(
                            // Subtle glow effect
                            Image(systemName: "graduationcap.circle.fill")
                                .font(.system(size: 110))
                                .foregroundColor(.white.opacity(0.3))
                                .scaleEffect(isAnimating ? 1.2 : 1.0)
                                .opacity(isAnimating ? 0 : 0.5)
                        )
                    
                    VStack(spacing: 12) {
                        Text("Smart Attend")
                            .font(.system(size: 42, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: [.white, .white.opacity(0.95)],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .shadow(color: .black.opacity(0.2), radius: 5, x: 0, y: 2)
                        
                        Text("Student Portal")
                            .font(.system(size: 20, weight: .medium, design: .rounded))
                            .foregroundColor(.white.opacity(0.9))
                            .tracking(1.2)
                    }
                    .opacity(opacity)
                    
                    // Enhanced loading indicator with progress
                    VStack(spacing: 16) {
                        // Progress bar
                        VStack(spacing: 8) {
                            ZStack(alignment: .leading) {
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white.opacity(0.3))
                                    .frame(width: 200, height: 8)
                                
                                RoundedRectangle(cornerRadius: 4)
                                    .fill(Color.white)
                                    .frame(width: 200 * loadingProgress, height: 8)
                                    .animation(.easeInOut(duration: 0.3), value: loadingProgress)
                            }
                            
                            Text(statusMessage)
                                .font(.system(size: 16, weight: .medium))
                                .foregroundColor(.white.opacity(0.8))
                                .animation(.easeInOut(duration: 0.2), value: statusMessage)
                        }
                        
                        // Face recognition status indicator
                        HStack(spacing: 8) {
                            Image(systemName: faceRecognitionEnabled ? "faceid" : "wifi.circle")
                                .font(.system(size: 14))
                                .foregroundColor(.white.opacity(0.7))
                            
                            Text(faceRecognitionEnabled ? "Face Recognition Enabled" : "Direct Marking Enabled")
                                .font(.system(size: 14, weight: .medium))
                                .foregroundColor(.white.opacity(0.7))
                        }
                        .opacity(loadingProgress > 0.3 ? 1.0 : 0.0)
                        .animation(.easeInOut(duration: 0.5), value: loadingProgress)
                    }
                    .opacity(opacity)
                }
                
                Spacer()
                Spacer()
                Spacer() // Extra spacers to balance the content positioning
                
                // Elegant branding at bottom
                VStack(spacing: 12) {
                    // More prominent subtle divider line
                    Rectangle()
                        .fill(
                            LinearGradient(
                                colors: [
                                    .clear,
                                    .white.opacity(0.6),
                                    .white.opacity(0.7),
                                    .white.opacity(0.6),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5)
                        .frame(maxWidth: 180)
                        .opacity(brandingOpacity)
                        .scaleEffect(x: brandingOpacity, y: 1.0, anchor: .center)
                    
                    // College name in two lines for better readability
                    VStack(spacing: 2) {
                        // First line: THAPAR INSTITUTE
                        HStack(spacing: 4) {
                            Text("THAPAR")
                                .opacity(brandingOpacity > 0 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0 ? 0 : -20)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.1), value: brandingOpacity)
                            
                            Text("INSTITUTE")
                                .opacity(brandingOpacity > 0.2 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.2 ? 0 : -20)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.3), value: brandingOpacity)
                        }
                        
                        // Second line: OF ENGINEERING & TECHNOLOGY
                        HStack(spacing: 3) {
                            Text("OF")
                                .opacity(brandingOpacity > 0.4 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.4 ? 0 : -15)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.5), value: brandingOpacity)
                            
                            Text("ENGINEERING")
                                .opacity(brandingOpacity > 0.6 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.6 ? 0 : -15)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.7), value: brandingOpacity)
                            
                            Text("&")
                                .opacity(brandingOpacity > 0.8 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.8 ? 0 : -10)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(0.9), value: brandingOpacity)
                            
                            Text("TECHNOLOGY")
                                .opacity(brandingOpacity > 0.9 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.9 ? 0 : -15)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8).delay(1.1), value: brandingOpacity)
                        }
                    }
                    .font(.system(size: 14, weight: .medium, design: .serif))
                    .foregroundStyle(
                        LinearGradient(
                            colors: [
                                .white,
                                .white.opacity(0.95)
                            ],
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .tracking(1.2)
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4)
                    .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1)
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startEnhancedLoadingSequence()
        }
    }
    
    private func startEnhancedLoadingSequence() {
        // Logo scale and glow animation
        withAnimation(.easeOut(duration: 1.2)) {
            logoScale = 1.0
        }
        
        // Main content fade in
        withAnimation(.easeIn(duration: 1.0).delay(0.3)) {
            opacity = 1.0
        }
        
        // Pulsing glow effect
        withAnimation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true).delay(0.5)) {
            isAnimating = true
        }
        
        // Start loading sequence
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            startLoadingSteps()
        }
        
        // Branding appears last
        withAnimation(.easeIn(duration: 0.8).delay(3.5)) {
            brandingOpacity = 1.0
        }
    }
    
    private func startLoadingSteps() {
        // Step 1: Initialize Firebase
        updateLoadingStep(progress: 0.2, message: "Connecting...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            // Step 2: Check face recognition toggle
            self.checkFaceRecognitionToggle()
        }
    }
    
    private func checkFaceRecognitionToggle() {
        updateLoadingStep(progress: 0.4, message: "Checking authentication settings...")
        
        let db = Firestore.firestore()
        
        Task {
            do {
                let document = try await db.collection("adminToggles").document("faceRecognition").getDocument()
                
                await MainActor.run {
                    if document.exists, let data = document.data() {
                        let toggles = AdminToggles(from: data)
                        self.faceRecognitionEnabled = toggles.faceRecognitionEnabled
                        
                        print("🔧 Face Recognition Toggle Status: \(toggles.faceRecognitionEnabled ? "ENABLED" : "DISABLED")")
                        
                        // Step 3: Authentication settings confirmed
                        self.updateLoadingStep(
                            progress: 0.6,
                            message: toggles.faceRecognitionEnabled ? "Face recognition ready" : "Direct marking ready"
                        )
                    } else {
                        self.faceRecognitionEnabled = true // Default to enabled if document doesn't exist
                        print("🔧 Face Recognition Toggle document not found - defaulting to ENABLED")
                        
                        self.updateLoadingStep(progress: 0.6, message: "Face recognition ready (default)")
                    }
                    
                    // Continue loading sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.continueLoadingSequence()
                    }
                }
            } catch {
                await MainActor.run {
                    self.faceRecognitionEnabled = true // Default to enabled on error
                    print("❌ Error checking face recognition toggle: \(error) - defaulting to ENABLED")
                    
                    self.updateLoadingStep(progress: 0.6, message: "Authentication ready (fallback)")
                    
                    // Continue loading sequence
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
                        self.continueLoadingSequence()
                    }
                }
            }
        }
    }
    
    private func continueLoadingSequence() {
        // Step 4: Loading user preferences
        updateLoadingStep(progress: 0.8, message: "Loading user preferences...")
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.6) {
            // Step 5: Finalizing setup
            self.updateLoadingStep(progress: 1.0, message: "Ready to start!")
            
            // Small delay before completion
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                // The splash screen will be dismissed by the parent view's logic
                // This enhanced splash ensures face recognition toggle is checked before app starts
            }
        }
    }
    
    private func updateLoadingStep(progress: Double, message: String) {
        withAnimation(.easeInOut(duration: 0.3)) {
            loadingProgress = progress
        }
        
        withAnimation(.easeInOut(duration: 0.2)) {
            statusMessage = message
        }
    }
}


#Preview {
    SplashScreenView()
}
