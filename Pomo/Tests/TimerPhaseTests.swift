import Testing
@testable import Pomo

@Test func phaseDisplayName() {
    #expect(TimerPhase.focus.displayName == "Focus")
    #expect(TimerPhase.shortBreak.displayName == "Break")
    #expect(TimerPhase.idle.displayName == "Idle")
}

@Test func phaseIsBreak() {
    #expect(!TimerPhase.focus.isBreak)
    #expect(TimerPhase.shortBreak.isBreak)
    #expect(!TimerPhase.idle.isBreak)
}
