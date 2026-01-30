# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

ReFomo is a native iOS Pomodoro timer app built with SwiftUI, featuring session tracking, iCloud sync, and comprehensive accessibility support. The app targets iOS 17.0+ and follows Apple's Human Interface Guidelines.

## Build & Test Commands

```bash
# Open project in Xcode
open refomo/refomo.xcodeproj

# Build from command line
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo -configuration Debug build

# Run tests
xcodebuild test -project refomo/refomo.xcodeproj -scheme refomo -destination 'platform=iOS Simulator,name=iPhone 15'

# Build for release
xcodebuild -project refomo/refomo.xcodeproj -scheme refomo -configuration Release build
```

**Note:** This project does not use CocoaPods or Swift Package Manager. It's a standalone Xcode project with no external dependencies.

## Architecture

### MVVM Pattern with SwiftUI

- **Models** (`Models/`): Codable data structures (e.g., `PomodoroRecord`)
- **ViewModels** (`ViewModels/`): `@MainActor` classes with `@Published` properties for state management
- **Views** (`Views/`): SwiftUI declarative UI components
- **Services** (`Services/`): Singleton business logic (storage, sound/haptics)

### Key Architectural Patterns

**Timer State Machine** (`PomodoroViewModel.swift:12`):
```
idle → running → paused ⟲ running
         ↓ (time expires)
    completed → RecordView → idle
```

**Data Flow**:
1. User interaction → View
2. View calls ViewModel method
3. ViewModel updates `@Published` properties
4. SwiftUI automatically re-renders View
5. ViewModel calls Service for side effects (storage, sound)

**iCloud Sync** (`StorageService.swift:29-36`):
- Uses `FileManager.url(forUbiquityContainerIdentifier:)` for iCloud Documents
- Falls back to local storage if iCloud unavailable
- Container ID: `iCloud.com.presence042.refomo`
- Data stored as JSON in `Documents/Refomo/records.json`

**Record Update Pattern** (`StorageService.swift:65-71`):
- `update(record:)` modifies existing `PomodoroRecord` by UUID match
- Loads full record list, finds matching ID, updates, then saves
- Used by `RecordViewModel` when updating in-progress sessions
- Example: `RecordViewModel.saveRecord()` uses this when `existingRecordId` is set

### ViewModel Responsibilities

All ViewModels must:
- Be marked with `@MainActor` to ensure UI updates on main thread
- Use `@Published` for observable state
- Handle business logic coordination (not implementation)
- Delegate side effects to Services (never perform I/O directly)

Example pattern from `PomodoroViewModel.swift:75-84`:
```swift
func startTimer() {
    // 1. Update state
    startTime = Date()
    timerState = .running

    // 2. Delegate side effects to services
    setScreenAwake(true)
    SoundService.shared.playHaptic(.light)

    // 3. Start internal mechanisms
    startInternalTimer()
}
```

### Design System (`DesignSystem.swift`)

**Centralized Design Tokens**:
- `Spacing`: 8pt grid system (xs=4, sm=8, md=16, lg=20, xl=24, xxl=32)
- `CornerRadius`: Semantic radius values (small=8, medium=10, large=12, sheet=16)
- `ShadowStyle`: HIG-compliant elevation levels (subtle, card)
- `AnimationConfig`: Reduce Motion aware animations

**Color Semantics**:
- Primary accent: `Color.pomodoroAccent` (from Asset Catalog, not defined in code)
- Semantic colors use UIKit dynamic colors (`UIColor.label`, `secondarySystemBackground`, etc.)
- Never hardcode colors; always use semantic color names

**Accessibility First**:
- Use `@ScaledMetric` for all fixed sizes to support Dynamic Type
- Check `AnimationConfig.reduceMotion` before animating
- All animations should be conditionally applied via `.animateIfAllowed()` modifier

## Code Style & Conventions

### Language & Comments

- **UI text**: Korean (user-facing strings)
- **Code**: English (variable names, function names, comments)
- **Comments**: Korean comments allowed for complex business logic

### Swift API Guidelines

