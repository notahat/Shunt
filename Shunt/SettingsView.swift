import ServiceManagement
import SwiftUI

/// Settings window content. Owns the switcher mode and open-at-login preferences.
struct SettingsView: View {
    @AppStorage(SwitcherMode.defaultsKey) private var switcherMode: SwitcherMode = .dock
    @State private var openAtLogin = false

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            VStack(alignment: .leading, spacing: 8) {
                Text("⌘-tab opens:").fontWeight(.medium)
                Picker("", selection: $switcherMode) {
                    Text("Dock").tag(SwitcherMode.dock)
                    Text("Raycast window switcher").tag(SwitcherMode.raycast)
                }
                .pickerStyle(.radioGroup)
                .labelsHidden()
            }
            Divider()
            Toggle("Open at login", isOn: $openAtLogin)
                .onChange(of: openAtLogin) { _, enabled in
                    do {
                        if enabled {
                            try SMAppService.mainApp.register()
                        } else {
                            try SMAppService.mainApp.unregister()
                        }
                    } catch {
                        print("Failed to update launch at login: \(error)")
                        openAtLogin = !enabled
                    }
                }
        }
        .padding()
        .frame(width: 280)
        .onAppear {
            openAtLogin = SMAppService.mainApp.status == .enabled
        }
    }
}

#Preview {
    let store = UserDefaults(suiteName: "preview")!
    store.set(SwitcherMode.raycast.rawValue, forKey: "switcherMode")
    return SettingsView()
        .defaultAppStorage(store)
}
