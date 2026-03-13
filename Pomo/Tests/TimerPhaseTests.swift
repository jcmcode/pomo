import Testing
@testable import Pomo

@Test func phaseDisplayName() {
    #expect(TimerPhase.focus.displayName == "Focus")
    #expect(TimerPhase.shortBreak.displayName == "Short Break")
    #expect(TimerPhase.longBreak.displayName == "Long Break")
    #expect(TimerPhase.idle.displayName == "Idle")
}

@Test func phaseIsBreak() {
    #expect(!TimerPhase.focus.isBreak)
    #expect(TimerPhase.shortBreak.isBreak)
    #expect(TimerPhase.longBreak.isBreak)
    #expect(!TimerPhase.idle.isBreak)
}

@Test func nextPhaseFromFocusNotLastCycle() {
    let next = TimerPhase.nextPhase(after: .focus, currentPomodoro: 1, totalPomodoros: 4)
    #expect(next == .shortBreak)
}

@Test func nextPhaseFromFocusLastCycle() {
    let next = TimerPhase.nextPhase(after: .focus, currentPomodoro: 4, totalPomodoros: 4)
    #expect(next == .longBreak)
}

@Test func nextPhaseFromShortBreak() {
    let next = TimerPhase.nextPhase(after: .shortBreak, currentPomodoro: 1, totalPomodoros: 4)
    #expect(next == .focus)
}

@Test func nextPhaseFromLongBreak() {
    let next = TimerPhase.nextPhase(after: .longBreak, currentPomodoro: 4, totalPomodoros: 4)
    #expect(next == .idle)
}

@Test func nextPhaseFromIdle() {
    let next = TimerPhase.nextPhase(after: .idle, currentPomodoro: 1, totalPomodoros: 4)
    #expect(next == .focus)
}