Follow [Swift API Design Guidelines](https://swift.org/documentation/api-design-guidelines/):
- Use clear, descriptive names (e.g., `updateSelectedMinutes(from:)` not `update(_:)`)
- Omit needless words (e.g., `removeAll()` not `removeAllItems()`)
- Name methods by side effects: `playHaptic()`, `saveRecords()` (imperative)
- Name computed properties by what they are: `displayTime`, `progress` (noun)

### SwiftUI Best Practices

- Extract reusable components to `Views/Components/`
- Use `@Environment` for system preferences (colorScheme, reduceMotion, etc.)
- Prefer composition over inheritance
- Keep View bodies under 10 lines; extract subviews otherwise

**Gesture Patterns** (`PomodoroView.swift:130-159`):
- Use `DragGesture()` for directional swipes (e.g., memo panel open/close)
- Swipe direction convention: **left swipe (negative translation)** opens right-side panels, **right swipe (positive translation)** closes them
- Use `.updating($dragOffset)` with `@GestureState` for real-time drag preview before commitment
- Swipe thresholds: 50pt or greater to avoid accidental triggers
- **Velocity-based quick swipes**: Use `value.predictedEndTranslation` to detect fast flicks (>100pt velocity)
  ```swift
  let velocity = value.predictedEndTranslation.width - value.translation.width
  let isQuickSwipe = abs(velocity) > 100
  if (value.translation.width < -threshold || (isQuickSwipe && velocity < 0)) { ... }
  ```
- Animation: Use `.interactiveSpring(response: 0.35, dampingFraction: 0.85)` for gesture-driven animations
- Always check motion preferences: `reduceMotion ? nil : .interactiveSpring(...)`
- Provide haptic feedback for gesture completion: `SoundService.shared.playHaptic()`
- Always provide button alternatives for accessibility (FAB for non-gesture users)
- Gestures can be state-conditional: `(timerState == .running || timerState == .completed) ? DragGesture() : nil`

**Long-Press Session Dialog** (`PomodoroView.swift:231-251`):
- Long-press on timer circle during running/paused/completed shows `.confirmationDialog()` with "저장"/"삭제" options
- State guard: Only trigger when `timerState != .idle`
- Use `role: .destructive` for destructive button styling (e.g., "삭제")
- Haptic: `.medium` on gesture trigger; dialog handles its own button haptics
- Helper `setupRecordViewModelForSave()` prepares RecordViewModel state — shared with completeButton
- Accessibility hint: "길게 눌러 세션 종료 옵션"

**Modal Dismissal with TabView** (`HistoryView.swift:22-27`, `ContentView.swift:23`):
- Race condition: Sheet `onDismiss` callback fires **during** dismissal animation, not after completion
- Problem: When `.scrollDisabled()` is tied to sheet state, setting state to `false` in `onDismiss` enables TabView scrolling mid-animation, causing swipe gestures to trigger unwanted page switches
- Solution: Delay state update in `onDismiss` to allow animation to complete:
  ```swift
  .sheet(item: $item, onDismiss: {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.35) {
          isSheetPresented = false
      }
  })
  ```
- Timing: 0.35 seconds accounts for standard sheet dismissal animation (~0.3s) plus buffer
- Pattern: Use binding to disable TabView scrolling while sheet is presented: `.scrollDisabled(isSheetPresented)`
- Anti-pattern: Never set `scrollDisabled` binding to `false` synchronously in `onDismiss`

### Performance Patterns

**Service Singletons** (`SoundService.swift:9-24`):
- Cache expensive objects (e.g., haptic generators, JSON encoder/decoder)
- Call `.prepare()` on haptic generators during initialization for lower latency
- Use `private(set)` or `private` for singleton state

## Commit Convention

```
[type] Subject (max 50 characters)

[feat]     - New feature
[fix]      - Bug fix
[refactor] - Code refactoring (no behavior change)
[test]     - Add/modify tests
[docs]     - Documentation
[chore]    - Build, dependencies, configuration
```

Examples:
```
[feat] Add overtime tracking to timer
[fix] Prevent timer from continuing after reset
[refactor] Extract focus level buttons to component
```

## iCloud Configuration

When setting up a new development environment:

1. Update container ID in `StorageService.swift:13` to your own:
   ```swift
   private let containerID = "iCloud.com.yourteam.refomo"
   ```

2. Enable iCloud capability in Xcode:
   - Select target → Signing & Capabilities
   - Add iCloud capability
   - Enable "iCloud Documents"
   - Select/create container matching the ID above

3. Test iCloud sync:
   - Run on two devices with same Apple ID
   - Create a session on device A
   - Verify it appears on device B (may take 10-30 seconds)

## File Organization

```
refomo/refomo/
├── Models/              # Data structures (Codable, Identifiable)
├── ViewModels/          # @MainActor ObservableObjects
├── Views/               # SwiftUI views
│   └── Components/      # Reusable UI components
├── Services/            # Singleton business logic
├── DesignSystem.swift   # Design tokens & view extensions
├── refomoApp.swift      # App entry point
└── ContentView.swift    # Root view with TabView
```

**File Naming**: Match the primary type name (e.g., `PomodoroViewModel.swift` contains `class PomodoroViewModel`)

## Accessibility Implementation

This app prioritizes accessibility. When adding features:

1. **VoiceOver**: Add `.accessibilityLabel()` and `.accessibilityHint()` to custom controls
2. **Dynamic Type**: Use `@ScaledMetric` for all fixed dimensions
3. **Reduce Motion**: Use `AnimationConfig.reduceMotion` or `.animateIfAllowed()` modifier
4. **Color Contrast**: Use semantic colors from `DesignSystem.swift`
5. **Haptic Feedback**: Provide haptic alternatives to visual-only feedback

Example from `RecordView.swift:19-21`:
```swift
@ScaledMetric(relativeTo: .title2) private var focusButtonSize: CGFloat = 50
@ScaledMetric(relativeTo: .headline) private var saveButtonHeight: CGFloat = 50
```

## Timer Implementation Details

**Screen Wake Lock** (`PomodoroViewModel.swift:154-156`):
- Prevents screen from sleeping during active timer
- Always disable when timer stops/pauses to preserve battery
- Use `UIApplication.shared.isIdleTimerDisabled`

**Time Tracking**:
- `plannedDuration`: User's selected time in seconds
- `actualDuration`: Planned + overtime (stored in `PomodoroRecord`)
- `overSeconds`: Time elapsed after completion (for overtime tracking)

**Pending Record Pattern** (`PomodoroViewModel.swift:14-19, 100-105`):
- Timer completion creates a `PendingRecord` (not saved yet)
- User fills focus level, reflection, memo in `RecordView`
- `RecordViewModel` converts `PendingRecord` → `PomodoroRecord` and saves
- This separation prevents incomplete records in storage

**In-Progress Session Pattern** (`PomodoroViewModel.swift:29-31, 121-133`):
- `actualDuration` is `Int?` (Optional) to distinguish session states:
  - `nil` = session still running (memo saved early, not yet completed)
  - `Int` value = session completed with actual duration
- `currentRecordId` tracks UUID of in-progress record for subsequent updates
- Flow:
  1. User swipes left during timer → memo panel opens (from right edge)
  2. User writes memo and swipes right → partial record created with `actualDuration: nil`
  3. Timer completes → `actualDuration` updated to `plannedDuration + overSeconds`
  4. User taps "완료" → `RecordView` updates existing record with focusLevel/reflection
- Multiple memo updates during session update same record (no duplicates)
- **Session termination options** (long-press dialog, `PomodoroViewModel.swift:180-194`):
  - **Save** (`saveSessionEarly()`): Updates partial record's `actualDuration` to elapsed time, then shows RecordView
  - **Delete** (`deleteSession()`): Calls `resetTimer()` which cleans up orphaned partial records via `StorageService.delete(id:)`
  - `currentActualDuration` computed property unifies duration calculation: `plannedDuration - remainingSeconds` (running/paused) or `plannedDuration + overSeconds` (completed)
  - **Orphan cleanup**: `resetTimer()` deletes partial record if `currentRecordId` is set before clearing state
  - **Safety**: `finishSession()` sets `currentRecordId = nil` BEFORE calling `resetTimer()`, preventing deletion of successfully saved records
