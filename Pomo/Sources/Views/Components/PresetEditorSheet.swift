import SwiftUI

struct PresetEditorSheet: View {
    let existingPreset: Preset?
    let onSave: (Preset) -> Void
    let onCancel: () -> Void

    @State private var name: String
    @State private var focusMinutes: Double
    @State private var shortBreakMinutes: Double
    @State private var longBreakMinutes: Double
    @State private var cycleCount: Int

    init(preset: Preset?, onSave: @escaping (Preset) -> Void, onCancel: @escaping () -> Void) {
        self.existingPreset = preset
        self.onSave = onSave
        self.onCancel = onCancel
        _name = State(initialValue: preset?.name ?? "")
        _focusMinutes = State(initialValue: (preset?.focusDuration ?? 25 * 60) / 60)
        _shortBreakMinutes = State(initialValue: (preset?.shortBreakDuration ?? 5 * 60) / 60)
        _longBreakMinutes = State(initialValue: (preset?.longBreakDuration ?? 15 * 60) / 60)
        _cycleCount = State(initialValue: preset?.cycleCount ?? 4)
    }

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
            && focusMinutes >= 1 && focusMinutes <= 1440
            && shortBreakMinutes >= 0 && shortBreakMinutes <= 1440
            && longBreakMinutes >= 0 && longBreakMinutes <= 1440
            && cycleCount >= 1 && cycleCount <= 99
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(existingPreset == nil ? "New Preset" : "Edit Preset")
                .font(.headline)

            Form {
                TextField("Name", text: $name)

                HStack {
                    Text("Focus (min)")
                    Spacer()
                    TextField("", value: $focusMinutes, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Short Break (min)")
                    Spacer()
                    TextField("", value: $shortBreakMinutes, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }

                HStack {
                    Text("Long Break (min)")
                    Spacer()
                    TextField("", value: $longBreakMinutes, format: .number)
                        .frame(width: 60)
                        .multilineTextAlignment(.trailing)
                }

                Stepper("Cycles: \(cycleCount)", value: $cycleCount, in: 1...99)
            }

            HStack {
                Button("Cancel", action: onCancel)
                    .keyboardShortcut(.cancelAction)
                Spacer()
                Button("Save") {
                    let preset = Preset(
                        id: existingPreset?.id ?? UUID(),
                        name: name.trimmingCharacters(in: .whitespaces),
                        focusDuration: focusMinutes * 60,
                        shortBreakDuration: shortBreakMinutes * 60,
                        longBreakDuration: longBreakMinutes * 60,
                        cycleCount: cycleCount,
                        isBuiltIn: false
                    )
                    onSave(preset)
                }
                .keyboardShortcut(.defaultAction)
                .disabled(!isValid)
            }
        }
        .padding()
        .frame(width: 350, height: 320)
    }
}
