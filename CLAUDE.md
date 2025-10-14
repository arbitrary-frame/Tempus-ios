# Tempus - Claude Context File

This file provides essential project context for Claude Code assistance. Last updated: October 2025.

---

## ⛔️ CRITICAL REMINDERS - READ FIRST

1. **NEVER work on `master` branch** - Always create feature branch first (`git checkout -b feature/name`)
2. **ALWAYS use `iPhone 17` simulator** - iOS 26 does NOT have iPhone 15 (use iPhone 17, 17 Pro, 16e, 16, 16 Pro, iPhone Air)
3. **NEVER update CHANGELOG.md** until user approves changes before PR merge
4. **NEVER merge to master directly** - All merges via GitHub Pull Requests

---

## Common Bash Commands

### Build & Run
```bash
# Clean build
xcodebuild -project Tempus.xcodeproj -scheme "Tempus Dev" clean

# Build for iPhone 17 simulator (REQUIRED - iOS 26 compatible)
xcodebuild -project Tempus.xcodeproj -scheme "Tempus Dev" -destination 'platform=iOS Simulator,name=iPhone 17' build

# Build production scheme
xcodebuild -project Tempus.xcodeproj -scheme "Tempus" -destination 'platform=iOS Simulator,name=iPhone 17' build

# List available simulators
xcrun simctl list devices | grep "iPhone"

# Boot iPhone 17 simulator
xcrun simctl boot "iPhone 17"
```

### Git Workflow
```bash
# ALWAYS check branch first (must NOT be master)
git branch

# Create feature branch (if on master)
git checkout -b feature/descriptive-name

# Commit changes
git add .
git commit -m "Your message"

# Push feature branch
git push -u origin feature/branch-name

# Create PR via GitHub CLI
gh pr create --title "Title" --body "Description"
```

### Database Migration
```bash
# Run database migration script (when needed)
./migrate-database.sh
```

---

## Core Files & Structure

### Key Data Models
- `Tempus/Models/Exercise.swift` - Exercise definitions with muscle groups, tags, isUnilateral flag
- `Tempus/Models/WorkoutEntry.swift` - Logged workouts with embedded exercise data
- `Tempus/Models/WorkoutRoutine.swift` - Reusable workout templates with emoji icons
- `Tempus/Models/OnboardingState.swift` - User preferences (weekly goal, name, theme)
- `Tempus/Models/Supporting/WorkoutExerciseData.swift` - Exercise performance within workouts (sets, reps, weights)

### Important Utilities
- `Tempus/Utilities/HapticManager.swift` - Cached haptic feedback (generators pre-warmed)
- `Tempus/Utilities/ThemeManager.swift` - Light/dark mode handling
- `Tempus/Utilities/AppGroupUserDefaults.swift` - Shared UserDefaults for widgets (App Group: `group.com.tempus.shared`)
- `Tempus/Utilities/ExerciseTagConstants.swift` - Predefined exercise tags
- `Tempus/Utilities/AnalyticsHelper.swift` - Analytics calculations (volume, PRs, streaks)

### Core Views
- `Tempus/Views/Workouts/WorkoutsListView.swift` - Main landing page with weekly stats
- `Tempus/Views/Workouts/WorkoutLoggingView.swift` - Workout entry form
- `Tempus/Views/Exercises/ExercisesListView.swift` - Exercise library
- `Tempus/Views/Analytics/AnalyticsView.swift` - Analytics dashboard
- `Tempus/Views/Settings/SettingsView.swift` - App settings

### Widget Files
- `TempusWidget/WorkoutStatsProvider.swift` - Shared data provider for all widgets
- `TempusWidget/GoalProgressWidget.swift` - Circular progress ring widget
- `TempusWidget/CombinedStatsWidget.swift` - Medium widget with all stats

---

## Code Style Guidelines

### Swift 6 Concurrency
- Use `@MainActor` for UI-updating code
- Use `Task.detached` for background work (e.g., JSON export)
- SwiftData queries should use proper predicates

### SwiftUI Conventions
- Use `@Observable` macro for ViewModels (not `ObservableObject`)
- Use `.regularMaterial` and `.ultraThinMaterial` for Liquid Glass design
- Prefer `NavigationStack` over deprecated `NavigationView`
- Use `@AppStorage` or custom `@AppGroupStorage` for UserDefaults

