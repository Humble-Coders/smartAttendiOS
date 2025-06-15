import SwiftUI
import FirebaseCore

@main
struct Smart_AttendApp: App {
    
    init() {
        // Configure Firebase
        FirebaseApp.configure()
        print("🔥 Firebase configured successfully")
    }
    
    var body: some Scene {
        WindowGroup {
            MainAppView()
                .preferredColorScheme(.none) // Supports both light and dark mode
        }
    }
}
