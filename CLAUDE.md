# Pomo

macOS Pomodoro timer app — native SwiftUI with menu bar integration.

## Build & Run

```bash
cd Pomo

# Build
swift build

# Test (requires framework flags for CLI tools)
swift test -Xswiftc -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks

# Release build + install to /Applications
swift build -c release
pkill -f "Pomo" 2>/dev/null; sleep 1
cp .build/release/Pomo /Applications/Pomo.app/Contents/MacOS/Pomo
open /Applications/Pomo.app
```

## Project Structure

```
Pomo/
├── Package.swift
├── Sources/
│   ├── PomoApp.swift              # App entry point, window + menu bar + MenuBarLabel
│   ├── Models/
│   │   ├── TimerPhase.swift       # Enum: idle, focus, shortBreak
│   │   ├── Preset.swift           # Preset model + TimerBlock (simple + advanced sequences)
│   │   └── AppSettings.swift      # Settings with UserDefaults persistence
│   ├── ViewModels/
│   │   ├── TimerManager.swift     # Sequence-based timer engine
│   │   └── PresetStore.swift      # Preset CRUD + UserDefaults
│   ├── Views/
│   │   ├── MainWindow/            # ContentView, TimerTabView, PresetsTabView, SettingsTabView
│   │   ├── MenuBar/               # MenuBarPopover
│   │   └── Components/            # DoubleRingView, TimerControlsView, PresetEditorSheet
│   ├── Utilities/                 # NotificationManager, Color+Hex
│   └── Resources/                 # chime.aiff, AppIcon.icns
└── Tests/                         # Swift Testing framework tests
```

## Environment Notes

- No Xcode.app — only Command Line Tools installed
- Uses Swift Testing (`import Testing`, `@Test`, `#expect`), NOT XCTest
- All ObservableObject classes are `@MainActor` (Swift 6 strict concurrency)
- UNUserNotificationCenter is guarded for non-bundle builds
- App bundle at `/Applications/Pomo.app` with Info.plist

## Conventions

- Don't add Co-Authored-By lines to commits
- Keep UI clean and minimal
- Strawberry icon, not tomato
