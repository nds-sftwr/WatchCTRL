import SwiftUI

struct StatusView: View {
    @Environment(MacSessionManager.self) private var sessionManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Header
            HStack {
                Image(systemName: "applewatch.radiowaves.left.and.right")
                    .font(.title3)
                Text("WatchCTRL")
                    .font(.headline)
            }
            .padding(.bottom, 2)

            Divider()

            // Connection status
            HStack(spacing: 6) {
                Circle()
                    .fill(sessionManager.isConnected ? .green : .orange)
                    .frame(width: 8, height: 8)
                if let name = sessionManager.connectedDeviceName {
                    Text("Connected: \(name)")
                        .font(.subheadline)
                } else {
                    Text("Waiting for iPhone...")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
            }

            // Last action
            if let action = sessionManager.lastAction, let time = sessionManager.lastActionTime {
                HStack(spacing: 6) {
                    Image(systemName: "arrow.right.circle.fill")
                        .foregroundStyle(.blue)
                    Text(action.replacingOccurrences(of: "_", with: " "))
                        .font(.subheadline)
                    Spacer()
                    Text(time, style: .relative)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }

            Divider()

            // Accessibility permission
            HStack(spacing: 6) {
                Image(systemName: KeySimulator.hasAccessibilityPermission ? "checkmark.shield.fill" : "exclamationmark.shield.fill")
                    .foregroundStyle(KeySimulator.hasAccessibilityPermission ? .green : .red)
                Text(KeySimulator.hasAccessibilityPermission ? "Accessibility Granted" : "Accessibility Required")
                    .font(.subheadline)
            }

            if !KeySimulator.hasAccessibilityPermission {
                Button("Grant Accessibility Access") {
                    KeySimulator.requestAccessibilityPermission()
                }
            }

            Divider()

            // Listening toggle
            Toggle("Accept Connections", isOn: Binding(
                get: { sessionManager.isListening },
                set: { newValue in
                    if newValue {
                        sessionManager.startListening()
                    } else {
                        sessionManager.stopListening()
                    }
                }
            ))
            .font(.subheadline)

            Divider()

            Button("Quit WatchCTRL") {
                NSApplication.shared.terminate(nil)
            }
        }
        .padding()
        .frame(width: 260)
    }
}
