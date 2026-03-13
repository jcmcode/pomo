import Testing
@testable import Pomo

@Test @MainActor func initialPresetsContainsBuiltIns() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore1")
    let store = PresetStore(defaults: defaults)
    #expect(store.allPresets.count == 3)
    #expect(store.allPresets.contains(where: { $0.name == "Classic" }))
    #expect(store.allPresets.contains(where: { $0.name == "Deep Work" }))
    #expect(store.allPresets.contains(where: { $0.name == "Short Sprint" }))
}

@Test @MainActor func addCustomPreset() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore2")
    let store = PresetStore(defaults: defaults)
    let custom = Preset(
        name: "Custom",
        focusDuration: 45 * 60,
        shortBreakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        cycleCount: 3,
        isBuiltIn: false
    )
    store.addPreset(custom)
    #expect(store.allPresets.count == 4)
    #expect(store.allPresets.contains(where: { $0.name == "Custom" }))
}

@Test @MainActor func deleteCustomPreset() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore3")
    let store = PresetStore(defaults: defaults)
    let custom = Preset(
        name: "ToDelete",
        focusDuration: 600,
        shortBreakDuration: 300,
        longBreakDuration: 900,
        cycleCount: 2,
        isBuiltIn: false
    )
    store.addPreset(custom)
    #expect(store.allPresets.count == 4)
    store.deletePreset(custom)
    #expect(store.allPresets.count == 3)
}

@Test @MainActor func cannotDeleteBuiltInPreset() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore4")
    let store = PresetStore(defaults: defaults)
    store.deletePreset(Preset.classic)
    #expect(store.allPresets.count == 3)
    #expect(store.allPresets.contains(where: { $0.name == "Classic" }))
}

@Test @MainActor func updateCustomPreset() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore5")
    let store = PresetStore(defaults: defaults)
    var custom = Preset(
        name: "Original",
        focusDuration: 600,
        shortBreakDuration: 300,
        longBreakDuration: 900,
        cycleCount: 2,
        isBuiltIn: false
    )
    store.addPreset(custom)
    custom.name = "Updated"
    store.updatePreset(custom)
    #expect(store.allPresets.contains(where: { $0.name == "Updated" }))
    #expect(!store.allPresets.contains(where: { $0.name == "Original" }))
}

@Test @MainActor func persistenceRoundTrip() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore6")

    let store1 = PresetStore(defaults: defaults)
    let custom = Preset(
        name: "Persisted",
        focusDuration: 600,
        shortBreakDuration: 300,
        longBreakDuration: 900,
        cycleCount: 2,
        isBuiltIn: false
    )
    store1.addPreset(custom)

    let store2 = PresetStore(defaults: defaults)
    #expect(store2.allPresets.count == 4)
    #expect(store2.allPresets.contains(where: { $0.name == "Persisted" }))
}

@Test @MainActor func activePresetDefaultsToClassic() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore7")
    let store = PresetStore(defaults: defaults)
    #expect(store.activePreset.id == Preset.classic.id)
}

@Test @MainActor func setActivePreset() {
    let defaults = makeCleanDefaults(suiteName: "com.pomo.tests.presetstore8")
    let store = PresetStore(defaults: defaults)
    store.setActivePreset(Preset.deepWork)
    #expect(store.activePreset.id == Preset.deepWork.id)
}
