import Foundation

/// Creates a fresh UserDefaults instance for the given suite name, clearing any prior data.
/// Primarily useful for tests that need isolated UserDefaults.
func makeCleanDefaults(suiteName: String) -> UserDefaults {
    let defaults = UserDefaults(suiteName: suiteName)!
    defaults.removePersistentDomain(forName: suiteName)
    return defaults
}
