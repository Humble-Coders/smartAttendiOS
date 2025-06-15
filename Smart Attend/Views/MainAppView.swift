import SwiftUI

struct MainAppView: View {
    @State private var currentStudent: Student?
    @State private var isLoggedIn = false
    
    var body: some View {
        Group {
            if isLoggedIn, let student = currentStudent {
                StudentHomeView(
                    student: student,
                    onLogout: handleLogout
                )
            } else {
                LoginView(onLoginSuccess: handleLogin)
            }
        }
        .animation(.easeInOut(duration: 0.5), value: isLoggedIn)
    }
    
    private func handleLogin(student: Student) {
        currentStudent = student
        isLoggedIn = true
        
        print("✅ Student logged in:")
        print("   👤 Name: \(student.name)")
        print("   🎓 Roll: \(student.rollNumber)")
        print("   📚 Class: \(student.className)")
    }
    
    private func handleLogout() {
        currentStudent = nil
        isLoggedIn = false
        
        print("👋 Student logged out")
    }
}

#Preview {
    MainAppView()
}
