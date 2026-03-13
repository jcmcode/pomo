import Foundation
import Combine

@MainActor
final class TimerManager: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var isRunning: Bool = false

    /// Index into the current preset's sequence
    @Published var currentBlockIndex: Int = 0

    private var timer: AnyCancellable?
    private let presetStore: PresetStore

    /// Callback fired on each phase transition (for notifications)
    var onPhaseTransition: ((TimerPhase, TimerPhase) -> Void)?

    var activePreset: Preset {
        presetStore.activePreset
    }

    private var sequence: [TimerBlock] {
        activePreset.sequence
    }

    var currentBlock: TimerBlock? {
        guard currentBlockIndex < sequence.count else { return nil }
        return sequence[currentBlockIndex]
    }

    var totalDuration: TimeInterval {
        currentBlock?.duration ?? 0
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    /// How many focus sessions completed so far
    var completedFocusSessions: Int {
        let pastBlocks = sequence.prefix(currentBlockIndex)
        return pastBlocks.filter { $0.phase == .focus }.count
    }

    var totalFocusSessions: Int {
        activePreset.totalFocusSessions
    }

    /// Current focus session number (1-based)
    var currentPomodoro: Int {
        completedFocusSessions + (phase == .focus ? 1 : 0)
    }

    var cycleProgress: Double {
        guard totalFocusSessions > 0 else { return 0 }
        return Double(completedFocusSessions) / Double(totalFocusSessions)
    }

    init(presetStore: PresetStore) {
        self.presetStore = presetStore
    }

    func start() {
        currentBlockIndex = 0
        advanceToBlock(0)
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
        advanceToBlock(currentBlockIndex + 1)
    }

    func resetCycle() {
        stopTimer()
        phase = .idle
        timeRemaining = 0
        currentBlockIndex = 0
        isRunning = false
    }

    // MARK: - Block Navigation

    private func advanceToBlock(_ index: Int) {
        let oldPhase = phase

        if index >= sequence.count {
            // Sequence complete
            phase = .idle
            timeRemaining = 0
            isRunning = false
            currentBlockIndex = index
            stopTimer()
            onPhaseTransition?(oldPhase, .idle)
            return
        }

        let block = sequence[index]
        currentBlockIndex = index
        phase = block.phase

        if block.duration <= 0 {
            // Skip zero-duration blocks
            onPhaseTransition?(oldPhase, block.phase)
            advanceToBlock(index + 1)
            return
        }

        timeRemaining = block.duration
        isRunning = true
        startTimer()
        onPhaseTransition?(oldPhase, block.phase)
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
