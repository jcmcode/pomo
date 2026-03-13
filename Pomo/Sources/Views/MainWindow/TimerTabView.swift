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
        return "\(timerManager.phase.displayName) \u{00B7} \(timerManager.currentPomodoro) of \(timerManager.totalFocusSessions)"
    }

    private var nextPhaseLabel: String? {
        guard timerManager.phase != .idle else { return nil }
        let seq = timerManager.activePreset.sequence
        let nextIndex = timerManager.currentBlockIndex + 1
        if nextIndex >= seq.count { return "Last Block" }
        return "Next: \(seq[nextIndex].phase.displayName) (\(seq[nextIndex].displayDuration))"
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
                    completedPomodoros: timerManager.completedFocusSessions,
                    totalPomodoros: timerManager.totalFocusSessions,
                    isBreak: timerManager.phase.isBreak,
                    size: 200
                )

                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 40, weight: .ultraLight, design: .default))
                        .monospacedDigit()

                    if timerManager.phase != .idle {
                        Text("\(timerManager.currentPomodoro) of \(timerManager.totalFocusSessions)")
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
