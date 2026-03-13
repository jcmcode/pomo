import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var presetStore: PresetStore
    let onOpenWindow: () -> Void

    @State private var showingSwitchConfirmation = false
    @State private var pendingSwitchPreset: Preset?

    private var timeString: String {
        let minutes = Int(timerManager.timeRemaining) / 60
        let seconds = Int(timerManager.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 14) {
                DoubleRingView(
                    timerProgress: timerManager.progress,
                    cycleProgress: timerManager.cycleProgress,
                    completedPomodoros: timerManager.currentPomodoro - 1,
                    totalPomodoros: timerManager.activePreset.cycleCount,
                    isBreak: timerManager.phase.isBreak,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 22, weight: .light))
                        .monospacedDigit()
                    Text(timerManager.phase == .idle
                         ? "Ready"
                         : "\(timerManager.phase.displayName) \u{00B7} \(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            TimerControlsView(timerManager: timerManager, compact: true)

            Divider()

            VStack(alignment: .leading, spacing: 6) {
                Text("QUICK SWITCH")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    ForEach(Preset.builtInPresets) { preset in
                        Button(action: { handlePresetSwitch(preset) }) {
                            Text(preset.name)
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(preset.id == presetStore.activePreset.id ? Color(hex: "ff6b6b") : nil)
                    }
                }
            }

            Divider()

            Button(action: onOpenWindow) {
                HStack {
                    Spacer()
                    Text("Open Window")
                        .font(.caption)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 260)
        .alert("Switch Preset?", isPresented: $showingSwitchConfirmation) {
            Button("Cancel", role: .cancel) { pendingSwitchPreset = nil }
            Button("Switch", role: .destructive) {
                if let preset = pendingSwitchPreset {
                    presetStore.setActivePreset(preset)
                    timerManager.resetCycle()
                }
                pendingSwitchPreset = nil
            }
        } message: {
            Text("This will reset your current session. Continue?")
        }
    }

    private func handlePresetSwitch(_ preset: Preset) {
        guard preset.id != presetStore.activePreset.id else { return }
        if timerManager.phase != .idle {
            pendingSwitchPreset = preset
            showingSwitchConfirmation = true
        } else {
            presetStore.setActivePreset(preset)
        }
    }
}
