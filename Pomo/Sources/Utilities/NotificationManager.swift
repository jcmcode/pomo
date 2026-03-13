import Foundation
import UserNotifications
import AppKit

@MainActor
final class NotificationManager {
    private let settings: AppSettings
    var onVisualNotification: (() -> Void)?

    private var hasRequestedPermission = false

    init(settings: AppSettings) {
        self.settings = settings
    }

    func handlePhaseTransition(from oldPhase: TimerPhase, to newPhase: TimerPhase) {
        if settings.systemNotificationsEnabled {
            if !hasRequestedPermission {
                hasRequestedPermission = true
                requestNotificationPermission()
            }
            sendSystemNotification(from: oldPhase, to: newPhase)
        }
        if settings.soundEnabled {
            playSound()
        }
        if settings.visualNotificationsEnabled {
            onVisualNotification?()
        }
    }

    private var notificationCenter: UNUserNotificationCenter? {
        // UNUserNotificationCenter crashes without a proper app bundle (e.g. SPM debug builds)
        guard Bundle.main.bundleIdentifier != nil else { return nil }
        return UNUserNotificationCenter.current()
    }

    private func requestNotificationPermission() {
        notificationCenter?.requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private nonisolated func sendSystemNotification(from oldPhase: TimerPhase, to newPhase: TimerPhase) {
        guard Bundle.main.bundleIdentifier != nil else { return }

        let content = UNMutableNotificationContent()

        switch newPhase {
        case .shortBreak, .longBreak:
            content.title = "Focus Complete!"
            content.body = "Time for a \(newPhase == .longBreak ? "long " : "")break."
        case .focus:
            content.title = "Break Over!"
            content.body = "Time to focus."
        case .idle:
            content.title = "Cycle Complete!"
            content.body = "Great work! All pomodoros finished."
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        if let soundURL = Bundle.main.url(forResource: "chime", withExtension: "aiff") {
            NSSound(contentsOf: soundURL, byReference: true)?.play()
        } else {
            NSSound.beep()
        }
    }
}
