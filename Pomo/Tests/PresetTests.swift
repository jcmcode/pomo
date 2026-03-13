import Testing
@testable import Pomo

@Test func builtInPresets() {
    let classic = Preset.classic
    #expect(classic.name == "Classic")
    #expect(classic.focusDuration == 25 * 60)
    #expect(classic.breakDuration == 5 * 60)
    #expect(classic.sessionCount == 4)
    #expect(classic.isBuiltIn)

    let deepWork = Preset.deepWork
    #expect(deepWork.focusDuration == 50 * 60)
    #expect(deepWork.sessionCount == 3)

    let sprint = Preset.shortSprint
    #expect(sprint.focusDuration == 15 * 60)
}

@Test func customPreset() {
    let custom = Preset(
        name: "My Custom",
        focusDuration: 45 * 60,
        breakDuration: 10 * 60,
        sessionCount: 3,
        isBuiltIn: false
    )
    #expect(custom.name == "My Custom")
    #expect(!custom.isBuiltIn)
}

@Test func presetCodable() throws {
    let preset = Preset(
        name: "Test",
        focusDuration: 600,
        breakDuration: 300,
        sessionCount: 2,
        isBuiltIn: false
    )
    let data = try Pomo.encode(preset)
    let decoded = try Pomo.decode(Preset.self, from: data)
    #expect(decoded.name == preset.name)
    #expect(decoded.focusDuration == preset.focusDuration)
    #expect(decoded.id == preset.id)
}

@Test func simpleSequenceGeneration() {
    let preset = Preset.classic
    let seq = preset.sequence
    // 4 sessions: F B F B F B F = 7 blocks
    #expect(seq.count == 7)
    #expect(seq[0].phase == .focus)
    #expect(seq[1].phase == .shortBreak)
    #expect(seq[6].phase == .focus) // last is focus, no trailing break
    #expect(preset.totalFocusSessions == 4)
}

@Test func noBreakPreset() {
    let preset = Preset(
        name: "No Break",
        focusDuration: 25 * 60,
        breakDuration: 0,
        sessionCount: 3,
        isBuiltIn: false
    )
    let seq = preset.sequence
    // 3 focus blocks, no breaks
    #expect(seq.count == 3)
    #expect(seq.allSatisfy { $0.phase == .focus })
}

@Test func advancedPreset() {
    let blocks = [
        TimerBlock(phase: .focus, duration: 25 * 60),
        TimerBlock(phase: .shortBreak, duration: 5 * 60),
        TimerBlock(phase: .focus, duration: 50 * 60),
        TimerBlock(phase: .shortBreak, duration: 15 * 60),
        TimerBlock(phase: .focus, duration: 25 * 60),
    ]
    let preset = Preset(
        name: "Custom Flow",
        focusDuration: 0,
        breakDuration: 0,
        sessionCount: 0,
        isBuiltIn: false,
        advancedBlocks: blocks
    )
    #expect(preset.isAdvanced)
    #expect(preset.sequence.count == 5)
    #expect(preset.totalFocusSessions == 3)
}
