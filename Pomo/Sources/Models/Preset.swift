import Foundation

struct Preset: Identifiable, Codable, Equatable, Sendable {
    let id: UUID
    var name: String
    var focusDuration: TimeInterval      // seconds
    var shortBreakDuration: TimeInterval  // seconds
    var longBreakDuration: TimeInterval   // seconds
    var cycleCount: Int
    let isBuiltIn: Bool

    init(
        id: UUID = UUID(),
        name: String,
        focusDuration: TimeInterval,
        shortBreakDuration: TimeInterval,
        longBreakDuration: TimeInterval,
        cycleCount: Int,
        isBuiltIn: Bool
    ) {
        self.id = id
        self.name = name
        self.focusDuration = focusDuration
        self.shortBreakDuration = shortBreakDuration
        self.longBreakDuration = longBreakDuration
        self.cycleCount = cycleCount
        self.isBuiltIn = isBuiltIn
    }

    func duration(for phase: TimerPhase) -> TimeInterval {
        switch phase {
        case .focus: return focusDuration
        case .shortBreak: return shortBreakDuration
        case .longBreak: return longBreakDuration
        case .idle: return 0
        }
    }

    // MARK: - Built-in Presets

    static let classic = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000001")!,
        name: "Classic",
        focusDuration: 25 * 60,
        shortBreakDuration: 5 * 60,
        longBreakDuration: 15 * 60,
        cycleCount: 4,
        isBuiltIn: true
    )

    static let deepWork = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000002")!,
        name: "Deep Work",
        focusDuration: 50 * 60,
        shortBreakDuration: 10 * 60,
        longBreakDuration: 20 * 60,
        cycleCount: 3,
        isBuiltIn: true
    )

    static let shortSprint = Preset(
        id: UUID(uuidString: "00000000-0000-0000-0000-000000000003")!,
        name: "Short Sprint",
        focusDuration: 15 * 60,
        shortBreakDuration: 3 * 60,
        longBreakDuration: 10 * 60,
        cycleCount: 4,
        isBuiltIn: true
    )

    static let builtInPresets: [Preset] = [classic, deepWork, shortSprint]
}
