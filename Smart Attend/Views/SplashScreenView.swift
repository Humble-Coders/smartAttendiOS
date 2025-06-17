import SwiftUI

struct SplashScreenView: View {
    @State private var isAnimating = false
    @State private var opacity = 0.0
    @State private var brandingOpacity = 0.0
    @State private var logoScale = 0.8
    
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
                    
                    // Enhanced loading indicator
                    VStack(spacing: 16) {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: .white))
                            .scaleEffect(1.3)
                        
                        Text("Loading your experience...")
                            .font(.system(size: 16, weight: .medium))
                            .foregroundColor(.white.opacity(0.8))
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
                                    .white.opacity(0.6), // Increased from 0.4 to 0.6
                                    .white.opacity(0.7), // Added middle stop for more prominence
                                    .white.opacity(0.6),
                                    .clear
                                ],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(height: 1.5) // Slightly thicker
                        .frame(maxWidth: 160) // Slightly wider
                        .opacity(brandingOpacity)
                        .scaleEffect(x: brandingOpacity, y: 1.0, anchor: .center)
                    
                    // Refined branding text with sophisticated left-to-right reveal
                    HStack(spacing: 6) {
                        Group {
                            Text("A")
                                .opacity(brandingOpacity > 0 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0 ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0), value: brandingOpacity)
                            
                            Text("Humble")
                                .opacity(brandingOpacity > 0.15 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.15 ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.15), value: brandingOpacity)
                            
                            Text("Solutions")
                                .opacity(brandingOpacity > 0.3 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.3 ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.3), value: brandingOpacity)
                            
                            Text("Product")
                                .opacity(brandingOpacity > 0.45 ? 1.0 : 0.0)
                                .offset(x: brandingOpacity > 0.45 ? 0 : -30)
                                .animation(.spring(response: 0.6, dampingFraction: 0.8, blendDuration: 0).delay(0.45), value: brandingOpacity)
                        }
                        .font(.system(size: 17, weight: .semibold, design: .serif))
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
                    }
                    .tracking(2.0) // Premium letter spacing
                    .shadow(color: .black.opacity(0.4), radius: 8, x: 0, y: 4) // Strong shadow for prominence
                    .shadow(color: .white.opacity(0.1), radius: 2, x: 0, y: -1) // Subtle highlight for depth
                }
                .padding(.bottom, 50)
            }
        }
        .onAppear {
            startGracefulAnimations()
        }
    }
    
    private func startGracefulAnimations() {
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
        
        // Branding appears last
        withAnimation(.easeIn(duration: 0.8).delay(1.5)) {
            brandingOpacity = 1.0
        }
    }
}

#Preview {
    SplashScreenView()
}
