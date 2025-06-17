import SwiftUI

struct MainAppView: View {
    @StateObject private var authManager = StudentAuthManager()
    
    var body: some View {
        Group {
            if authManager.isLoading {
                SplashScreenView()
            } else if authManager.isLoggedIn, let student = authManager.currentStudent {
                StudentHomeView(
                    student: student,
                    onLogout: authManager.logout
                )
            } else {
                LoginView(onLoginSuccess: handleLogin)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: authManager.isLoggedIn)
        .animation(.easeInOut(duration: 0.3), value: authManager.isLoading)
    }
    
    private func handleLogin(name: String, rollNumber: String, className: String) -> Bool {
        return authManager.login(name: name, rollNumber: rollNumber, className: className)
    }
}
