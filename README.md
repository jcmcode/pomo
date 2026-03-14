# Pomo

A native macOS Pomodoro timer built with SwiftUI. Lives in both the menu bar and a main window.

## Features

- **Double-ring timer** — inner ring shows current timer progress, outer ring shows session progress
- **Menu bar integration** — strawberry icon with progress ring, full dropdown with controls and preset switching
- **Presets** — 3 built-in (Classic 25/5, Deep Work 50/10, Short Sprint 15/3) plus custom presets
- **Simple & Advanced modes** — simple mode: set focus, break, and session count. Advanced mode: build any sequence of focus/break blocks
- **Notifications** — system notifications, sound, and visual menu bar pulse (each toggleable)
- **Appearance** — system, light, or dark theme
- **Lightweight** — local-only, no accounts, no network

## Build & Run

Requires macOS 14+ and Swift 6 (Command Line Tools).

```bash
cd Pomo
swift build
.build/debug/Pomo
```

### Install to /Applications

```bash
cd Pomo
swift build -c release
cp .build/release/Pomo /Applications/Pomo.app/Contents/MacOS/Pomo
open /Applications/Pomo.app
```

### Run Tests

```bash
cd Pomo
swift test -Xswiftc -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -F/Library/Developer/CommandLineTools/Library/Developer/Frameworks \
  -Xlinker -rpath -Xlinker /Library/Developer/CommandLineTools/Library/Developer/Frameworks
```
