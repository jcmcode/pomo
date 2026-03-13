# Pomo Implementation Plan

> **For agentic workers:** REQUIRED: Use superpowers:subagent-driven-development (if subagents available) or superpowers:executing-plans to implement this plan. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a native SwiftUI macOS Pomodoro timer app with menu bar integration, double-ring timer visualization, and customizable presets.

**Architecture:** SwiftUI app with `NSStatusItem` for menu bar and a standard window. A single `TimerManager` ObservableObject drives both UIs. Data stored locally in UserDefaults. The app is structured as a standard Xcode Swift Package with separate files for models, view models, views, and utilities.

**Tech Stack:** Swift, SwiftUI, AppKit (NSStatusItem), UserNotifications, ServiceManagement (SMAppService)

---

## File Structure

```
Pomo/
├── Pomo.xcodeproj/                     # Xcode project (generated)
├── Pomo/
│   ├── PomoApp.swift                   # App entry point, window + menu bar setup
│   ├── Models/
│   │   ├── TimerPhase.swift            # Enum: focus, shortBreak, longBreak, idle
│   │   ├── Preset.swift                # Preset model (name, durations, cycle count)
│   │   └── AppSettings.swift           # Settings model (notification toggles, appearance, general)
│   ├── ViewModels/
│   │   ├── TimerManager.swift          # Core timer engine (ObservableObject, single source of truth)
│   │   └── PresetStore.swift           # Preset CRUD, UserDefaults persistence
│   ├── Views/
│   │   ├── MainWindow/
│   │   │   ├── ContentView.swift       # Tab container (Timer, Presets, Settings)
│   │   │   ├── TimerTabView.swift      # Full-size double-ring + controls
│   │   │   ├── PresetsTabView.swift    # Preset list, create/edit/delete
│   │   │   └── SettingsTabView.swift   # Notification, appearance, general toggles
│   │   ├── MenuBar/
│   │   │   └── MenuBarPopover.swift    # Menu bar dropdown: mini ring, controls, quick-switch
│   │   └── Components/
│   │       ├── DoubleRingView.swift    # Reusable double-ring timer visualization
│   │       ├── TimerControlsView.swift # Pause/Skip/Start buttons (reused in window + menu bar)
│   │       └── PresetEditorSheet.swift # Create/edit preset form
│   ├── Utilities/
│   │   ├── NotificationManager.swift   # System notifications + sound playback
│   │   └── Color+Hex.swift            # Color extension for hex string init
│   ├── Resources/
│   │   └── chime.aiff                  # Timer completion sound
│   └── Assets.xcassets/                # App icon, colors
├── PomoTests/
│   ├── TimerManagerTests.swift         # Timer engine unit tests
│   ├── PresetStoreTests.swift          # Preset CRUD + persistence tests
│   ├── PresetTests.swift               # Preset model validation tests
│   └── TimerPhaseTests.swift           # Phase transition logic tests
└── docs/                               # Existing spec + plan docs
```

---

## Chunk 1: Project Setup, Models, and Timer Engine

### Task 1: Create Xcode Project

**Files:**
- Create: `Pomo/` Xcode project structure

- [ ] **Step 1: Create the Xcode project via command line**

Use `xcodegen` or create manually in Xcode. The most reliable approach:

1. Open Xcode
2. File → New → Project → macOS → App
3. Product Name: `Pomo`, Interface: SwiftUI, Language: Swift, Testing System: XCTest
4. Save into `/Users/jack/Documents/code/pomo/`
5. This creates `Pomo.xcodeproj` and the `Pomo/` source directory
6. Add a test target: File → New → Target → macOS → Unit Testing Bundle, name it `PomoTests`

**Note:** This step requires Xcode GUI. An agentic worker should create the project interactively or use a pre-existing project template.

- [ ] **Step 3: Verify project builds**

```bash
cd /Users/jack/Documents/code/pomo
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Pomo.xcodeproj Pomo/ PomoTests/
git commit -m "feat: initialize Xcode project for Pomo macOS app"
```

---

### Task 2: TimerPhase Model

**Files:**
- Create: `Pomo/Pomo/Models/TimerPhase.swift`
- Create: `Pomo/PomoTests/TimerPhaseTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Pomo/PomoTests/TimerPhaseTests.swift`:

```swift
import XCTest
@testable import Pomo

final class TimerPhaseTests: XCTestCase {
    func testPhaseDisplayName() {
        XCTAssertEqual(TimerPhase.focus.displayName, "Focus")
        XCTAssertEqual(TimerPhase.shortBreak.displayName, "Short Break")
        XCTAssertEqual(TimerPhase.longBreak.displayName, "Long Break")
        XCTAssertEqual(TimerPhase.idle.displayName, "Idle")
    }

    func testPhaseIsBreak() {
        XCTAssertFalse(TimerPhase.focus.isBreak)
        XCTAssertTrue(TimerPhase.shortBreak.isBreak)
        XCTAssertTrue(TimerPhase.longBreak.isBreak)
        XCTAssertFalse(TimerPhase.idle.isBreak)
    }

    func testNextPhaseFromFocusNotLastCycle() {
        // In cycle 1 of 4, after focus → short break
        let next = TimerPhase.nextPhase(after: .focus, currentPomodoro: 1, totalPomodoros: 4)
        XCTAssertEqual(next, .shortBreak)
    }

    func testNextPhaseFromFocusLastCycle() {
        // In cycle 4 of 4, after focus → long break
        let next = TimerPhase.nextPhase(after: .focus, currentPomodoro: 4, totalPomodoros: 4)
        XCTAssertEqual(next, .longBreak)
    }

    func testNextPhaseFromShortBreak() {
        // After short break → focus
        let next = TimerPhase.nextPhase(after: .shortBreak, currentPomodoro: 1, totalPomodoros: 4)
        XCTAssertEqual(next, .focus)
    }

    func testNextPhaseFromLongBreak() {
        // After long break → idle (cycle complete)
        let next = TimerPhase.nextPhase(after: .longBreak, currentPomodoro: 4, totalPomodoros: 4)
        XCTAssertEqual(next, .idle)
    }

    func testNextPhaseFromIdle() {
        // From idle → focus (starting fresh)
        let next = TimerPhase.nextPhase(after: .idle, currentPomodoro: 1, totalPomodoros: 4)
        XCTAssertEqual(next, .focus)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: FAIL — `TimerPhase` not defined

- [ ] **Step 3: Write the implementation**

Create `Pomo/Pomo/Models/TimerPhase.swift`:

```swift
import Foundation

