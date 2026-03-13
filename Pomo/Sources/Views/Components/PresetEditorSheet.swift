import SwiftUI

struct PresetEditorSheet: View {
    let existingPreset: Preset?
    let onSave: (Preset) -> Void
    let onCancel: () -> Void

    // Simple mode
    @State private var name: String
    @State private var focusMinutes: Double
    @State private var breakMinutes: Double
    @State private var sessionCount: Int

    // Advanced mode
    @State private var isAdvanced: Bool
    @State private var blocks: [TimerBlock]

    init(preset: Preset?, onSave: @escaping (Preset) -> Void, onCancel: @escaping () -> Void) {
        self.existingPreset = preset
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: preset?.name ?? "")
        _focusMinutes = State(initialValue: (preset?.focusDuration ?? 25 * 60) / 60)
        _breakMinutes = State(initialValue: (preset?.breakDuration ?? 5 * 60) / 60)
        _sessionCount = State(initialValue: preset?.sessionCount ?? 4)
        _isAdvanced = State(initialValue: preset?.isAdvanced ?? false)
        _blocks = State(initialValue: preset?.advancedBlocks ?? [
            TimerBlock(phase: .focus, duration: 25 * 60),
            TimerBlock(phase: .shortBreak, duration: 5 * 60),
            TimerBlock(phase: .focus, duration: 25 * 60),
        ])
    }

    private var isValid: Bool {
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return false }
        if isAdvanced {
            return !blocks.isEmpty && blocks.allSatisfy { $0.duration >= 0 }
                && blocks.contains(where: { $0.phase == .focus && $0.duration > 0 })
        }
        return focusMinutes >= 1 && focusMinutes <= 1440
            && breakMinutes >= 0 && breakMinutes <= 1440
            && sessionCount >= 1 && sessionCount <= 99
    }

    var body: some View {
        VStack(spacing: 12) {
            Text(existingPreset == nil ? "New Preset" : "Edit Preset")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                Toggle("Advanced", isOn: $isAdvanced.animation())
            }

            if isAdvanced {
                advancedEditor
            } else {
                simpleEditor
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(.horizontal)
            .padding(.bottom, 8)
        }
        .padding(.top)
        .frame(width: 380, height: isAdvanced ? 460 : 300)
    }

    // MARK: - Simple Editor

    private var simpleEditor: some View {
        Form {
            HStack {
                Text("Focus (min)")
                Spacer()
                TextField("", value: $focusMinutes, format: .number)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }

            HStack {
                Text("Break (min)")
                Spacer()
                TextField("", value: $breakMinutes, format: .number)
                    .frame(width: 60)
                    .multilineTextAlignment(.trailing)
            }

            Stepper("Sessions: \(sessionCount)", value: $sessionCount, in: 1...99)
        }
    }

    // MARK: - Advanced Editor

    private var advancedEditor: some View {
        VStack(spacing: 8) {
            List {
                ForEach($blocks) { $block in
                    HStack(spacing: 8) {
                        Picker("", selection: $block.phase) {
                            Text("Focus").tag(TimerPhase.focus)
                            Text("Break").tag(TimerPhase.shortBreak)
                        }
                        .labelsHidden()
                        .frame(width: 80)

                        TextField("min", value: Binding(
                            get: { block.duration / 60 },
                            set: { block.duration = $0 * 60 }
                        ), format: .number)
                        .frame(width: 50)
                        .multilineTextAlignment(.trailing)

                        Text("min")
                            .foregroundStyle(.secondary)
                            .font(.caption)

                        Spacer()

                        Button(action: { blocks.removeAll { $0.id == block.id } }) {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .onMove { from, to in
                    blocks.move(fromOffsets: from, toOffset: to)
                }
            }
            .frame(minHeight: 150)

            HStack(spacing: 12) {
                Button(action: {
                    blocks.append(TimerBlock(phase: .focus, duration: 25 * 60))
                }) {
                    Label("Focus", systemImage: "plus.circle.fill")
                        .font(.caption)
                }

                Button(action: {
                    blocks.append(TimerBlock(phase: .shortBreak, duration: 5 * 60))
                }) {
                    Label("Break", systemImage: "plus.circle.fill")
                        .font(.caption)
                }
            }
            .padding(.horizontal)
        }
    }

    // MARK: - Save

    private func save() {
        let preset = Preset(
            id: existingPreset?.id ?? UUID(),
            name: name.trimmingCharacters(in: .whitespaces),
            focusDuration: focusMinutes * 60,
            breakDuration: breakMinutes * 60,
            sessionCount: sessionCount,
            isBuiltIn: false,
            advancedBlocks: isAdvanced ? blocks : nil
        )
        onSave(preset)
    }
}
