# Tempus Widgets - Build Instructions

## What Was Done

### 1. ✅ Project Configuration
- Added App Groups capability to both Tempus and TempusWidget targets with identifier: `group.com.tempus.shared`
- Configured SwiftData to use shared App Group container for data sharing
- Added URL scheme `tempus://` for deep linking
- Shared SwiftData models (Exercise, WorkoutEntry, WorkoutRoutine, OnboardingState) with widget target

### 2. ✅ Created 4 Widgets

| Widget | Size | Description |
|--------|------|-------------|
| **GoalProgressWidget** | Small (2×2) | Circular progress ring showing workouts completed vs weekly goal |
| **ExercisesWidget** | Small (2×2) | Number of exercises completed this week |
| **WeightWidget** | Small (2×2) | Total weight lifted this week (in kg) |
| **CombinedStatsWidget** | Medium (4×2) | All three stats in horizontal row |

### 3. ✅ Key Features Implemented
- All widgets use shared SwiftData via App Group
- Single data provider (`WorkoutStatsProvider`) for all widgets
- Daily timeline updates (refreshes at midnight)
- Immediate widget refresh after saving workouts
- All widgets tap to open app to Workouts tab
- iOS 26 Liquid Glass design with `.widgetAccentable()`
- Empty state handling

### 4. ✅ Files Created/Modified

**New Widget Files:**
- `TempusWidget/WorkoutStatsEntry.swift` - Timeline entry model
- `TempusWidget/WorkoutStatsProvider.swift` - Data provider with SwiftData queries
- `TempusWidget/GoalProgressWidget.swift` - Workout goal progress widget
- `TempusWidget/ExercisesWidget.swift` - Exercises count widget
- `TempusWidget/WeightWidget.swift` - Weight total widget
- `TempusWidget/CombinedStatsWidget.swift` - All stats in one widget
- `Tempus/Utilities/AppGroupUserDefaults.swift` - Helper for App Group UserDefaults

**Modified Files:**
- `TempusApp.swift` - App Group configuration + deep link handling
- `ContentView.swift` - Tab selection binding for deep links
- `WorkoutLoggingView.swift` - Widget refresh after saving
- `TempusWidgetBundle.swift` - Widget bundle with 4 widgets
- `WorkoutsListView.swift` - Use AppGroupStorage
- `SettingsView.swift` - Use AppGroupStorage
- `AnalyticsView.swift` - Use AppGroupStorage
- `WorkoutCalendarView.swift` - Use AppGroupStorage
- `OnboardingState.swift` - Use shared UserDefaults

## How to Build & Test

### Step 1: Add New Files to Xcode Project

You need to add the new widget files to the TempusWidget target in Xcode:

1. Open Xcode
2. Right-click on `TempusWidget` folder in Project Navigator
3. Select **Add Files to "Tempus"**
4. Navigate to `/Users/ronakpattani/code/arbitrary-frame/Tempus/TempusWidget/`
5. Select these files:
   - `WorkoutStatsEntry.swift`
   - `WorkoutStatsProvider.swift`
   - `GoalProgressWidget.swift`
   - `ExercisesWidget.swift`
   - `WeightWidget.swift`
   - `CombinedStatsWidget.swift`
6. Make sure **Target Membership** is set to `TempusWidget` (not Tempus)
7. Click **Add**

Also add the helper to main app:
1. Right-click on `Tempus/Utilities` folder
2. **Add Files to "Tempus"**
3. Select `AppGroupUserDefaults.swift`
4. Target: `Tempus` ✅

### Step 2: Verify App Groups Configuration

1. Select **Tempus** target → **Signing & Capabilities**
2. Verify **App Groups** capability exists with:
   - ☑️ `group.com.tempus.shared`

3. Select **TempusWidget** target → **Signing & Capabilities**
4. Verify **App Groups** capability exists with:
   - ☑️ `group.com.tempus.shared`

### Step 3: Verify URL Scheme

1. Select **Tempus** target → **Info** tab
2. Expand **URL Types**
3. Verify entry exists:
   - Identifier: `com.tempus.app`
   - URL Schemes: `tempus`

### Step 4: Build the App

1. Select scheme: **Tempus** (or **TempusWidget** to test widget only)
2. Select target device (iPhone or Simulator running iOS 26+)
3. Click **Product** → **Clean Build Folder** (⇧⌘K)
4. Click **Product** → **Build** (⌘B)
5. Fix any build errors if they appear

Common build errors and fixes:
- **"No such module 'WidgetKit'"** → Make sure WidgetKit is imported
- **"Cannot find 'AppGroupStorage'"** → Make sure `AppGroupUserDefaults.swift` is added to Tempus target
- **"No such module 'SwiftData'"** → Make sure SwiftData models are shared with widget target

