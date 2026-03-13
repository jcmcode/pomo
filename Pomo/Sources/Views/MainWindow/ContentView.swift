import SwiftUI

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            TimerTabView(timerManager: timerManager)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            PresetsTabView(presetStore: presetStore, timerManager: timerManager)
                .tabItem {
                    Label("Presets", systemImage: "list.bullet")
                }

            SettingsTabView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .frame(minWidth: 350, minHeight: 420)
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
