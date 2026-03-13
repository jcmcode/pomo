# Pomo — macOS Pomodoro Timer

## Overview

A native SwiftUI macOS productivity app built around the Pomodoro technique. Lightweight, local-only, personal-first. Lives in both the menu bar and a main window. Uses a distinctive double-ring timer visualization and a strawberry icon.

## Architecture

- **Platform:** Native macOS, SwiftUI
- **Data storage:** UserDefaults (local-only, no server, no accounts)
- **App type:** `NSApplication` with `NSStatusItem` (menu bar) and standard `NSWindow`
- **State management:** Single `TimerManager` (ObservableObject) drives both the menu bar and window views — one source of truth

## Interfaces

### Menu Bar

An `NSStatusItem` with a popover dropdown. Always accessible.

**Menu bar icon:**
- Small strawberry emoji inside a thin progress ring
- Idle: strawberry, no ring
- Focus: strawberry inside a filling red/orange progress ring
- Break: ring color shifts to green/teal
- Timer ended: icon pulses briefly, then settles into idle state (timer stops, does not auto-advance after cycle completion)
- Active countdown text (e.g. `18:42`) shown next to the icon during sessions

**Dropdown popover contents:**
- Mini double-ring timer (same visualization as main window, scaled down)
- Current time remaining and phase label (e.g. "Focus · 3 of 4")
- Pause / Skip controls
- Preset quick-switch row (e.g. Classic | Deep Work | Sprint)
- "Open Window" link to bring up the main window

### Main Window

Tabbed layout with three tabs:

#### Timer Tab
- Full-size double-ring visualization:
  - **Inner ring:** current timer progress (gradient fill, red-to-orange)
  - **Outer ring:** pomodoro cycle progress (segmented, shows N of M completed)
- Digital time display centered inside the rings
- Current phase label and cycle count (e.g. "Focus · 3 of 4")
- Pause / Skip controls
- "Next: Short Break" indicator

#### Presets Tab
- List of available presets with active preset highlighted
- 3 built-in presets:
  - **Classic:** 25 min focus / 5 min short break / 15 min long break / 4 cycles
  - **Deep Work:** 50 min focus / 10 min short break / 20 min long break / 3 cycles
  - **Short Sprint:** 15 min focus / 3 min short break / 10 min long break / 4 cycles
- Custom preset creation: user sets focus duration, short break, long break, and cycle count (max 24 hours per duration, min 1 minute, cycle count 1–99)
- Custom presets stored in UserDefaults
- Edit/delete custom presets via contextual menu or swipe-to-delete

#### Settings Tab
- **Notifications section:** three independent toggles:
  - System notifications (macOS banners via `UNUserNotificationCenter`)
  - Sound (chime/bell on phase transitions)
  - Visual (menu bar icon pulse on transitions)
- **Appearance section:** follow system light/dark mode or manual override
- **General section:**
  - Start at login toggle
  - Keep window on top toggle
- **About section:** version info

## Timer System

### Core Engine (`TimerManager`)
- ObservableObject shared across menu bar and window views
- Tracks: current phase, time remaining, current pomodoro number, active preset
- Publishes state changes so both UIs update in sync

### Pomodoro Cycle Flow
1. Focus → short break → focus → short break → ... → after Nth focus → long break
2. After long break completes, timer stops and returns to idle (does not loop automatically)
3. Auto-advances between phases within a cycle (notification fires at each transition)
4. User actions: pause, resume, skip to next phase, reset cycle, start new cycle from idle

### Preset System
- Preset model: focus duration, short break duration, long break duration, cycle count, name
- 3 built-in presets (not editable, not deletable)
- User-created custom presets (editable, deletable)
- Quick-switchable from both menu bar dropdown and Presets tab
- Switching presets during an active session shows a confirmation dialog ("This will reset your current session. Continue?") before resetting

## Notifications

Three independent, toggleable channels:

1. **System notifications:** macOS banner via `UNUserNotificationCenter` on phase transitions (e.g. "Focus complete! Time for a break.")
2. **Sound:** Short chime/bell sound effect. Bundle a clean default sound.
3. **Visual:** Menu bar icon pulses/changes state on transition. Double-ring animates smoothly (fill/reset).

## Visual Design

- **Color scheme:**
  - Focus: warm gradient (red `#ff6b6b` to orange `#ff8e53`)
  - Break: teal/green (`#4ecdc4`)
  - Dark theme: `#1a1a2e` base, light text
  - Light theme: light background, dark text, same accent colors
  - Appearance toggle in Settings: System (follows macOS), Light, or Dark
- **Icon:** Strawberry, sized to fit neatly inside the menu bar progress ring
- **Typography:** System font, lightweight for timer digits
- **Animations:** Smooth ring fill/reset transitions, icon pulse on timer end

## Out of Scope (for v1)

- Task list / to-do tracking
- Focus/distraction blocking
- Daily stats / history tracking
- Notes / journaling
- Break suggestions
- Calendar integration
- Cross-platform (Electron/Tauri) — may revisit later
- Sync / cloud storage
- App Store distribution (can be added later)
