# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project Overview

HabbitApp is an iOS habit tracking app built with SwiftUI and SwiftData (iOS 17+). It uses a unique **3-level goal system** (MINI/MORE/MAX) and **20-day cycle** approach to make habit formation more flexible and sustainable.

**Core Philosophy**: "It's not your fault if you quit after 3 days" - the app encourages users to complete 15 out of 20 days (75%) rather than demanding perfection.

## Build Commands

```bash
# Build for simulator
xcodebuild -project HabbitApp.xcodeproj \
  -scheme HabbitApp \
  -sdk iphonesimulator \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  build

# Clean build
xcodebuild clean -project HabbitApp.xcodeproj -scheme HabbitApp

# Run specific widget size (Small/Medium/Large)
# Use Xcode GUI: Select HabbitAppWidget scheme → Run → Choose widget size

# Run tests
xcodebuild test -project HabbitApp.xcodeproj \
  -scheme HabbitApp \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

## Architecture

### MVVM Pattern
- **Models**: SwiftData models with `@Model` macro
- **ViewModels**: `@Observable` classes (iOS 17+)
- **Views**: SwiftUI views

### Data Layer (SwiftData)

**Key Models:**
- `Habit`: Main habit entity with 20-day cycle tracking
  - `currentCycle: Int` - Current cycle number (1-indexed)
  - `completedCycles: Int` - Successfully completed cycles (15+ days)
  - `miniGoal`, `moreGoal`, `maxGoal` - Three-level goals
- `DailyRecord`: Daily completion record
  - `level: CompletionLevel` - MINI/MORE/MAX/none
  - `memo: String?` - Optional daily note
- `CompletionLevel`: Enum for completion levels

**Important**: Models are shared between main app and widget. When modifying models, ensure both targets compile.

### 20-Day Cycle System

The app's unique feature - habits run in 20-day cycles:
- Users need to complete **15 out of 20 days** to succeed
- Cycles auto-advance after 20 days
- All cycle logic is in `HabitViewModel`:
  - `getCurrentCycleStartDate()` - Calculates cycle start based on `startDate`
  - `getCurrentCycleDay()` - Returns 1-20
  - `getCurrentCycleRecords()` - Returns array of 20 `DailyRecord?`
  - `checkAndUpdateCycleCompletion()` - Must be called on app launch

**Date calculation logic:**
```swift
let daysSinceStart = Calendar.current.dateComponents([.day], from: startDate, to: Date()).day ?? 0
let currentCycleIndex = daysSinceStart / 20
let cycleStartDate = Calendar.current.date(byAdding: .day, value: currentCycleIndex * 20, to: startDate)
```

Always use `Calendar.current.startOfDay()` for date comparisons to avoid timezone issues.

### Widget Architecture

Three widget sizes, all in `HabbitAppWidget.swift`:
- **Small**: Single habit with circular progress (20-day completion)
- **Medium**: Two habits with progress bars
- **Large**: 20-day calendar grid (4×5) showing completion status per day

**Widget Data Flow:**
1. `Provider.fetchHabits()` reads from SwiftData
2. Creates `HabitWidgetData` with `cycleRecords: [CompletionLevel?]` (20 items)
3. Timeline updates at midnight via `Timeline(entries:policy:.after(midnight))`

**Note**: Widget and app currently use **separate SwiftData containers** (App Group not configured). Both use default `ModelConfiguration` without `groupContainer`.

## Color System

Level colors (used throughout app and widgets):
- **MINI**: `#B8E6D5` / `#8FD5C1` (mint)
- **MORE**: `#7DB3E8` / `#5A9BD4` (blue)
- **MAX**: `#B48FD9` / `#9B6FC5` (purple)

Progress indicators use color coding:
- Red: 0-25% complete
- Orange: 25-50%
- Blue: 50-75%
- Green: 75-100%

## Common Development Patterns

### Adding a New ViewModel Method

```swift
// In HabitViewModel.swift
func yourMethod(for habit: Habit) -> ReturnType {
    // Always use Calendar.current.startOfDay() for dates
    let calendar = Calendar.current
    let today = calendar.startOfDay(for: Date())

    // Access records through habit.records
    // Save changes with modelContext.save()
}
```

### Modifying SwiftData Models

1. Add property to model class
2. Update `init()` with default value
3. Rebuild both targets: HabbitApp **and** HabbitAppWidget
4. If widget uses the property, update `HabitWidgetData` and `fetchHabits()`

### Widget Development

Test widgets using Xcode Canvas (fastest):
```swift
#Preview(as: .systemLarge) {
    HabbitAppWidget()
} timeline: {
    // Preview data
}
```

Or run widget scheme from Xcode to see on simulator home screen.

## Important Constraints

- **iOS 17.0+ only** - Uses SwiftData and iOS 17 SwiftUI features
- **1-3 habits recommended** - UI optimized for small number of focused habits
- **20-day cycle is fixed** - Core to the app's philosophy, not configurable
- **Widget updates at midnight** - Cannot force refresh more frequently

## Testing Widget Data

To test widget with real data:
1. Run main app (HabbitApp scheme)
2. Add habits and complete some days
3. Run widget (HabbitAppWidget scheme)
4. Widget reads from SwiftData automatically

If widget shows "앱에서 습관을 추가하세요", the widget cannot find habits - usually means no habits exist in database.

## References

- See `20DAY_CYCLE_GUIDE.md` for complete cycle system documentation
- See `README.md` for user-facing features
- Inspired by minimoremax.com habit tracking philosophy
