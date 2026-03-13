import SwiftUI

struct TimerTabView: View {
    @ObservedObject var timerManager: TimerManager

    private var timeString: String {
        let minutes = Int(timerManager.timeRemaining) / 60
        let seconds = Int(timerManager.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var phaseLabel: String {
        if timerManager.phase == .idle {
            return "Ready"
        }
        return "\(timerManager.phase.displayName) \u{00B7} \(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)"
    }

    private var nextPhaseLabel: String? {
        guard timerManager.phase != .idle else { return nil }
        let next = TimerPhase.nextPhase(
            after: timerManager.phase,
            currentPomodoro: timerManager.currentPomodoro,
            totalPomodoros: timerManager.activePreset.cycleCount
        )
        if next == .idle { return "Cycle Complete" }
        return "Next: \(next.displayName)"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(timerManager.activePreset.name)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                DoubleRingView(
                    timerProgress: timerManager.progress,
                    cycleProgress: timerManager.cycleProgress,
                    completedPomodoros: timerManager.currentPomodoro - 1,
                    totalPomodoros: timerManager.activePreset.cycleCount,
                    isBreak: timerManager.phase.isBreak,
                    size: 200
                )

                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 40, weight: .ultraLight, design: .default))
                        .monospacedDigit()

                    if timerManager.phase != .idle {
                        Text("\(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(phaseLabel)
                .font(.headline)

            TimerControlsView(timerManager: timerManager, compact: false)
                .frame(maxWidth: 200)

            if let nextLabel = nextPhaseLabel {
                Text(nextLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
