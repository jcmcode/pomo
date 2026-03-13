import SwiftUI
import AppKit

@main
struct PomoApp: App {
    @StateObject private var presetStore: PresetStore
    @StateObject private var settings = AppSettings()
    @StateObject private var timerManager: TimerManager
    @State private var notificationManager: NotificationManager?
    @Environment(\.openWindow) private var openWindow

    init() {
        let store = PresetStore()
        _presetStore = StateObject(wrappedValue: store)
        _timerManager = StateObject(wrappedValue: TimerManager(presetStore: store))
        // Show dock icon when running as a bare executable (no .app bundle)
        NSApplication.shared.setActivationPolicy(.regular)
        // Set strawberry as dock icon
        Self.setAppIcon()
    }

    private static func setAppIcon() {
        let size = NSSize(width: 256, height: 256)
        let image = NSImage(size: size, flipped: false) { rect in
            // Dark rounded rect background (matches .icns style)
            let bgPath = NSBezierPath(roundedRect: rect.insetBy(dx: 8, dy: 8), xRadius: 48, yRadius: 48)
            NSColor(red: 0.08, green: 0.08, blue: 0.16, alpha: 1.0).setFill()
            bgPath.fill()

            // Subtle border
            NSColor(red: 0.2, green: 0.2, blue: 0.35, alpha: 0.6).setStroke()
            bgPath.lineWidth = 2
            bgPath.stroke()

            // Strawberry emoji centered
            let str = "\u{1F353}" as NSString
            let font = NSFont.systemFont(ofSize: 140)
            let attrs: [NSAttributedString.Key: Any] = [.font: font]
            let strSize = str.size(withAttributes: attrs)
            let point = NSPoint(
                x: (rect.width - strSize.width) / 2,
                y: (rect.height - strSize.height) / 2
            )
            str.draw(at: point, withAttributes: attrs)
            return true
        }
        NSApplication.shared.applicationIconImage = image
    }

    var body: some Scene {
        Window("Pomo", id: "main") {
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
        openWindow(id: "main")
        NSApplication.shared.activate(ignoringOtherApps: true)
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
