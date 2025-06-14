import SwiftUI

@main
struct Smart_AttendApp: App {
    
    // Handle app lifecycle for BLE scanning
    @Environment(\.scenePhase) private var scenePhase
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.none) // Supports both light and dark mode
                .onChange(of: scenePhase) { phase in
                    handleScenePhase(phase)
                }
        }
    }
    
    private func handleScenePhase(_ phase: ScenePhase) {
        switch phase {
        case .active:
            print("📱 App became active - BLE scanning will resume")
        case .inactive:
            print("📱 App became inactive")
        case .background:
            print("📱 App moved to background - BLE scanning continues")
        @unknown default:
            break
        }
    }
}