enum TimerPhase: String, Codable, Equatable {
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: All TimerPhaseTests PASS

- [ ] **Step 5: Commit**

```bash
git add Pomo/Pomo/Models/TimerPhase.swift Pomo/PomoTests/TimerPhaseTests.swift
git commit -m "feat: add TimerPhase model with phase transition logic"
```

---

### Task 3: Preset Model

**Files:**
- Create: `Pomo/Pomo/Models/Preset.swift`
- Create: `Pomo/PomoTests/PresetTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Pomo/PomoTests/PresetTests.swift`:

```swift
import XCTest
@testable import Pomo

final class PresetTests: XCTestCase {
    func testBuiltInPresets() {
        let classic = Preset.classic
        XCTAssertEqual(classic.name, "Classic")
        XCTAssertEqual(classic.focusDuration, 25 * 60)
        XCTAssertEqual(classic.shortBreakDuration, 5 * 60)
        XCTAssertEqual(classic.longBreakDuration, 15 * 60)
        XCTAssertEqual(classic.cycleCount, 4)
        XCTAssertTrue(classic.isBuiltIn)

        let deepWork = Preset.deepWork
        XCTAssertEqual(deepWork.focusDuration, 50 * 60)
        XCTAssertEqual(deepWork.cycleCount, 3)

        let sprint = Preset.shortSprint
        XCTAssertEqual(sprint.focusDuration, 15 * 60)
    }

    func testCustomPreset() {
        let custom = Preset(
            name: "My Custom",
            focusDuration: 45 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 20 * 60,
            cycleCount: 3,
            isBuiltIn: false
        )
        XCTAssertEqual(custom.name, "My Custom")
        XCTAssertFalse(custom.isBuiltIn)
    }

    func testPresetCodable() throws {
        let preset = Preset(
            name: "Test",
            focusDuration: 600,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            cycleCount: 2,
            isBuiltIn: false
        )
        let data = try JSONEncoder().encode(preset)
        let decoded = try JSONDecoder().decode(Preset.self, from: data)
        XCTAssertEqual(decoded.name, preset.name)
        XCTAssertEqual(decoded.focusDuration, preset.focusDuration)
        XCTAssertEqual(decoded.id, preset.id)
    }

    func testDurationForPhase() {
        let preset = Preset.classic
        XCTAssertEqual(preset.duration(for: .focus), 25 * 60)
        XCTAssertEqual(preset.duration(for: .shortBreak), 5 * 60)
        XCTAssertEqual(preset.duration(for: .longBreak), 15 * 60)
        XCTAssertEqual(preset.duration(for: .idle), 0)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: FAIL — `Preset` not defined

- [ ] **Step 3: Write the implementation**

Create `Pomo/Pomo/Models/Preset.swift`:

```swift
import Foundation

struct Preset: Identifiable, Codable, Equatable {
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
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: All PresetTests PASS

- [ ] **Step 5: Commit**

```bash
git add Pomo/Pomo/Models/Preset.swift Pomo/PomoTests/PresetTests.swift
git commit -m "feat: add Preset model with built-in presets and codable support"
```

---

### Task 4: AppSettings Model

**Files:**
- Create: `Pomo/Pomo/Models/AppSettings.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Models/AppSettings.swift`:

```swift
import Foundation

enum AppearanceMode: String, Codable, CaseIterable {
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
```

No tests needed — thin wrapper over UserDefaults with no business logic.

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Models/AppSettings.swift
git commit -m "feat: add AppSettings model with UserDefaults persistence"
```

---

### Task 5: PresetStore

**Files:**
- Create: `Pomo/Pomo/ViewModels/PresetStore.swift`
- Create: `Pomo/PomoTests/PresetStoreTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Pomo/PomoTests/PresetStoreTests.swift`:

```swift
import XCTest
@testable import Pomo

final class PresetStoreTests: XCTestCase {
    var store: PresetStore!

    override func setUp() {
        super.setUp()
        // Use a separate UserDefaults suite for testing
        let defaults = UserDefaults(suiteName: "com.pomo.tests")!
        defaults.removePersistentDomain(forName: "com.pomo.tests")
        store = PresetStore(defaults: defaults)
    }

    func testInitialPresetsContainsBuiltIns() {
        XCTAssertEqual(store.allPresets.count, 3)
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Classic" }))
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Deep Work" }))
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Short Sprint" }))
    }

    func testAddCustomPreset() {
        let custom = Preset(
            name: "Custom",
            focusDuration: 45 * 60,
            shortBreakDuration: 10 * 60,
            longBreakDuration: 20 * 60,
            cycleCount: 3,
            isBuiltIn: false
        )
        store.addPreset(custom)
        XCTAssertEqual(store.allPresets.count, 4)
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Custom" }))
    }

    func testDeleteCustomPreset() {
        let custom = Preset(
            name: "ToDelete",
            focusDuration: 600,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            cycleCount: 2,
            isBuiltIn: false
        )
        store.addPreset(custom)
        XCTAssertEqual(store.allPresets.count, 4)
        store.deletePreset(custom)
        XCTAssertEqual(store.allPresets.count, 3)
    }

