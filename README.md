# Tempus

A minimalist iOS workout tracking app built with Swift 6, SwiftUI, and Swift Data.

## Features

- **Workout Logging**: Track your workouts with exercises, sets, weights, and reps
- **Routines**: Create reusable workout routines with custom emoji icons
- **Exercise Library**: Manage exercises organised by muscle groups
- **Drop Set Support**: Log multiple weight/rep combinations per set
- **Workout History**: View and edit past workouts with preserved data
- **Data Export**: Export all workout data to JSON format
- **Dark Mode**: Built-in dark/light theme support
- **Analytics**: Basic workout statistics and insights

## Design

Tempus follows a minimalist design philosophy with:
- Liquid Glass aesthetic using iOS materials and translucency
- Orange accent colour (#FF8F3D) on grayscale base
- Dark mode default with light mode option
- UK localisation (en_GB, metric units, British date formatting)

## Requirements

- iOS 26.0+
- Xcode 16.0+
- Swift 6.0+

## Installation

1. Clone the repository
2. Open `Tempus.xcodeproj` in Xcode
3. Select your target device or simulator
4. Build and run (⌘R)

## Architecture

- **Swift Data** for persistent storage with @Model classes
- **SwiftUI** for declarative UI
- **MVVM** pattern with environment-based dependency injection
- **Swift 6** with full concurrency support

## Models

- **Exercise**: Exercise definitions with muscle groups and tags
- **WorkoutRoutine**: Reusable workout templates with exercises
- **WorkoutEntry**: Logged workouts with embedded exercise data for history preservation
- **WorkoutExerciseData**: Exercise performance data within workouts

## Development Workflow

See `.claude/workflow.md` for development guidelines and Git workflow.

## Contributing

This is a personal project, but feedback and suggestions are welcome via Issues.

## Acknowledgements

Built with Claude Code assistance.