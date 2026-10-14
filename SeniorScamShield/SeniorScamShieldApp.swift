import SwiftUI
import AVFoundation

@main
struct SeniorScamShieldApp: App {
    @StateObject private var session = SessionStore()

    init() {
        do {
            try AVAudioSession.sharedInstance().setCategory(.playback, mode: .default)
            try AVAudioSession.sharedInstance().setActive(true)
        } catch {
            print("Failed to set audio session category: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            Group {
                if session.isLoggedIn {
                    ContentView()
                } else {
                    LoginView()
                }
            }
            .environmentObject(session)
            .onReceive(NotificationCenter.default.publisher(for: UserDefaults.didChangeNotification)) { _ in
                print("🌐 ROOT DEBUG: AppStorage updated -> isLoggedIn is currently: \(session.isLoggedIn)")
            }
        }
    }
}
