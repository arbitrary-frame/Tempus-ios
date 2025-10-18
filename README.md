# Tempus 🏋️

A minimalist iOS workout tracking app built with Swift 6, SwiftUI, and SwiftData.

[![iOS](https://img.shields.io/badge/iOS-26.0+-black.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)

---

## 📱 App Store Description

A powerful yet simple workout tracker focused on what matters: tracking your progress without the noise.

Tempus is designed for lifters who want intelligent workout tracking without subscriptions, social features, or complicated interfaces. See your previous performance while logging exercises, track personal records automatically, and monitor your consistency with beautiful home screen widgets.

**Core Features:**
• **Smart Logging** - See your last workout's numbers while logging. Tap to copy previous sets and stay focused on progressive overload.
• **30+ Preset Exercises** - Organized by muscle groups (chest, back, legs, shoulders, arms, core, cardio, full body) with support for custom exercises.
• **Workout Routines** - Save your favourite workouts as templates with custom emoji icons for quick logging.
• **Drop Set Support** - Log multiple weight/rep pairs per set for advanced training techniques.
• **Personal Records** - Automatic PR tracking by exercise with historical data.
• **Weekly Goals** - Set workout frequency goals and track consistency with progress rings.
• **Home Widgets** - Beautiful iOS 26 widgets showing your weekly stats at a glance.
• **Workout Calendar** - Visual calendar of your training history with colour-coded consistency.
• **Analytics Dashboard** - Week-over-week comparisons, volume progression, and streak tracking.
• **Complete Privacy** - Your data never leaves your device. No account, no tracking, no ads.
• **Export/Import** - Full JSON backup of all your workout data whenever you need it.

**Built for iOS 26:**
• Liquid Glass design language with translucent materials
• SF Symbols 7 icons throughout
• Haptic feedback on every interaction
• Dark mode optimized (light mode available)
• UK-first design (metric units, DD/MM/YYYY dates)

**Perfect for:**
• Strength training and progressive overload
• Bodybuilding and hypertrophy training
• Powerlifting programs
• General fitness and consistency tracking

No subscriptions. No social features. No noise. Just you and your progress.

---

## ✨ Features

### 🏋️ Smart Workout Logging
- **Previous Performance Display** - See your last workout's sets, reps, and weights while logging
- **Tap to Copy** - Populate sets from previous workout with one tap
- **Drop Set Support** - Log multiple weight/rep pairs per set for advanced techniques
- **Exercise Notes** - Track how you felt or variations used
- **Unilateral Exercise Support** - Automatic weight doubling for dumbbell exercises
- **Workout History** - View and edit past workouts with fully preserved data

### 📚 Exercise & Routine Management
- **30+ Preset Exercises** - Pre-loaded exercises across 8 muscle groups
- **Custom Exercises** - Create your own with muscle group tags and SF Symbols
- **7 Preset Routines** - Push, Pull, Legs, Upper/Lower, Full Body templates
- **Custom Routines** - Save workouts as reusable templates with emoji icons
- **Exercise Archive** - Exercises used in workouts are archived, not deleted
- **Preset Browser** - Browse and add preset exercises and routines anytime

### 📊 Analytics & Insights
- **Personal Records** - Automatic PR tracking with date and exercise details
- **Weekly Goal Tracking** - Progress rings with celebration effects when goals met
- **Workout Calendar** - Visual calendar with colour-coded workout frequency
- **Volume Progression** - Track total weight lifted over time with trend charts
- **Streak Tracking** - Monitor consecutive weeks meeting your goals
- **Week-over-Week Stats** - Compare current week to previous with trend indicators
- **Exercise Detail Views** - Deep dive into performance history per exercise

### 📱 Home Screen Widgets (iOS 26)
- **Goal Progress Widget** (Small) - Circular ring showing workouts vs weekly goal
- **Exercises Widget** (Small) - Unique exercises performed this week
- **Weight Widget** (Small) - Total weight lifted this week in kg
- **Combined Stats Widget** (Medium) - All three stats in one compact widget
- **Auto-Updates** - Widgets refresh when workouts are logged
- **Deep Links** - Tap any widget to open app to Workouts tab

### ⚙️ Customization & Privacy
- **Theme Support** - Dark mode default with light mode option
- **Weekly Goal Settings** - Customize target workout frequency (1-7 per week)
- **Full Data Export** - Complete JSON export of exercises, routines, workouts, and settings
- **Data Import** - Restore from JSON backups
- **100% Offline** - All data stored locally with SwiftData
- **No Account Required** - No sign-up, no tracking, complete privacy
- **App Group Storage** - Shared data container for widgets

### 🎨 Onboarding Experience
- **6-Screen Flow** - Personalized setup with name and goal configuration
- **Value Proposition** - Learn about progressive overload and analytics
- **Preset Library Intro** - Discover 30+ exercises and 7 routines
- **Smart Logging Guide** - Understand previous data display and tap-to-copy
- **Progress Tracking Tour** - Preview PRs, streaks, widgets, and calendar
- **Portrait Lock** - Onboarding stays in portrait for optimal experience
- **Swipe Navigation** - Gesture-based flow with validation on first screen

## 🎨 Design Philosophy

Tempus follows a **minimalist design philosophy** with iOS 26's Liquid Glass aesthetic:

- **Visual Style**
  - Liquid Glass materials with translucency and depth
  - `.ultraThinMaterial` and `.regularMaterial` backgrounds
  - Layered UI with proper shadows and blur effects

- **Color Palette**
  - Primary: Orange accent (#FF8F3D - rgb(255, 143, 61))
  - Base: Pure grayscale (black, white, grays)
  - Minimal color usage for focus and clarity

- **Typography & Icons**
  - SF Pro system fonts with clear hierarchy
  - SF Symbols 7 icons throughout
  - Unique muscle group icons

- **Interactions**
  - Haptic feedback on all key actions
  - Smooth spring animations
  - Material-based buttons and cards

- **Localization**
  - UK English (en_GB)
  - Metric units (kg)
  - British date formatting

## 📋 Requirements

- **iOS**: 26.0+
- **Xcode**: 16.0+
- **Swift**: 6.0+
- **Device**: iPhone (iPad support not yet implemented)

## 🚀 Installation

```bash
# Clone the repository
git clone https://github.com/arbitrary-frame/Tempus-ios.git
cd Tempus-ios

# Open in Xcode
open Tempus.xcodeproj

# Build and run (⌘R)
```

## 🏗️ Architecture

- **SwiftData** for persistent storage with @Model classes
- **SwiftUI** for declarative UI
- **MVVM** pattern with environment-based dependency injection
- **Swift 6** with full concurrency support
- **WidgetKit** for home screen widgets with TimelineProvider

### Models

- **Exercise** - Exercise definitions with muscle groups and tags
- **WorkoutRoutine** - Reusable workout templates with exercises
- **WorkoutEntry** - Logged workouts with embedded exercise data for history preservation
- **WorkoutExerciseData** - Exercise performance data within workouts
- **OnboardingState** - User preferences and settings

### Project Structure

```
Tempus/
├── Models/               # SwiftData models
│   ├── Exercise.swift
│   ├── WorkoutRoutine.swift
│   ├── WorkoutEntry.swift
│   ├── OnboardingState.swift
│   └── Supporting/
│       └── WorkoutExerciseData.swift
├── Views/               # SwiftUI views
│   ├── Workouts/       # Workout logging and list
│   ├── Exercises/      # Exercise library
│   ├── Routines/       # Workout templates
│   ├── Analytics/      # Statistics and insights
│   ├── Settings/       # App configuration
│   └── Onboarding/     # First-time setup
├── Utilities/          # Helpers and managers
│   ├── HapticManager.swift
│   ├── ThemeManager.swift
│   └── AppGroupUserDefaults.swift
└── Assets.xcassets/    # Images and colors

TempusWidget/           # Widget extension
├── GoalProgressWidget.swift
├── ExercisesWidget.swift
├── WeightWidget.swift
├── CombinedStatsWidget.swift
├── WorkoutStatsProvider.swift
└── WorkoutStatsEntry.swift
```

## 📚 Documentation

- **[CHANGELOG.md](CHANGELOG.md)** - Detailed history of all features, improvements, and fixes
- **[WIDGET_BUILD_INSTRUCTIONS.md](WIDGET_BUILD_INSTRUCTIONS.md)** - Widget implementation guide
- **[workflow.md](.claude/workflow.md)** - Development guidelines and Git workflow
- **[requirements-ios.md](requirements-ios.md)** - Complete iOS 26 requirements and specifications

## 🆕 Recent Updates

**v1.0.0 (October 2025)**
- ✨ **Onboarding Redesign** - 6-screen flow with swipe navigation, validation, and portrait lock
- 🏋️ **Smart Workout Logging** - Previous performance display and tap-to-copy sets
- 📊 **iOS 26 Widgets** - Home screen widgets with real-time sync and deep links
- 🎯 **Weekly Goals** - Progress rings with celebration effects and streak tracking
- 📅 **Workout Calendar** - Visual calendar with colour-coded workout frequency
- 🏆 **Personal Records** - Automatic PR tracking with detailed history
- 📚 **Preset Library** - 30+ exercises and 7 routines ready to use
- 🔄 **Full Export/Import** - Complete JSON backup and restore
- ⚡ **Performance** - 15-20% faster startup, optimized haptics, background export
- 🎨 **Liquid Glass UI** - Refined translucent materials throughout

See [CHANGELOG.md](CHANGELOG.md) for complete version history.

## 🛠️ Development

### Development Workflow
1. **Never commit directly to `master`** - Always create feature branches
2. Use descriptive PR titles following conventional commits
3. Include Claude Code co-authoring in commits
4. See [workflow.md](.claude/workflow.md) for detailed guidelines

### Building
```bash
# Clean build
⌘⇧K

# Build
⌘B

# Run
⌘R

# Run tests (when available)
⌘U
```

### Performance Tips
- Use Instruments to profile performance
- Check for SwiftData query optimizations
- Monitor memory usage with Debug Memory Graph
- Test on real devices for accurate widget behavior

## 🤝 Contributing

This is a personal project, but feedback and suggestions are welcome via GitHub Issues.

## 📝 License

Private project - All rights reserved.

## 🙏 Acknowledgements

- Built with [Claude Code](https://claude.com/claude-code) assistance
- Design inspired by iOS 26 Liquid Glass aesthetic
- Icons from SF Symbols 7
- Haptic feedback patterns from Apple HIG

---

**Made with 🧡 by Ronak Pattani**
