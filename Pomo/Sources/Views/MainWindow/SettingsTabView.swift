import SwiftUI
import ServiceManagement

struct SettingsTabView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("System Notifications", isOn: $settings.systemNotificationsEnabled)
                Toggle("Sound", isOn: $settings.soundEnabled)
                Toggle("Visual (Menu Bar Pulse)", isOn: $settings.visualNotificationsEnabled)
            }

            Section("Appearance") {
                Picker("Theme", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("General") {
                Toggle("Start at Login", isOn: $settings.startAtLogin)
                    .onChange(of: settings.startAtLogin) { _, newValue in
                        setLoginItem(enabled: newValue)
                    }
                Toggle("Keep Window on Top", isOn: $settings.keepWindowOnTop)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            print("Login item registration failed: \(error)")
        }
    }
}
