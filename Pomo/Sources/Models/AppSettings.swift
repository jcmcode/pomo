import Foundation
import SwiftUI

enum AppearanceMode: String, Codable, CaseIterable, Sendable {
    case system
    case light
    case dark

    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

@MainActor
final class AppSettings: ObservableObject {
    @Published var systemNotificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(systemNotificationsEnabled, forKey: "systemNotificationsEnabled") }
    }
    @Published var soundEnabled: Bool {
        didSet { UserDefaults.standard.set(soundEnabled, forKey: "soundEnabled") }
    }
    @Published var visualNotificationsEnabled: Bool {
        didSet { UserDefaults.standard.set(visualNotificationsEnabled, forKey: "visualNotificationsEnabled") }
    }
    @Published var appearanceMode: AppearanceMode {
        didSet { UserDefaults.standard.set(appearanceMode.rawValue, forKey: "appearanceMode") }
    }
    @Published var startAtLogin: Bool {
        didSet { UserDefaults.standard.set(startAtLogin, forKey: "startAtLogin") }
    }
    @Published var keepWindowOnTop: Bool {
        didSet { UserDefaults.standard.set(keepWindowOnTop, forKey: "keepWindowOnTop") }
    }

    init() {
        let defaults = UserDefaults.standard
        self.systemNotificationsEnabled = defaults.object(forKey: "systemNotificationsEnabled") as? Bool ?? true
        self.soundEnabled = defaults.object(forKey: "soundEnabled") as? Bool ?? true
        self.visualNotificationsEnabled = defaults.object(forKey: "visualNotificationsEnabled") as? Bool ?? true
        self.appearanceMode = AppearanceMode(rawValue: defaults.string(forKey: "appearanceMode") ?? "") ?? .system
        self.startAtLogin = defaults.bool(forKey: "startAtLogin")
        self.keepWindowOnTop = defaults.bool(forKey: "keepWindowOnTop")
    }
}
