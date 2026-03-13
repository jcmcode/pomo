import SwiftUI
import AppKit

@main
struct PomoApp: App {
    @StateObject private var presetStore: PresetStore
    @StateObject private var settings = AppSettings()
    @StateObject private var timerManager: TimerManager
    @State private var notificationManager: NotificationManager?

    init() {
        let store = PresetStore()
        _presetStore = StateObject(wrappedValue: store)
        _timerManager = StateObject(wrappedValue: TimerManager(presetStore: store))
        // Show dock icon when running as a bare executable (no .app bundle)
        NSApplication.shared.setActivationPolicy(.regular)
    }

    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager, presetStore: presetStore, settings: settings)
                .onAppear {
                    setupNotifications()
                    applyWindowOnTop()
                }
                .onChange(of: settings.keepWindowOnTop) { _, _ in
                    applyWindowOnTop()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 380, height: 480)

        MenuBarExtra {
            MenuBarPopover(
                timerManager: timerManager,
                presetStore: presetStore,
                onOpenWindow: { openMainWindow() }
            )
        } label: {
            MenuBarLabel(timerManager: timerManager)
        }
        .menuBarExtraStyle(.window)
    }

    private func setupNotifications() {
        guard notificationManager == nil else { return }
        let nm = NotificationManager(settings: settings)
        timerManager.onPhaseTransition = { oldPhase, newPhase in
            nm.handlePhaseTransition(from: oldPhase, to: newPhase)
        }
        self.notificationManager = nm
    }

    private func applyWindowOnTop() {
        DispatchQueue.main.async {
            NSApplication.shared.windows.first { $0.title != "" }?.level = settings.keepWindowOnTop ? .floating : .normal
        }
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.title != "" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

struct MenuBarLabel: View {
    @ObservedObject var timerManager: TimerManager

    private var accentColor: Color {
        timerManager.phase.isBreak ? Color(hex: "4ecdc4") : Color(hex: "ff6b6b")
    }

    var body: some View {
        HStack(spacing: 4) {
            if timerManager.phase != .idle {
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                    Text("\u{1F353}")
                        .font(.system(size: 8))
                }
                Text(timeString(timerManager.timeRemaining))
                    .monospacedDigit()
                    .font(.caption)
            } else {
                Text("\u{1F353}")
            }
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}