    func testCannotDeleteBuiltInPreset() {
        store.deletePreset(Preset.classic)
        XCTAssertEqual(store.allPresets.count, 3)
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Classic" }))
    }

    func testUpdateCustomPreset() {
        var custom = Preset(
            name: "Original",
            focusDuration: 600,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            cycleCount: 2,
            isBuiltIn: false
        )
        store.addPreset(custom)
        custom.name = "Updated"
        store.updatePreset(custom)
        XCTAssertTrue(store.allPresets.contains(where: { $0.name == "Updated" }))
        XCTAssertFalse(store.allPresets.contains(where: { $0.name == "Original" }))
    }

    func testPersistenceRoundTrip() {
        let defaults = UserDefaults(suiteName: "com.pomo.tests.persist")!
        defaults.removePersistentDomain(forName: "com.pomo.tests.persist")

        let store1 = PresetStore(defaults: defaults)
        let custom = Preset(
            name: "Persisted",
            focusDuration: 600,
            shortBreakDuration: 300,
            longBreakDuration: 900,
            cycleCount: 2,
            isBuiltIn: false
        )
        store1.addPreset(custom)

        let store2 = PresetStore(defaults: defaults)
        XCTAssertEqual(store2.allPresets.count, 4)
        XCTAssertTrue(store2.allPresets.contains(where: { $0.name == "Persisted" }))
    }

    func testActivePresetDefaultsToClassic() {
        XCTAssertEqual(store.activePreset.id, Preset.classic.id)
    }

