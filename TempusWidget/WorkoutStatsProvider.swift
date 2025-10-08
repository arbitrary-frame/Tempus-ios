//
//  WorkoutStatsProvider.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import WidgetKit
import SwiftUI
import SwiftData

struct WorkoutStatsProvider: TimelineProvider {
    typealias Entry = WorkoutStatsEntry

    // Create shared model container - same configuration as main app
    private var modelContainer: ModelContainer? = {
        let schema = Schema([
            Exercise.self,
            WorkoutRoutine.self,
            WorkoutEntry.self
        ])

        // Conditional database path AND App Group based on build configuration (MUST match main app)
        #if DEVELOPMENT
        let databaseName = "dev-database.store"
        let appGroupIdentifier = "group.tempus-ios.Tempus.dev"
        print("🧪 [WIDGET DEVELOPMENT] Using dev database: \(databaseName)")
        print("🧪 [WIDGET DEVELOPMENT] Using dev App Group: \(appGroupIdentifier)")
        #else
        let databaseName = "production-database.store"
        let appGroupIdentifier = "group.tempus-ios.Tempus"
        print("✅ [WIDGET PRODUCTION] Using production database: \(databaseName)")
        print("✅ [WIDGET PRODUCTION] Using production App Group: \(appGroupIdentifier)")
        #endif

        // CRITICAL: Use App Group container so app and widget share the same database
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            print("❌ Widget: App Group container '\(appGroupIdentifier)' not found!")
            return nil
        }

        // Ensure App Group directory exists
        try? FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true)

        let databaseURL = appGroupURL.appendingPathComponent(databaseName)

        let modelConfiguration = ModelConfiguration(
            url: databaseURL
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("✅ Widget: ModelContainer created successfully")
            print("📦 Widget database location: \(databaseURL.path)")
            return container
        } catch {
            print("❌ Widget: Failed to create ModelContainer: \(error)")
            return nil
        }
    }()

    func placeholder(in context: Context) -> WorkoutStatsEntry {
        WorkoutStatsEntry(
            date: Date(),
            workoutsCompleted: 2,
            weeklyGoal: 3,
            exercisesThisWeek: 8,
            totalWeightThisWeek: 1250.0
        )
    }

    func getSnapshot(in context: Context, completion: @escaping (WorkoutStatsEntry) -> Void) {
        Task {
            let entry = await generateEntry()
            completion(entry)
        }
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<WorkoutStatsEntry>) -> Void) {
        print("🔄 Widget: getTimeline called at \(Date())")
        Task {
            let entry = await generateEntry()

            // Use .atEnd policy so widget accepts manual reloads
            // Create multiple entries to allow for updates throughout the day
            var entries: [WorkoutStatsEntry] = []

            // Current entry
            entries.append(entry)

            // Entry for 1 hour from now (allows system to update if needed)
            let oneHourLater = Date().addingTimeInterval(3600)
            entries.append(WorkoutStatsEntry(
                date: oneHourLater,
                workoutsCompleted: entry.workoutsCompleted,
                weeklyGoal: entry.weeklyGoal,
                exercisesThisWeek: entry.exercisesThisWeek,
                totalWeightThisWeek: entry.totalWeightThisWeek
            ))

            print("⏰ Widget: Created \(entries.count) timeline entries, policy: .atEnd")
            let timeline = Timeline(entries: entries, policy: .atEnd)
            completion(timeline)
        }
    }

    @MainActor
    private func generateEntry() async -> WorkoutStatsEntry {
        // Get weekly goal from shared UserDefaults
        let weeklyGoal = UserDefaults.shared.integer(forKey: "weeklyWorkoutGoal") != 0
            ? UserDefaults.shared.integer(forKey: "weeklyWorkoutGoal")
            : 3

        // Check if model container is available
        guard let container = modelContainer else {
            print("⚠️ Widget: No model container available, returning empty data")
            return WorkoutStatsEntry(
                date: Date(),
                workoutsCompleted: 0,
                weeklyGoal: weeklyGoal,
                exercisesThisWeek: 0,
                totalWeightThisWeek: 0
            )
        }

        let context = container.mainContext

        // Query workouts this week
        let startOfWeek = Calendar.current.startOfWeek(for: Date())
        let descriptor = FetchDescriptor<WorkoutEntry>(
            predicate: #Predicate { workout in
                workout.workoutDate >= startOfWeek
            },
            sortBy: [SortDescriptor(\.workoutDate, order: .reverse)]
        )

        do {
            let workouts = try context.fetch(descriptor)
            let workoutCount = workouts.count

            // Calculate exercise count
            var exerciseCount = 0
            for workout in workouts {
                exerciseCount += workout.exercisesData.count
            }

            // Calculate total volume
            var totalWeight = 0.0
            for workout in workouts {
                for exercise in workout.exercisesData {
                    for set in exercise.sets {
                        for weightRep in set.weightsAndReps {
                            totalWeight += weightRep.weight * Double(weightRep.reps)
                        }
                    }
                }
            }

            print("✅ Widget: Fetched \(workoutCount) workouts, \(exerciseCount) exercises, \(Int(totalWeight))kg")

            return WorkoutStatsEntry(
                date: Date(),
                workoutsCompleted: workoutCount,
                weeklyGoal: weeklyGoal,
                exercisesThisWeek: exerciseCount,
                totalWeightThisWeek: totalWeight
            )
        } catch {
            print("❌ Widget failed to fetch workouts: \(error)")
            return WorkoutStatsEntry(
                date: Date(),
                workoutsCompleted: 0,
                weeklyGoal: weeklyGoal,
                exercisesThisWeek: 0,
                totalWeightThisWeek: 0
            )
        }
    }
}

// Helper extension
extension Calendar {
    func startOfWeek(for date: Date) -> Date {
        let components = dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return self.date(from: components) ?? date
    }
}
