import Foundation
import Combine

@MainActor
final class TimerManager: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentPomodoro: Int = 1
    @Published var isRunning: Bool = false

    private var timer: AnyCancellable?
    private let presetStore: PresetStore

    /// Callback fired on each phase transition (for notifications)
    var onPhaseTransition: ((TimerPhase, TimerPhase) -> Void)?

    var activePreset: Preset {
        presetStore.activePreset
    }

    var totalDuration: TimeInterval {
        activePreset.duration(for: phase)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var cycleProgress: Double {
        guard activePreset.cycleCount > 0 else { return 0 }
        let completed = Double(currentPomodoro - 1)
        return completed / Double(activePreset.cycleCount)
    }

    init(presetStore: PresetStore) {
        self.presetStore = presetStore
    }

    func start() {
        phase = .focus
        currentPomodoro = 1
        timeRemaining = activePreset.duration(for: .focus)
        isRunning = true
        startTimer()
    }

    func pause() {
        isRunning = false
        stopTimer()
    }

    func resume() {
        isRunning = true
        startTimer()
    }

    func skip() {
        let oldPhase = phase
        let nextPhase = TimerPhase.nextPhase(
            after: phase,
            currentPomodoro: currentPomodoro,
            totalPomodoros: activePreset.cycleCount
        )

        if oldPhase == .shortBreak {
            currentPomodoro += 1
        }

        phase = nextPhase

        if nextPhase == .idle {
            timeRemaining = 0
            isRunning = false
            stopTimer()
        } else {
            timeRemaining = activePreset.duration(for: nextPhase)
            isRunning = true
            startTimer()
        }

        onPhaseTransition?(oldPhase, nextPhase)
    }

    func resetCycle() {
        stopTimer()
        phase = .idle
        timeRemaining = 0
        currentPomodoro = 1
        isRunning = false
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining <= 0 {
            skip()
        }
    }
}
