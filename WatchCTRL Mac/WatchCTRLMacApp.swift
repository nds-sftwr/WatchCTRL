import SwiftUI

@main
struct WatchCTRLMacApp: App {
    @State private var sessionManager = MacSessionManager.shared

    init() {
        if !KeySimulator.hasAccessibilityPermission {
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                KeySimulator.requestAccessibilityPermission()
            }
        }
    }

    var body: some Scene {
        MenuBarExtra {
            StatusView()
                .environment(sessionManager)
        } label: {
            Image(systemName: sessionManager.isConnected ? "applewatch.radiowaves.left.and.right" : "applewatch")
        }
    }
}
