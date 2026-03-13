import Testing
@testable import Pomo

@Test @MainActor func initialState() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests1"))
    let manager = TimerManager(presetStore: store)
    #expect(manager.phase == .idle)
    #expect(manager.timeRemaining == 0)
    #expect(manager.currentPomodoro == 0)
    #expect(!manager.isRunning)
}

@Test @MainActor func startBeginsFirstFocusSession() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests2"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    #expect(manager.phase == .focus)
    #expect(manager.timeRemaining == 25 * 60)
    #expect(manager.isRunning)
    #expect(manager.currentPomodoro == 1)
}

@Test @MainActor func pauseAndResume() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests3"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    manager.pause()
    #expect(!manager.isRunning)
    #expect(manager.phase == .focus)
    manager.resume()
    #expect(manager.isRunning)
}

@Test @MainActor func skipMovesToNextPhase() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests4"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    #expect(manager.phase == .focus)
    manager.skip() // focus → break
    #expect(manager.phase == .shortBreak)
    #expect(manager.timeRemaining == 5 * 60)
    #expect(manager.isRunning)
}

@Test @MainActor func skipThroughFullCycleEndsAtIdle() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests5"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    // Classic: F B F B F B F = 7 blocks
    for _ in 0..<7 {
        manager.skip()
    }
    #expect(manager.phase == .idle)
    #expect(!manager.isRunning)
}

@Test @MainActor func lastFocusGoesDirectlyToIdle() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests6"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    // Skip to last focus (block index 6)
    for _ in 0..<6 {
        manager.skip()
    }
    #expect(manager.phase == .focus)
    #expect(manager.currentPomodoro == 4)
    manager.skip() // last focus → idle (no long break!)
    #expect(manager.phase == .idle)
}

@Test @MainActor func resetCycle() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests7"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    manager.skip()
    manager.skip()
    manager.resetCycle()
    #expect(manager.phase == .idle)
    #expect(!manager.isRunning)
}

@Test @MainActor func progressCalculation() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests8"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    let initial = manager.progress
    #expect(initial >= 0.0 && initial <= 0.01)
    manager.timeRemaining = 12.5 * 60 // Half of 25 minutes
    let mid = manager.progress
    #expect(mid >= 0.49 && mid <= 0.51)
}

@Test @MainActor func cycleProgress() {
    let store = PresetStore(defaults: makeCleanDefaults(suiteName: "com.pomo.timer.tests9"))
    let manager = TimerManager(presetStore: store)
    manager.start()
    let initial = manager.cycleProgress
    #expect(initial >= 0.0 && initial <= 0.01)
    manager.skip() // → break
    manager.skip() // → focus (pomo 2)
    let afterOne = manager.cycleProgress
    #expect(afterOne >= 0.24 && afterOne <= 0.26)
}
