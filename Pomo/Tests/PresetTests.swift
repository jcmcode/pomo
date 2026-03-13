import Testing
@testable import Pomo

@Test func builtInPresets() {
    let classic = Preset.classic
    #expect(classic.name == "Classic")
    #expect(classic.focusDuration == 25 * 60)
    #expect(classic.shortBreakDuration == 5 * 60)
    #expect(classic.longBreakDuration == 15 * 60)
    #expect(classic.cycleCount == 4)
    #expect(classic.isBuiltIn)

    let deepWork = Preset.deepWork
    #expect(deepWork.focusDuration == 50 * 60)
    #expect(deepWork.cycleCount == 3)

    let sprint = Preset.shortSprint
    #expect(sprint.focusDuration == 15 * 60)
}

@Test func customPreset() {
    let custom = Preset(
        name: "My Custom",
        focusDuration: 45 * 60,
        shortBreakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        cycleCount: 3,
        isBuiltIn: false
    )
    #expect(custom.name == "My Custom")
    #expect(!custom.isBuiltIn)
}

@Test func presetCodable() throws {
    let preset = Preset(
        name: "Test",
        focusDuration: 600,
        shortBreakDuration: 300,
        longBreakDuration: 900,
        cycleCount: 2,
        isBuiltIn: false
    )
    let data = try Pomo.encode(preset)
    let decoded = try Pomo.decode(Preset.self, from: data)
    #expect(decoded.name == preset.name)
    #expect(decoded.focusDuration == preset.focusDuration)
    #expect(decoded.id == preset.id)
}

@Test func durationForPhase() {
    let preset = Preset.classic
    #expect(preset.duration(for: .focus) == 25 * 60)
    #expect(preset.duration(for: .shortBreak) == 5 * 60)
    #expect(preset.duration(for: .longBreak) == 15 * 60)
    #expect(preset.duration(for: .idle) == 0)
}