### Step 5: Run & Add Widgets

1. Click **Run** (⌘R) to launch app on device/simulator
2. On your device home screen, **long press** empty space
3. Tap **+** button (top-left) to add widget
4. Search for "Tempus"
5. You should see 4 widget options:
   - **Workout Goal** (small)
   - **Exercises This Week** (small)
   - **Weight This Week** (small)
   - **Weekly Stats** (medium)
6. Drag any widget to home screen
7. Tap **Done**

### Step 6: Test Functionality

**Test Widget Data:**
1. Open Tempus app
2. Log a workout with some exercises
3. Return to home screen
4. Widgets should update within a few seconds

**Test Deep Linking:**
1. Tap on any widget
2. App should open to Workouts tab (first tab)

**Test Goal Progress:**
1. In app, go to Settings
2. Change "Weekly Workout Goal" to 3
3. Log 2 workouts this week
4. Goal Progress Widget should show "2/3" with partial ring
5. Log 1 more workout
6. Ring should turn green and show "3/3"

## Troubleshooting

### Widgets Show No Data

**Solution 1: Reset App Group Container**
```bash
# Delete app from device/simulator
# Delete all widgets
# Clean build folder in Xcode
# Rebuild and reinstall
```

**Solution 2: Check App Group Identifier**
- Verify both targets use exact same identifier: `group.com.tempus.shared`
- No typos, spaces, or capitalization differences

### Widgets Not Updating

**Solution:**
1. Check if `WidgetCenter.shared.reloadAllTimelines()` is called after saving workout
2. Try manually refreshing: Long press widget → **Edit Widget** → Back out
3. Check Console logs in Xcode for widget errors

### Deep Linking Not Working

**Solution:**
1. Verify URL scheme in Info.plist: `tempus`
2. Check `TempusApp.swift` has `.onOpenURL { url in handleDeepLink(url) }`
3. Test with Safari: Open Safari, type `tempus://workouts`, press Go

### Build Errors

**"Cannot find type 'AppGroupStorage'"**
```
Solution: Make sure AppGroupUserDefaults.swift is added to Tempus target (not widget)
```

**"Cannot find type 'Exercise' in scope"**
```
Solution: In Xcode, select Exercise.swift → File Inspector → Check TempusWidget in Target Membership
```

**"Cannot find module 'WidgetKit'"**
```
Solution: Add `import WidgetKit` at top of file
```

## Widget Specs

### Goal Progress Widget (Small)
- Displays circular progress ring
- Text: "X/Y Workouts"
- Color: Accent (blue) until goal reached, then green
- Updates: Daily at midnight + after saving workouts

### Exercises Widget (Small)
- Icon: `list.bullet.clipboard`
- Value: Number of unique exercises
- Label: "Exercises"
- Updates: Daily at midnight + after saving workouts

### Weight Widget (Small)
- Icon: `dumbbell.fill` (orange)
- Value: Total weight lifted (formatted as "450" or "1.2k")
- Label: "kg"
- Updates: Daily at midnight + after saving workouts

### Combined Stats Widget (Medium)
- Shows all 3 stats in horizontal row
- Same design as top of Workouts page
- Material background for each card
- Updates: Daily at midnight + after saving workouts

## What Users Can Do

1. **Add widgets to home screen** - Choose from 4 options
2. **See weekly stats at a glance** - No need to open app
3. **Tap widget to open app** - Quick access to workouts
4. **Customize with multiple widgets** - Mix and match

## Known Limitations

- Widgets update once per day (midnight) + when workout saved
- No configuration options (by design - simple)
- All widgets open to Workouts tab only
- Requires iOS 26+
- Data shared via App Group (no iCloud sync)

## Future Enhancements (Not Implemented)

- Lock screen widgets (accessoryCircular, accessoryRectangular)
- Large widget with charts
- Interactive widgets with buttons
- Live Activities during workout
- Configurable time periods (week/month/year)
- Individual stat deep links
- Widget configuration to choose stats

---

## Testing Checklist

- [ ] App builds without errors
- [ ] Widgets appear in widget gallery
- [ ] All 4 widgets show placeholder data
- [ ] Widgets show real data after logging workout
- [ ] Tapping widget opens app to Workouts tab
- [ ] Goal progress ring shows correct progress
- [ ] Exercises count is accurate
- [ ] Weight total is correct
- [ ] Weekly goal can be changed in Settings
- [ ] Widgets update when goal changes
- [ ] Widgets refresh after saving workout
- [ ] Light mode looks good
- [ ] Dark mode looks good
- [ ] Empty state (no workouts) handled gracefully

---

Built with ❤️ for iOS 26 using SwiftUI, SwiftData, and WidgetKit.
