import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var timerManager: TimerManager
    let compact: Bool

    var body: some View {
        if timerManager.phase == .idle {
            Button(action: { timerManager.start() }) {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: compact ? nil : .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "ff6b6b"))
        } else {
            HStack(spacing: compact ? 8 : 12) {
                if timerManager.isRunning {
                    Button(action: { timerManager.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: compact ? nil : .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "ff6b6b"))
                } else {
                    Button(action: { timerManager.resume() }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: compact ? nil : .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "ff6b6b"))
                }

                Button(action: { timerManager.skip() }) {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: compact ? nil : .infinity)
                }
                .buttonStyle(.bordered)

                Button(action: { timerManager.resetCycle() }) {
                    Label("Stop", systemImage: "stop.fill")
                        .frame(maxWidth: compact ? nil : .infinity)
                }
                .buttonStyle(.bordered)
                .tint(.secondary)
            }
        }
    }
}
