import Foundation

enum TimerPhase: String, Codable, Equatable, Sendable {
    case idle
    case focus
    case shortBreak

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .focus: return "Focus"
        case .shortBreak: return "Break"
        }
    }

    var isBreak: Bool {
        self == .shortBreak
    }
}
