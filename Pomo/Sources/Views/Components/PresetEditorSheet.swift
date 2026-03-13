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
        VStack(spacing: 0) {
            // Header
            Text(existingPreset == nil ? "New Preset" : "Edit Preset")
                .font(.headline)
                .padding(.top, 20)
                .padding(.bottom, 16)

            // Content
            VStack(spacing: 12) {
                // Name field
                HStack {
                    Text("Name")
                        .frame(width: 70, alignment: .leading)
                    TextField("Preset name", text: $name)
                        .textFieldStyle(.roundedBorder)
                }

                Divider()

                if isAdvanced {
                    advancedEditor
                } else {
                    simpleEditor
                }
            }
            .padding(.horizontal, 20)

            Spacer(minLength: 12)

            // Footer
            HStack {
                Button(action: {
                    withAnimation { isAdvanced.toggle() }
                }) {
                    Text(isAdvanced ? "Simple" : "Advanced")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .buttonStyle(.plain)

                Spacer()

                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)

                Button("Save") { save() }
                    .keyboardShortcut(.defaultAction)
                    .disabled(!isValid)
            }
            .padding(.horizontal, 20)
            .padding(.bottom, 16)
        }
        .frame(width: 340, height: isAdvanced ? 440 : 280)
    }

    // MARK: - Simple Editor

    private var simpleEditor: some View {
        VStack(spacing: 10) {
            HStack {
                Text("Focus")
                    .frame(width: 70, alignment: .leading)
                TextField("", value: $focusMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("min")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }

            HStack {
                Text("Break")
                    .frame(width: 70, alignment: .leading)
                TextField("", value: $breakMinutes, format: .number)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)
                Text("min")
                    .foregroundStyle(.secondary)
                    .font(.caption)
                Spacer()
            }

            HStack {
                Text("Sessions")
                    .frame(width: 70, alignment: .leading)
                Stepper("\(sessionCount)", value: $sessionCount, in: 1...99)
                    .frame(width: 100)
                Spacer()
            }
        }
    }

    // MARK: - Advanced Editor

    private var advancedEditor: some View {
        VStack(spacing: 8) {
            ScrollView {
                VStack(spacing: 6) {
                    ForEach($blocks) { $block in
                        HStack(spacing: 8) {
                            Picker("", selection: $block.phase) {
                                Text("Focus").tag(TimerPhase.focus)
                                Text("Break").tag(TimerPhase.shortBreak)
                            }
                            .labelsHidden()
                            .frame(width: 80)

                            TextField("", value: Binding(
                                get: { block.duration / 60 },
                                set: { block.duration = $0 * 60 }
                            ), format: .number)
                            .textFieldStyle(.roundedBorder)
                            .frame(width: 50)
                            .multilineTextAlignment(.trailing)

                            Text("min")
                                .foregroundStyle(.secondary)
                                .font(.caption)

                            Spacer()

                            Button(action: { blocks.removeAll { $0.id == block.id } }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundStyle(.secondary)
                                    .font(.system(size: 14))
                            }
                            .buttonStyle(.plain)
                        }
                        .padding(.vertical, 2)
                    }
                }
            }
            .frame(maxHeight: 200)

            HStack(spacing: 12) {
                Button(action: {
                    blocks.append(TimerBlock(phase: .focus, duration: 25 * 60))
                }) {
                    Label("Focus", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Button(action: {
                    blocks.append(TimerBlock(phase: .shortBreak, duration: 5 * 60))
                }) {
                    Label("Break", systemImage: "plus")
                        .font(.caption)
                }
                .buttonStyle(.bordered)

                Spacer()
            }
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
