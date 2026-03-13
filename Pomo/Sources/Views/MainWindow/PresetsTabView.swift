import SwiftUI

struct PresetsTabView: View {
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var timerManager: TimerManager
    @State private var showingAddSheet = false
    @State private var editingPreset: Preset?
    @State private var showingSwitchConfirmation = false
    @State private var pendingSwitchPreset: Preset?

    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            List {
                ForEach(presetStore.allPresets) { preset in
                    PresetRow(
                        preset: preset,
                        isActive: preset.id == presetStore.activePreset.id,
                        onSelect: { handlePresetSwitch(preset) },
                        onEdit: preset.isBuiltIn ? nil : { editingPreset = preset },
                        onDelete: preset.isBuiltIn ? nil : { presetStore.deletePreset(preset) }
                    )
                }
                .onDelete { indexSet in
                    let builtInCount = Preset.builtInPresets.count
                    for index in indexSet where index >= builtInCount {
                        let preset = presetStore.allPresets[index]
                        presetStore.deletePreset(preset)
                    }
                }
            }

            Button(action: { showingAddSheet = true }) {
                Label("New Preset", systemImage: "plus")
            }
            .padding(.horizontal)
            .padding(.bottom)
        }
        .sheet(isPresented: $showingAddSheet) {
            PresetEditorSheet(
                preset: nil,
                onSave: { preset in
                    presetStore.addPreset(preset)
                    showingAddSheet = false
                },
                onCancel: { showingAddSheet = false }
            )
        }
        .sheet(item: $editingPreset) { preset in
            PresetEditorSheet(
                preset: preset,
                onSave: { updated in
                    presetStore.updatePreset(updated)
                    editingPreset = nil
                },
                onCancel: { editingPreset = nil }
            )
        }
        .alert("Switch Preset?", isPresented: $showingSwitchConfirmation) {
            Button("Cancel", role: .cancel) { pendingSwitchPreset = nil }
            Button("Switch", role: .destructive) {
                if let preset = pendingSwitchPreset {
                    presetStore.setActivePreset(preset)
                    timerManager.resetCycle()
                }
                pendingSwitchPreset = nil
            }
        } message: {
            Text("This will reset your current session. Continue?")
        }
    }

    private func handlePresetSwitch(_ preset: Preset) {
        if timerManager.phase != .idle {
            pendingSwitchPreset = preset
            showingSwitchConfirmation = true
        } else {
            presetStore.setActivePreset(preset)
        }
    }
}

struct PresetRow: View {
    let preset: Preset
    let isActive: Bool
    let onSelect: () -> Void
    let onEdit: (() -> Void)?
    let onDelete: (() -> Void)?

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(preset.name)
                        .fontWeight(isActive ? .semibold : .regular)
                    if isActive {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(Color(hex: "ff6b6b"))
                            .font(.caption)
                    }
                }
                Text("\(Int(preset.focusDuration / 60))m focus / \(Int(preset.shortBreakDuration / 60))m break / \(preset.cycleCount) cycles")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            Spacer()
        }
        .contentShape(Rectangle())
        .onTapGesture { onSelect() }
        .contextMenu {
            if let onEdit {
                Button("Edit") { onEdit() }
            }
            if let onDelete {
                Button("Delete", role: .destructive) { onDelete() }
            }
        }
    }
}
