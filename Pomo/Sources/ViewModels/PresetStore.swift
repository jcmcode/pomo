import Foundation

@MainActor
final class PresetStore: ObservableObject {
    @Published private(set) var customPresets: [Preset] = []
    @Published private(set) var activePreset: Preset = .classic

    private let defaults: UserDefaults
    private let customPresetsKey = "customPresets"
    private let activePresetIdKey = "activePresetId"

    var allPresets: [Preset] {
        Preset.builtInPresets + customPresets
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.customPresets = Self.loadCustomPresets(from: defaults)
        self.activePreset = Self.loadActivePreset(from: defaults, customPresets: self.customPresets)
    }

    func addPreset(_ preset: Preset) {
        customPresets.append(preset)
        saveCustomPresets()
    }

    func deletePreset(_ preset: Preset) {
        guard !preset.isBuiltIn else { return }
        customPresets.removeAll { $0.id == preset.id }
        if activePreset.id == preset.id {
            activePreset = .classic
            saveActivePresetId()
        }
        saveCustomPresets()
    }

    func updatePreset(_ preset: Preset) {
        guard let index = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        customPresets[index] = preset
        if activePreset.id == preset.id {
            activePreset = preset
        }
        saveCustomPresets()
    }

    func setActivePreset(_ preset: Preset) {
        activePreset = preset
        saveActivePresetId()
    }

    private func saveCustomPresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            defaults.set(data, forKey: customPresetsKey)
        }
    }

    private func saveActivePresetId() {
        defaults.set(activePreset.id.uuidString, forKey: activePresetIdKey)
    }

    private static func loadCustomPresets(from defaults: UserDefaults) -> [Preset] {
        guard let data = defaults.data(forKey: "customPresets"),
              let presets = try? JSONDecoder().decode([Preset].self, from: data) else {
            return []
        }
        return presets
    }

    private static func loadActivePreset(from defaults: UserDefaults, customPresets: [Preset]) -> Preset {
        guard let idString = defaults.string(forKey: "activePresetId"),
              let id = UUID(uuidString: idString) else {
            return .classic
        }
        let all = Preset.builtInPresets + customPresets
        return all.first(where: { $0.id == id }) ?? .classic
    }
}