    func testSetActivePreset() {
        store.setActivePreset(Preset.deepWork)
        XCTAssertEqual(store.activePreset.id, Preset.deepWork.id)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: FAIL — `PresetStore` not defined

- [ ] **Step 3: Write the implementation**

Create `Pomo/Pomo/ViewModels/PresetStore.swift`:

```swift
import Foundation

final class PresetStore: ObservableObject {
    @Published private(set) var customPresets: [Preset] = []
    @Published private(set) var activePreset: Preset = .classic

    private let defaults: UserDefaults
    private let customPresetsKey = "customPresets"
    private let activePresetIdKey = "activePresetId"

    var allPresets: [Preset] {
        Preset.builtInPresets + customPresets
    }

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults
        self.customPresets = Self.loadCustomPresets(from: defaults)
        self.activePreset = Self.loadActivePreset(from: defaults, customPresets: self.customPresets)
    }

    func addPreset(_ preset: Preset) {
        customPresets.append(preset)
        saveCustomPresets()
    }

    func deletePreset(_ preset: Preset) {
        guard !preset.isBuiltIn else { return }
        customPresets.removeAll { $0.id == preset.id }
        if activePreset.id == preset.id {
            activePreset = .classic
            saveActivePresetId()
        }
        saveCustomPresets()
    }

    func updatePreset(_ preset: Preset) {
        guard let index = customPresets.firstIndex(where: { $0.id == preset.id }) else { return }
        customPresets[index] = preset
        if activePreset.id == preset.id {
            activePreset = preset
        }
        saveCustomPresets()
    }

    func setActivePreset(_ preset: Preset) {
        activePreset = preset
        saveActivePresetId()
    }

    // MARK: - Persistence

    private func saveCustomPresets() {
        if let data = try? JSONEncoder().encode(customPresets) {
            defaults.set(data, forKey: customPresetsKey)
        }
    }

    private func saveActivePresetId() {
        defaults.set(activePreset.id.uuidString, forKey: activePresetIdKey)
    }

    private static func loadCustomPresets(from defaults: UserDefaults) -> [Preset] {
        guard let data = defaults.data(forKey: "customPresets"),
              let presets = try? JSONDecoder().decode([Preset].self, from: data) else {
            return []
        }
        return presets
    }

    private static func loadActivePreset(from defaults: UserDefaults, customPresets: [Preset]) -> Preset {
        guard let idString = defaults.string(forKey: "activePresetId"),
              let id = UUID(uuidString: idString) else {
            return .classic
        }
        let all = Preset.builtInPresets + customPresets
        return all.first(where: { $0.id == id }) ?? .classic
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: All PresetStoreTests PASS

- [ ] **Step 5: Commit**

```bash
git add Pomo/Pomo/ViewModels/PresetStore.swift Pomo/PomoTests/PresetStoreTests.swift
git commit -m "feat: add PresetStore with CRUD operations and UserDefaults persistence"
```

---

### Task 6: TimerManager

**Files:**
- Create: `Pomo/Pomo/ViewModels/TimerManager.swift`
- Create: `Pomo/PomoTests/TimerManagerTests.swift`

- [ ] **Step 1: Write the failing test**

Create `Pomo/PomoTests/TimerManagerTests.swift`:

```swift
import XCTest
@testable import Pomo

final class TimerManagerTests: XCTestCase {
    var manager: TimerManager!
    var presetStore: PresetStore!

    override func setUp() {
        super.setUp()
        let defaults = UserDefaults(suiteName: "com.pomo.timer.tests")!
        defaults.removePersistentDomain(forName: "com.pomo.timer.tests")
        presetStore = PresetStore(defaults: defaults)
        manager = TimerManager(presetStore: presetStore)
    }

    func testInitialState() {
        XCTAssertEqual(manager.phase, .idle)
        XCTAssertEqual(manager.timeRemaining, 0)
        XCTAssertEqual(manager.currentPomodoro, 1)
        XCTAssertFalse(manager.isRunning)
    }

    func testStartBeginsFirstFocusSession() {
        manager.start()
        XCTAssertEqual(manager.phase, .focus)
        XCTAssertEqual(manager.timeRemaining, 25 * 60) // Classic preset
        XCTAssertTrue(manager.isRunning)
    }

    func testPauseAndResume() {
        manager.start()
        manager.pause()
        XCTAssertFalse(manager.isRunning)
        XCTAssertEqual(manager.phase, .focus) // Still in focus, just paused
        manager.resume()
        XCTAssertTrue(manager.isRunning)
    }

    func testSkipMovesToNextPhase() {
        manager.start()
        XCTAssertEqual(manager.phase, .focus)
        manager.skip()
        XCTAssertEqual(manager.phase, .shortBreak)
        XCTAssertEqual(manager.timeRemaining, 5 * 60)
        XCTAssertTrue(manager.isRunning)
    }

    func testSkipOnLastFocusGoesToLongBreak() {
        manager.start()
        // Skip through 3 focus+break cycles to get to pomodoro 4
        for _ in 1..<4 {
            manager.skip() // focus → short break
            manager.skip() // short break → focus
        }
        XCTAssertEqual(manager.currentPomodoro, 4)
        XCTAssertEqual(manager.phase, .focus)
        manager.skip() // focus 4 → long break
        XCTAssertEqual(manager.phase, .longBreak)
    }

    func testSkipFromLongBreakGoesToIdle() {
        manager.start()
        for _ in 1..<4 {
            manager.skip()
            manager.skip()
        }
        manager.skip() // → long break
        manager.skip() // → idle
        XCTAssertEqual(manager.phase, .idle)
        XCTAssertFalse(manager.isRunning)
    }

    func testResetCycle() {
        manager.start()
        manager.skip()
        manager.skip()
        manager.resetCycle()
        XCTAssertEqual(manager.phase, .idle)
        XCTAssertEqual(manager.currentPomodoro, 1)
        XCTAssertFalse(manager.isRunning)
    }

    func testProgressCalculation() {
        manager.start()
        XCTAssertEqual(manager.progress, 0.0, accuracy: 0.01) // Just started
        // Simulate time passing by setting timeRemaining directly for testing
        manager.timeRemaining = 12.5 * 60 // Half of 25 minutes
        XCTAssertEqual(manager.progress, 0.5, accuracy: 0.01)
    }

    func testCycleProgress() {
        manager.start()
        // Pomodoro 1 of 4
        XCTAssertEqual(manager.cycleProgress, 0.0, accuracy: 0.01)

        manager.skip() // → short break
        manager.skip() // → focus (pomo 2)
        // Completed 1 of 4
        XCTAssertEqual(manager.cycleProgress, 0.25, accuracy: 0.01)
    }
}
```

- [ ] **Step 2: Run tests to verify they fail**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: FAIL — `TimerManager` not defined

- [ ] **Step 3: Write the implementation**

Create `Pomo/Pomo/ViewModels/TimerManager.swift`:

```swift
import Foundation
import Combine

final class TimerManager: ObservableObject {
    @Published var phase: TimerPhase = .idle
    @Published var timeRemaining: TimeInterval = 0
    @Published var currentPomodoro: Int = 1
    @Published var isRunning: Bool = false

    private var timer: AnyCancellable?
    private let presetStore: PresetStore

    /// Callback fired on each phase transition (for notifications)
    var onPhaseTransition: ((TimerPhase, TimerPhase) -> Void)?

    var activePreset: Preset {
        presetStore.activePreset
    }

    var totalDuration: TimeInterval {
        activePreset.duration(for: phase)
    }

    var progress: Double {
        guard totalDuration > 0 else { return 0 }
        return 1.0 - (timeRemaining / totalDuration)
    }

    var cycleProgress: Double {
        guard activePreset.cycleCount > 0 else { return 0 }
        let completed = Double(currentPomodoro - 1)
        return completed / Double(activePreset.cycleCount)
    }

    init(presetStore: PresetStore) {
        self.presetStore = presetStore
    }

    func start() {
        phase = .focus
        currentPomodoro = 1
        timeRemaining = activePreset.duration(for: .focus)
        isRunning = true
        startTimer()
    }

    func pause() {
        isRunning = false
        stopTimer()
    }

    func resume() {
        isRunning = true
        startTimer()
    }

    func skip() {
        let oldPhase = phase
        let nextPhase = TimerPhase.nextPhase(
            after: phase,
            currentPomodoro: currentPomodoro,
            totalPomodoros: activePreset.cycleCount
        )

        if oldPhase == .shortBreak {
            currentPomodoro += 1
        }

        phase = nextPhase

        if nextPhase == .idle {
            timeRemaining = 0
            isRunning = false
            stopTimer()
        } else {
            timeRemaining = activePreset.duration(for: nextPhase)
            isRunning = true
            startTimer()
        }

        onPhaseTransition?(oldPhase, nextPhase)
    }

    func resetCycle() {
        stopTimer()
        phase = .idle
        timeRemaining = 0
        currentPomodoro = 1
        isRunning = false
    }

    // MARK: - Timer

    private func startTimer() {
        stopTimer()
        timer = Timer.publish(every: 1, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.tick()
            }
    }

    private func stopTimer() {
        timer?.cancel()
        timer = nil
    }

    private func tick() {
        guard isRunning else { return }
        if timeRemaining > 0 {
            timeRemaining -= 1
        }
        if timeRemaining <= 0 {
            skip()
        }
    }
}
```

- [ ] **Step 4: Run tests to verify they pass**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: All TimerManagerTests PASS

- [ ] **Step 5: Commit**

```bash
git add Pomo/Pomo/ViewModels/TimerManager.swift Pomo/PomoTests/TimerManagerTests.swift
git commit -m "feat: add TimerManager with phase transitions, pause/resume, skip, and progress tracking"
```

---

## Chunk 2: UI Components and Main Window

### Task 7: Color+Hex Utility and DoubleRingView Component

**Files:**
- Create: `Pomo/Pomo/Utilities/Color+Hex.swift`
- Create: `Pomo/Pomo/Views/Components/DoubleRingView.swift`

- [ ] **Step 1: Create the Color hex extension**

Create `Pomo/Pomo/Utilities/Color+Hex.swift`:

```swift
import SwiftUI

extension Color {
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let r, g, b: Double
        r = Double((int >> 16) & 0xFF) / 255.0
        g = Double((int >> 8) & 0xFF) / 255.0
        b = Double(int & 0xFF) / 255.0
        self.init(red: r, green: g, blue: b)
    }
}
```

- [ ] **Step 2: Write the DoubleRingView**

Create `Pomo/Pomo/Views/Components/DoubleRingView.swift`:

```swift
import SwiftUI

struct DoubleRingView: View {
    let timerProgress: Double    // 0.0 to 1.0 — inner ring
    let cycleProgress: Double    // 0.0 to 1.0 — outer ring
    let completedPomodoros: Int
    let totalPomodoros: Int
    let isBreak: Bool
    let size: CGFloat

