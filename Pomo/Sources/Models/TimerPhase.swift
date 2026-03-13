import Foundation

enum TimerPhase: String, Codable, Equatable, Sendable {
    case idle
    case focus
    case shortBreak
    case longBreak

    var displayName: String {
        switch self {
        case .idle: return "Idle"
        case .focus: return "Focus"
        case .shortBreak: return "Short Break"
        case .longBreak: return "Long Break"
        }
    }

    var isBreak: Bool {
        self == .shortBreak || self == .longBreak
    }

    static func nextPhase(after phase: TimerPhase, currentPomodoro: Int, totalPomodoros: Int) -> TimerPhase {
        switch phase {
        case .idle:
            return .focus
        case .focus:
            if currentPomodoro >= totalPomodoros {
                return .longBreak
            }
            return .shortBreak
        case .shortBreak:
            return .focus
        case .longBreak:
            return .idle
        }
    }
}
