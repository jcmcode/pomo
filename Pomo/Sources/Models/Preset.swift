import Foundation

/// A single block in an advanced sequence
struct TimerBlock: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var phase: TimerPhase
    var duration: TimeInterval // seconds

    init(id: UUID = UUID(), phase: TimerPhase, duration: TimeInterval) {
        self.id = id
        self.phase = phase
        self.duration = duration
    }

    var displayDuration: String {
        let mins = Int(duration / 60)
        return "\(mins)m"
    }
}

struct Preset: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    let isBuiltIn: Bool

    // Simple mode fields
    var focusDuration: TimeInterval
    var breakDuration: TimeInterval
    var sessionCount: Int

    // Advanced mode: custom sequence of blocks (nil = simple mode)
    var advancedBlocks: [TimerBlock]?

    var isAdvanced: Bool { advancedBlocks != nil }

    init(
        id: UUID = UUID(),
        name: String,
        focusDuration: TimeInterval,
        breakDuration: TimeInterval,
        sessionCount: Int,
        isBuiltIn: Bool,
        advancedBlocks: [TimerBlock]? = nil
    ) {
        self.id = id
        self.name = name
        self.focusDuration = focusDuration
        self.breakDuration = breakDuration
        self.sessionCount = sessionCount
        self.isBuiltIn = isBuiltIn
        self.advancedBlocks = advancedBlocks
    }

    /// Build the full sequence of blocks for this preset
    var sequence: [TimerBlock] {
        if let blocks = advancedBlocks {
            return blocks
        }
        // Simple mode: generate Focus → Break → Focus → Break → ... → Focus
        var blocks: [TimerBlock] = []
        for i in 0..<sessionCount {
            blocks.append(TimerBlock(phase: .focus, duration: focusDuration))
            if i < sessionCount - 1 && breakDuration > 0 {
                blocks.append(TimerBlock(phase: .shortBreak, duration: breakDuration))
            }
        }
        return blocks
    }

    /// Total number of focus sessions in this preset
    var totalFocusSessions: Int {
        sequence.filter { $0.phase == .focus }.count
    }

    // MARK: - Built-in Presets

    static let classic = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Classic",
        focusDuration: 25 * 60,
        breakDuration: 5 * 60,
        sessionCount: 4,
        isBuiltIn: true
    )

    static let deepWork = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Deep Work",
        focusDuration: 50 * 60,
        breakDuration: 10 * 60,
        sessionCount: 3,
        isBuiltIn: true
    )

    static let shortSprint = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Short Sprint",
        focusDuration: 15 * 60,
        breakDuration: 3 * 60,
        sessionCount: 4,
        isBuiltIn: true
    )

    static let builtInPresets: [Preset] = [classic, deepWork, shortSprint]
}