    private var accentGradient: AngularGradient {
        let colors: [Color] = isBreak
            ? [Color(hex: "4ecdc4"), Color(hex: "4ecdc4")]
            : [Color(hex: "ff6b6b"), Color(hex: "ff8e53")]
        return AngularGradient(gradient: Gradient(colors: colors), center: .center)
    }

    private var outerRadius: CGFloat { size / 2 - 4 }
    private var innerRadius: CGFloat { size / 2 - 20 }
    private var outerStrokeWidth: CGFloat { size * 0.03 }
    private var innerStrokeWidth: CGFloat { size * 0.06 }

    var body: some View {
        ZStack {
            // Outer ring background (segmented)
            Circle()
                .stroke(Color.gray.opacity(0.2), style: StrokeStyle(lineWidth: outerStrokeWidth, dash: [4, 3]))
                .frame(width: outerRadius * 2, height: outerRadius * 2)

            // Outer ring filled segments (completed pomodoros)
            ForEach(0..<completedPomodoros, id: \.self) { index in
                Circle()
                    .trim(
                        from: CGFloat(index) / CGFloat(totalPomodoros),
                        to: CGFloat(index + 1) / CGFloat(totalPomodoros) - 0.01
                    )
                    .stroke(
                        isBreak ? Color(hex: "4ecdc4").opacity(0.5) : Color(hex: "ff8e53").opacity(0.5),
                        lineWidth: outerStrokeWidth
                    )
                    .frame(width: outerRadius * 2, height: outerRadius * 2)
                    .rotationEffect(.degrees(-90))
            }

            // Inner ring background
            Circle()
                .stroke(Color.gray.opacity(0.2), lineWidth: innerStrokeWidth)
                .frame(width: innerRadius * 2, height: innerRadius * 2)

            // Inner ring progress
            Circle()
                .trim(from: 0, to: timerProgress)
                .stroke(
                    isBreak
                        ? AnyShapeStyle(Color(hex: "4ecdc4"))
                        : AnyShapeStyle(LinearGradient(
                            colors: [Color(hex: "ff6b6b"), Color(hex: "ff8e53")],
                            startPoint: .leading,
                            endPoint: .trailing
                          )),
                    style: StrokeStyle(lineWidth: innerStrokeWidth, lineCap: .round)
                )
                .frame(width: innerRadius * 2, height: innerRadius * 2)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 1), value: timerProgress)
        }
        .frame(width: size, height: size)
    }
}

```

- [ ] **Step 3: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Commit**

```bash
git add Pomo/Pomo/Utilities/Color+Hex.swift Pomo/Pomo/Views/Components/DoubleRingView.swift
git commit -m "feat: add Color+Hex utility and DoubleRingView component"
```

---

### Task 8: TimerControlsView Component

**Files:**
- Create: `Pomo/Pomo/Views/Components/TimerControlsView.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/Components/TimerControlsView.swift`:

```swift
import SwiftUI

struct TimerControlsView: View {
    @ObservedObject var timerManager: TimerManager
    let compact: Bool

