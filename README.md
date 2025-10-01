# Tempus 🏋️

A minimalist iOS workout tracking app built with Swift 6, SwiftUI, and SwiftData.

[![iOS](https://img.shields.io/badge/iOS-26.0+-black.svg)](https://developer.apple.com/ios/)
[![Swift](https://img.shields.io/badge/Swift-6.0-orange.svg)](https://swift.org)
[![SwiftUI](https://img.shields.io/badge/SwiftUI-5.0-blue.svg)](https://developer.apple.com/xcode/swiftui/)

> A powerful yet simple workout tracker focused on what matters: tracking your progress without the noise.

## ✨ Features

### 🏋️ Core Functionality
- **Workout Logging** - Track exercises, sets, weights, and reps with drop set support
- **Routines** - Create reusable workout templates with custom emoji icons
- **Exercise Library** - Manage exercises organized by muscle groups with SF Symbols 7 icons
- **Workout History** - View and edit past workouts with preserved data
- **Previous Workout Preview** - See your last performance while logging exercises

### 📊 Analytics & Insights
- **Weekly Goal Tracking** - Set and track weekly workout goals with progress rings
- **Workout Calendar** - Visual calendar showing your workout history
- **Statistics Dashboard** - Week-over-week comparisons and trend indicators
- **Streak Tracking** - Track consecutive weeks meeting your goals

### 📱 Home Screen Widgets
- **Goal Progress Widget** (Small) - Circular progress ring showing workouts vs weekly goal
- **Exercises Widget** (Small) - Exercise count for current week
- **Weight Widget** (Small) - Total weight lifted this week
- **Combined Stats Widget** (Medium) - All three stats in one widget
- Auto-updates when workouts change, tap to open app

### ⚙️ Customization & Data
- **Theme Support** - Dark mode default with light mode option
- **Data Export/Import** - Full JSON export of all workout data
- **Onboarding Flow** - Personalized setup with name and goal configuration
- **Settings** - Customize weekly goals, theme, and manage data

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
- ✨ iOS 26 home screen widgets with real-time sync
- 🎯 Weekly goal tracking with progress rings and streaks
- 📊 Enhanced analytics with week-over-week comparisons
- 📅 Visual workout calendar
- ⚡ Major performance optimizations (15-20% faster startup)
- 🎨 Refined Liquid Glass design throughout

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