### Design Patterns
- **Liquid Glass:** Use material backgrounds (`.regularMaterial`, `.ultraThinMaterial`)
- **Colors:** Orange accent (#FF8F3D), grayscale base, semantic system colors
- **Icons:** SF Symbols 7 throughout (never custom icons unless necessary)
- **Haptics:** Use `HapticManager.shared.trigger(.type)` for feedback
- **Animations:** Spring animations (`.spring(response: 0.3)`)

### UK Localization (IMPORTANT)
- Date format: DD/MM/YYYY (use `Locale(identifier: "en_GB")`)
- Weight: kg only (never lbs)
- Spelling: British English ("Visualisation", "Colour", "Organised")
- Numbers: Metric system only

---

## Repository Etiquette

### Branching Strategy (CRITICAL: Start Here for Every New Task)

**⛔️ BEFORE starting ANY new work, ALWAYS run these commands:**

```bash
# 1. Fetch latest from remote
git fetch origin

# 2. Switch to master (NEVER create branches from feature branches!)
git checkout master

# 3. Pull latest master
git pull origin master

# 4. NOW create your feature branch
git checkout -b feature/descriptive-name
```

**Key Rules:**
- **⛔️ NEVER commit to master** - Protected branch, all changes via PRs
- **⛔️ NEVER create feature branches from other feature branches** - Always branch from master
- **⛔️ ALWAYS verify you're on master first:** `git branch --show-current` should show "master"
- Branch naming: `feature/`, `fix/`, `refactor/`

### Pull Request Workflow (IMPORTANT: Follow These Steps)

**When you complete a task, ALWAYS create a PR immediately:**

1. **Build verification:** `xcodebuild -project Tempus.xcodeproj -scheme "Tempus Dev" -destination 'platform=iOS Simulator,name=iPhone 17' build`
2. **Create feature branch** (if not already on one): `git checkout -b feature/descriptive-name`
3. **Commit changes:** `git add . && git commit -m "message"` (include Claude Code co-authoring footer)
4. **Push branch:** `git push -u origin feature/branch-name`
5. **Create PR immediately:** `gh pr create --title "..." --body "..."`
6. **DO NOT update CHANGELOG.md yet** - Only after user approval
7. **Provide PR URL to user** so they can review and test
8. User reviews PR on GitHub
9. **After user approves:** Update CHANGELOG.md with changes
10. User merges PR via GitHub

**Key Points:**
- ⛔️ ALWAYS create PR when work is complete (don't wait for user to ask)
- ⛔️ NEVER update CHANGELOG.md before user approves PR
- ✅ Include comprehensive test plan in PR description
- ✅ Provide PR URL to user immediately after creation

### Commit Message Format
- `Add [feature]` - New functionality
- `Fix [issue]` - Bug fixes
- `Update [component]` - Improvements
- Include Claude Code co-authoring footer when applicable

---

## Testing Instructions

### Manual Testing (Primary Method)
- **NO UNIT TESTS** - User not comfortable with Swift testing yet
- Use `print("DEBUG: message")` liberally for debugging
- Mark temporary debug code with `// DEBUG:` comments
- Test on iPhone 17 simulator (iOS 26)

### Widget Testing
1. Build and run app on simulator
2. Long press home screen → Add widget
3. Add Tempus widgets
4. Log workout in app
5. Verify widgets update (may take a few seconds)
6. Tap widget → App opens to Workouts tab

### Key Test Cases
- Create workout with exercises
- Edit existing workout
- Create/edit workout routine
- Change weekly goal in Settings
- Export data (JSON share sheet)
- Import data (JSON file)
- Delete unused exercises (allowed)
- Try to delete used exercises (should archive instead)

---

## Project-Specific Context

### iOS 26 Specifics
- **Minimum deployment:** iOS 26.0+
- **Simulator devices:** iPhone 17, iPhone 17 Pro, iPhone 16e, iPhone 16, iPhone Air (NO iPhone 15 - doesn't exist in iOS 26)
- **Design language:** Liquid Glass (translucent materials, depth effects)
- **SF Symbols:** Version 7 (6,900+ icons with Draw animations)

### Data Sharing
- **App Group:** `group.com.tempus.shared` (enables widget data access)
- **SwiftData:** Shared container for app + widgets
- **UserDefaults:** Use `AppGroupStorage` property wrapper for widget-accessible settings

### Unilateral Exercise Logic (IMPORTANT)
- Exercises tagged with "unilateral" (e.g., dumbbell exercises, single-leg)
- When calculating volume, weight is doubled: `totalWeight = weight * 2 * reps * sets`
- Rationale: User logs weight per hand/leg, but lifts with both sides
- `isUnilateral` field stored in `WorkoutExerciseData` (snapshot at logging time)
- Update `isUnilateral` from current Exercise tags when editing workouts

### Widget Refresh Pattern
```swift
import WidgetKit

// After saving workout:
WidgetCenter.shared.reloadAllTimelines()
```

### HapticManager (Performance Critical)
- Generators are cached and pre-prepared in `init`
- Reduces latency by 40-50ms
- Pattern:
  ```swift
  HapticManager.shared.trigger(.success)
  HapticManager.shared.trigger(.light)
  HapticManager.shared.trigger(.warning)
  ```

---

## Common Patterns & Helpers

### Fetching Workouts for Current Week
```swift
let calendar = Calendar.current
let startOfWeek = calendar.startOfWeek(for: Date())
let endOfWeek = calendar.date(byAdding: .day, value: 7, to: startOfWeek)!

let predicate = #Predicate<WorkoutEntry> { workout in
    workout.workoutDate >= startOfWeek && workout.workoutDate < endOfWeek
}
```

### Weekly Goal Access
```swift
// In Views:
@AppGroupStorage("weeklyWorkoutGoal") private var weeklyGoal = 3
```

### Deep Linking
- URL scheme: `tempus://`
- All widgets open to Workouts tab: `tempus://workouts`

### Data Export
- JSON format via Share Sheet
- Export includes: exercises, routines, workouts, settings
- Background thread processing:
  ```swift
  Task.detached {
      let jsonData = try JSONEncoder().encode(data)
      await MainActor.run {
          // Present share sheet
      }
  }
  ```

---

## Build Schemes

### Tempus Dev
- Development build
- Debug configuration
- Additional logging enabled
- Use for daily development

### Tempus
- Production build
- Release configuration
- Optimized performance
- Use for PR final checks

---

## Known Gotchas

1. **iPhone 15/16 NOT available** - iOS 26 has iPhone 16e, 17, Air instead
2. **CHANGELOG timing** - Only update after user approves PR, not before
3. **Master branch protection** - Cannot push directly, must use PRs
4. **Widget data lag** - Widgets update at midnight + after workout save (not real-time)
5. **Exercise deletion** - Exercises used in workouts are archived (not deleted)
6. **Unilateral weight doubling** - Apply 2x multiplier for volume calculations
7. **UK date format** - Always use `Locale(identifier: "en_GB")` for dates

---

## When to Ask User

### Ask First If:
- Significant deviation from requirements-ios.md
- Architectural changes not in spec
- UI/UX differs from Liquid Glass patterns
- Adding new dependencies/frameworks
- Uncertain about design interpretation

### Safe to Proceed:
- Implementation details within requirements
- Variable/function naming
- Code organization
- Standard iOS patterns
- Minor UI adjustments matching design

---

## References

- Full specification: `requirements-ios.md`
- Development workflow: `.claude/workflow.md`
- Platform context: `.claude/project-context.md`
- Roadmap: `ROADMAP.md`
- Widget setup: `WIDGET_BUILD_INSTRUCTIONS.md`
- Version history: `CHANGELOG.md`

---

## Quick Checklist When Completing Work

**When you finish implementing a task, follow this checklist:**

- [ ] **⛔️ NOT on master branch** (`git branch` shows feature branch)
- [ ] **⛔️ Builds successfully with iPhone 17 simulator**
- [ ] Code follows requirements-ios.md
- [ ] Debug prints added where helpful (marked with `// DEBUG:`)
- [ ] Changes committed with clear message + Claude Code footer
- [ ] Feature branch pushed to GitHub: `git push -u origin branch-name`
- [ ] **⛔️ PR CREATED IMMEDIATELY** via `gh pr create` (don't wait for user to ask!)
- [ ] **PR URL provided to user** in your response
- [ ] CHANGELOG.md NOT updated yet (only after user approval)

**Remember:** Always create the PR as soon as work is complete. The user expects a PR to review and test.

---

Built with 🧡 by Ronak Pattani with [Claude Code](https://claude.com/claude-code)