    var body: some View {
        if timerManager.phase == .idle {
            Button(action: { timerManager.start() }) {
                Label("Start", systemImage: "play.fill")
                    .frame(maxWidth: compact ? nil : .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(Color(hex: "ff6b6b"))
        } else {
            HStack(spacing: compact ? 8 : 12) {
                if timerManager.isRunning {
                    Button(action: { timerManager.pause() }) {
                        Label("Pause", systemImage: "pause.fill")
                            .frame(maxWidth: compact ? nil : .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "ff6b6b"))
                } else {
                    Button(action: { timerManager.resume() }) {
                        Label("Resume", systemImage: "play.fill")
                            .frame(maxWidth: compact ? nil : .infinity)
                    }
                    .buttonStyle(.borderedProminent)
                    .tint(Color(hex: "ff6b6b"))
                }

                Button(action: { timerManager.skip() }) {
                    Label("Skip", systemImage: "forward.fill")
                        .frame(maxWidth: compact ? nil : .infinity)
                }
                .buttonStyle(.bordered)
            }
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/Components/TimerControlsView.swift
git commit -m "feat: add TimerControlsView with start/pause/resume/skip buttons"
```

---

### Task 9: TimerTabView

**Files:**
- Create: `Pomo/Pomo/Views/MainWindow/TimerTabView.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/MainWindow/TimerTabView.swift`:

```swift
import SwiftUI

struct TimerTabView: View {
    @ObservedObject var timerManager: TimerManager

    private var timeString: String {
        let minutes = Int(timerManager.timeRemaining) / 60
        let seconds = Int(timerManager.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    private var phaseLabel: String {
        if timerManager.phase == .idle {
            return "Ready"
        }
        return "\(timerManager.phase.displayName) · \(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)"
    }

    private var nextPhaseLabel: String? {
        guard timerManager.phase != .idle else { return nil }
        let next = TimerPhase.nextPhase(
            after: timerManager.phase,
            currentPomodoro: timerManager.currentPomodoro,
            totalPomodoros: timerManager.activePreset.cycleCount
        )
        if next == .idle { return "Cycle Complete" }
        return "Next: \(next.displayName)"
    }

    var body: some View {
        VStack(spacing: 16) {
            Text(timerManager.activePreset.name)
                .font(.caption)
                .foregroundStyle(.secondary)

            ZStack {
                DoubleRingView(
                    timerProgress: timerManager.progress,
                    cycleProgress: timerManager.cycleProgress,
                    completedPomodoros: timerManager.currentPomodoro - 1,
                    totalPomodoros: timerManager.activePreset.cycleCount,
                    isBreak: timerManager.phase.isBreak,
                    size: 200
                )

                VStack(spacing: 4) {
                    Text(timeString)
                        .font(.system(size: 40, weight: .ultraLight, design: .default))
                        .monospacedDigit()

                    if timerManager.phase != .idle {
                        Text("\(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
            }

            Text(phaseLabel)
                .font(.headline)

            TimerControlsView(timerManager: timerManager, compact: false)
                .frame(maxWidth: 200)

            if let nextLabel = nextPhaseLabel {
                Text(nextLabel)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(24)
        .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/MainWindow/TimerTabView.swift
git commit -m "feat: add TimerTabView with double-ring visualization and controls"
```

---

### Task 10: PresetsTabView and PresetEditorSheet

**Files:**
- Create: `Pomo/Pomo/Views/MainWindow/PresetsTabView.swift`
- Create: `Pomo/Pomo/Views/Components/PresetEditorSheet.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/MainWindow/PresetsTabView.swift`:

```swift
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
                    // Only allow deleting custom presets (offset by built-in count)
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

// MARK: - Preset Row

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

```

- [ ] **Step 2: Write the PresetEditorSheet**

Create `Pomo/Pomo/Views/Components/PresetEditorSheet.swift`:

```swift
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
            && shortBreakMinutes >= 1 && shortBreakMinutes <= 1440
            && longBreakMinutes >= 1 && longBreakMinutes <= 1440
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
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/MainWindow/PresetsTabView.swift Pomo/Pomo/Views/Components/PresetEditorSheet.swift
git commit -m "feat: add PresetsTabView and PresetEditorSheet with CRUD, swipe-to-delete, and switch confirmation"
```

---

### Task 11: SettingsTabView

**Files:**
- Create: `Pomo/Pomo/Views/MainWindow/SettingsTabView.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/MainWindow/SettingsTabView.swift`:

```swift
import SwiftUI
import ServiceManagement

struct SettingsTabView: View {
    @ObservedObject var settings: AppSettings

    var body: some View {
        Form {
            Section("Notifications") {
                Toggle("System Notifications", isOn: $settings.systemNotificationsEnabled)
                Toggle("Sound", isOn: $settings.soundEnabled)
                Toggle("Visual (Menu Bar Pulse)", isOn: $settings.visualNotificationsEnabled)
            }

            Section("Appearance") {
                Picker("Theme", selection: $settings.appearanceMode) {
                    ForEach(AppearanceMode.allCases, id: \.self) { mode in
                        Text(mode.displayName).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
            }

            Section("General") {
                Toggle("Start at Login", isOn: $settings.startAtLogin)
                    .onChange(of: settings.startAtLogin) { _, newValue in
                        setLoginItem(enabled: newValue)
                    }
                Toggle("Keep Window on Top", isOn: $settings.keepWindowOnTop)
            }

            Section("About") {
                HStack {
                    Text("Version")
                    Spacer()
                    Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0.0")
                        .foregroundStyle(.secondary)
                }
            }
        }
        .formStyle(.grouped)
        .padding()
    }

    private func setLoginItem(enabled: Bool) {
        do {
            if enabled {
                try SMAppService.mainApp.register()
            } else {
                try SMAppService.mainApp.unregister()
            }
        } catch {
            // Silently fail — login items may not work in dev/unsigned builds
            print("Login item registration failed: \(error)")
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/MainWindow/SettingsTabView.swift
git commit -m "feat: add SettingsTabView with notification, appearance, and general toggles"
```

---

### Task 12: ContentView (Tab Container)

**Files:**
- Create: `Pomo/Pomo/Views/MainWindow/ContentView.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/MainWindow/ContentView.swift`:

```swift
import SwiftUI

struct ContentView: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var presetStore: PresetStore
    @ObservedObject var settings: AppSettings

    var body: some View {
        TabView {
            TimerTabView(timerManager: timerManager)
                .tabItem {
                    Label("Timer", systemImage: "timer")
                }

            PresetsTabView(presetStore: presetStore, timerManager: timerManager)
                .tabItem {
                    Label("Presets", systemImage: "list.bullet")
                }

            SettingsTabView(settings: settings)
                .tabItem {
                    Label("Settings", systemImage: "gear")
                }
        }
        .frame(minWidth: 350, minHeight: 420)
        .preferredColorScheme(colorScheme)
    }

    private var colorScheme: ColorScheme? {
        switch settings.appearanceMode {
        case .system: return nil
        case .light: return .light
        case .dark: return .dark
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/MainWindow/ContentView.swift
git commit -m "feat: add ContentView with tab container for Timer, Presets, and Settings"
```

---

## Chunk 3: Menu Bar, Notifications, and App Entry Point

### Task 13: NotificationManager

**Files:**
- Create: `Pomo/Pomo/Utilities/NotificationManager.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Utilities/NotificationManager.swift`:

```swift
import Foundation
import UserNotifications
import AppKit

final class NotificationManager {
    private let settings: AppSettings

    /// Set by PomoApp to trigger menu bar icon pulse
    var onVisualNotification: (() -> Void)?

    init(settings: AppSettings) {
        self.settings = settings
        requestNotificationPermission()
    }

    func handlePhaseTransition(from oldPhase: TimerPhase, to newPhase: TimerPhase) {
        if settings.systemNotificationsEnabled {
            sendSystemNotification(from: oldPhase, to: newPhase)
        }
        if settings.soundEnabled {
            playSound()
        }
        if settings.visualNotificationsEnabled {
            onVisualNotification?()
        }
    }

    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { _, _ in }
    }

    private func sendSystemNotification(from oldPhase: TimerPhase, to newPhase: TimerPhase) {
        let content = UNMutableNotificationContent()

        switch newPhase {
        case .shortBreak, .longBreak:
            content.title = "Focus Complete!"
            content.body = "Time for a \(newPhase == .longBreak ? "long " : "")break."
        case .focus:
            content.title = "Break Over!"
            content.body = "Time to focus."
        case .idle:
            content.title = "Cycle Complete!"
            content.body = "Great work! All pomodoros finished."
        }

        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }

    private func playSound() {
        if let soundURL = Bundle.main.url(forResource: "chime", withExtension: "aiff") {
            NSSound(contentsOf: soundURL, byReference: true)?.play()
        } else {
            NSSound.beep()
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Utilities/NotificationManager.swift
git commit -m "feat: add NotificationManager with system notifications and sound"
```

---

### Task 14: MenuBarPopover

**Files:**
- Create: `Pomo/Pomo/Views/MenuBar/MenuBarPopover.swift`

- [ ] **Step 1: Write the implementation**

Create `Pomo/Pomo/Views/MenuBar/MenuBarPopover.swift`:

```swift
import SwiftUI

struct MenuBarPopover: View {
    @ObservedObject var timerManager: TimerManager
    @ObservedObject var presetStore: PresetStore
    let onOpenWindow: () -> Void

    @State private var showingSwitchConfirmation = false
    @State private var pendingSwitchPreset: Preset?

    private var timeString: String {
        let minutes = Int(timerManager.timeRemaining) / 60
        let seconds = Int(timerManager.timeRemaining) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }

    var body: some View {
        VStack(spacing: 12) {
            // Mini ring + timer
            HStack(spacing: 14) {
                DoubleRingView(
                    timerProgress: timerManager.progress,
                    cycleProgress: timerManager.cycleProgress,
                    completedPomodoros: timerManager.currentPomodoro - 1,
                    totalPomodoros: timerManager.activePreset.cycleCount,
                    isBreak: timerManager.phase.isBreak,
                    size: 56
                )

                VStack(alignment: .leading, spacing: 2) {
                    Text(timeString)
                        .font(.system(size: 22, weight: .light))
                        .monospacedDigit()
                    Text(timerManager.phase == .idle
                         ? "Ready"
                         : "\(timerManager.phase.displayName) · \(timerManager.currentPomodoro) of \(timerManager.activePreset.cycleCount)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                Spacer()
            }

            // Controls
            TimerControlsView(timerManager: timerManager, compact: true)

            Divider()

            // Quick-switch presets
            VStack(alignment: .leading, spacing: 6) {
                Text("QUICK SWITCH")
                    .font(.system(size: 9, weight: .medium))
                    .foregroundStyle(.tertiary)

                HStack(spacing: 6) {
                    ForEach(Preset.builtInPresets) { preset in
                        Button(action: { handlePresetSwitch(preset) }) {
                            Text(preset.name)
                                .font(.system(size: 10))
                                .frame(maxWidth: .infinity)
                        }
                        .buttonStyle(.bordered)
                        .tint(preset.id == presetStore.activePreset.id ? Color(hex: "ff6b6b") : nil)
                    }
                }
            }

            Divider()

            // Open window
            Button(action: onOpenWindow) {
                HStack {
                    Spacer()
                    Text("Open Window")
                        .font(.caption)
                    Image(systemName: "arrow.up.right")
                        .font(.caption2)
                    Spacer()
                }
            }
            .buttonStyle(.plain)
            .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(width: 260)
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
        guard preset.id != presetStore.activePreset.id else { return }
        if timerManager.phase != .idle {
            pendingSwitchPreset = preset
            showingSwitchConfirmation = true
        } else {
            presetStore.setActivePreset(preset)
        }
    }
}
```

- [ ] **Step 2: Verify it compiles**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Views/MenuBar/MenuBarPopover.swift
git commit -m "feat: add MenuBarPopover with mini ring, controls, and preset quick-switch"
```

---

### Task 15: App Entry Point (PomoApp.swift)

**Files:**
- Modify: `Pomo/Pomo/PomoApp.swift`

- [ ] **Step 1: Write the implementation**

Replace the contents of `Pomo/Pomo/PomoApp.swift`:

```swift
import SwiftUI
import AppKit

@main
struct PomoApp: App {
    @StateObject private var presetStore = PresetStore()
    @StateObject private var settings = AppSettings()
    @StateObject private var timerManager: TimerManager
    @State private var notificationManager: NotificationManager?
    @State private var showPulse = false

    init() {
        let store = PresetStore()
        _presetStore = StateObject(wrappedValue: store)
        _timerManager = StateObject(wrappedValue: TimerManager(presetStore: store))
    }

    var body: some Scene {
        WindowGroup {
            ContentView(timerManager: timerManager, presetStore: presetStore, settings: settings)
                .onAppear {
                    setupNotifications()
                    applyWindowOnTop()
                }
                .onChange(of: settings.keepWindowOnTop) { _, _ in
                    applyWindowOnTop()
                }
        }
        .windowStyle(.titleBar)
        .defaultSize(width: 380, height: 480)

        MenuBarExtra {
            MenuBarPopover(
                timerManager: timerManager,
                presetStore: presetStore,
                onOpenWindow: { openMainWindow() }
            )
        } label: {
            MenuBarLabel(timerManager: timerManager)
        }
        .menuBarExtraStyle(.window)
    }

    private func setupNotifications() {
        guard notificationManager == nil else { return }
        let nm = NotificationManager(settings: settings)
        nm.onVisualNotification = {
            // Trigger a brief pulse animation on the menu bar icon
            showPulse = true
            DispatchQueue.main.asyncAfter(deadline: .now() + 2) {
                showPulse = false
            }
        }
        timerManager.onPhaseTransition = { oldPhase, newPhase in
            nm.handlePhaseTransition(from: oldPhase, to: newPhase)
        }
        self.notificationManager = nm
    }

    private func applyWindowOnTop() {
        DispatchQueue.main.async {
            NSApplication.shared.windows.first { $0.title != "" }?.level = settings.keepWindowOnTop ? .floating : .normal
        }
    }

    private func openMainWindow() {
        NSApplication.shared.activate(ignoringOtherApps: true)
        if let window = NSApplication.shared.windows.first(where: { $0.title != "" }) {
            window.makeKeyAndOrderFront(nil)
        }
    }
}

// MARK: - Menu Bar Label

struct MenuBarLabel: View {
    @ObservedObject var timerManager: TimerManager

    private var accentColor: Color {
        timerManager.phase.isBreak ? Color(hex: "4ecdc4") : Color(hex: "ff6b6b")
    }

    var body: some View {
        HStack(spacing: 4) {
            if timerManager.phase != .idle {
                // Strawberry inside a mini progress ring
                ZStack {
                    Circle()
                        .stroke(accentColor.opacity(0.3), lineWidth: 2)
                        .frame(width: 16, height: 16)
                    Circle()
                        .trim(from: 0, to: timerManager.progress)
                        .stroke(accentColor, style: StrokeStyle(lineWidth: 2, lineCap: .round))
                        .frame(width: 16, height: 16)
                        .rotationEffect(.degrees(-90))
                    Text("🍓")
                        .font(.system(size: 8))
                }
                Text(timeString(timerManager.timeRemaining))
                    .monospacedDigit()
                    .font(.caption)
            } else {
                Text("🍓")
            }
        }
    }

    private func timeString(_ interval: TimeInterval) -> String {
        let minutes = Int(interval) / 60
        let seconds = Int(interval) % 60
        return String(format: "%d:%02d", minutes, seconds)
    }
}

// Note: SwiftUI MenuBarExtra label support for custom views varies by macOS version.
// If the ring doesn't render correctly in the menu bar, fall back to just the emoji + text
// and handle visual pulse via NSStatusItem image manipulation in PomoApp.
```

- [ ] **Step 2: Remove the default ContentView if Xcode generated one**

If Xcode created a default `ContentView.swift` in the project root, delete it — we created our own at `Views/MainWindow/ContentView.swift`.

- [ ] **Step 3: Verify it builds and runs**

```bash
xcodebuild -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS' build
```

Expected: BUILD SUCCEEDED

- [ ] **Step 4: Run the app manually to smoke test**

Open Xcode, hit Run (Cmd+R). Verify:
- Main window opens with tabbed layout (Timer, Presets, Settings)
- Strawberry icon appears in menu bar
- Clicking menu bar icon shows popover with controls
- Start button begins a timer
- Timer counts down, ring fills
- Pause/Skip work
- Preset switching works (with confirmation when active)
- Settings toggles persist after restarting

- [ ] **Step 5: Commit**

```bash
git add Pomo/Pomo/PomoApp.swift
git commit -m "feat: add PomoApp entry point with window, menu bar, and notification wiring"
```

---

### Task 16: Add Chime Sound Asset

**Files:**
- Create: `Pomo/Pomo/Resources/chime.aiff`

- [ ] **Step 1: Generate or source a chime sound**

Option A — use macOS built-in sounds:
```bash
cp /System/Library/Sounds/Glass.aiff /Users/jack/Documents/code/pomo/Pomo/Pomo/Resources/chime.aiff
```

Option B — generate a simple chime with `afplay` test:
```bash
# Test the sound first
afplay /System/Library/Sounds/Glass.aiff
```

Pick whichever system sound you like best. Glass, Purr, or Tink are good options.

- [ ] **Step 2: Add to Xcode project**

In Xcode, drag `chime.aiff` into the Pomo target's Resources group. Ensure "Copy items if needed" is checked and the file is added to the Pomo target.

- [ ] **Step 3: Commit**

```bash
git add Pomo/Pomo/Resources/chime.aiff
git commit -m "feat: add timer completion chime sound"
```

---

### Task 17: Final Integration Test

- [ ] **Step 1: Run all tests**

```bash
xcodebuild test -project Pomo.xcodeproj -scheme Pomo -destination 'platform=macOS'
```

Expected: All tests PASS

- [ ] **Step 2: Run the app and verify full workflow**

1. Launch app
2. Start timer with Classic preset → verify 25:00 countdown starts
3. Verify double ring fills progressively
4. Skip to short break → verify 5:00 countdown, ring color changes to teal
5. Skip through full cycle → verify long break at end
6. Skip past long break → verify timer returns to idle
7. Switch to Deep Work preset → verify 50:00 focus
8. Create custom preset → verify it appears in list and menu bar
9. Delete custom preset → verify it's removed
10. Toggle notification settings → verify persistence
11. Toggle appearance (light/dark/system) → verify theme changes
12. Check menu bar: strawberry icon shows, timer text updates during active session
13. Click menu bar → verify popover matches main window state

- [ ] **Step 3: Commit any fixes**

```bash
git status
# Review staged files, then add only relevant changed files:
git add Pomo/
git commit -m "fix: integration test fixes"
```

- [ ] **Step 4: Add .superpowers to .gitignore**

```bash
echo ".superpowers/" >> /Users/jack/Documents/code/pomo/.gitignore
git add .gitignore
git commit -m "chore: add .superpowers to gitignore"
```
