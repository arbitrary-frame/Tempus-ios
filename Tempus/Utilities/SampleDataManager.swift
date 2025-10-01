//
//  SampleDataManager.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

#if DEBUG

import Foundation
import SwiftData

@MainActor
class SampleDataManager {

    /// Populates the database with sample exercises, routines, and workouts
    static func loadSampleData(into context: ModelContext) {
        print("🎯 Loading sample data...")

        // Clear existing data first
        clearAllData(from: context)

        // Create sample exercises
        let exercises = createSampleExercises(context: context)

        // Create sample routines
        let routines = createSampleRoutines(exercises: exercises, context: context)

        // Create sample workouts
        createSampleWorkouts(exercises: exercises, routines: routines, context: context)

        // Save everything
        do {
            try context.save()
            print("✅ Sample data loaded successfully!")
        } catch {
            print("❌ Error saving sample data: \(error)")
        }
    }

    /// Clears all data from the database
    static func clearAllData(from context: ModelContext) {
        print("🧹 Clearing all data...")

        // Delete all workout entries
        do {
            try context.delete(model: WorkoutEntry.self)
            try context.delete(model: WorkoutRoutine.self)
            try context.delete(model: Exercise.self)
            try context.save()
            print("✅ All data cleared!")
        } catch {
            print("❌ Error clearing data: \(error)")
        }
    }

    // MARK: - Private Helpers

    private static func createSampleExercises(context: ModelContext) -> [Exercise] {
        let exerciseData: [(name: String, muscleGroup: String, tags: [String])] = [
            // Chest
            ("Bench Press", "Chest", ["Compound", "Barbell"]),
            ("Incline Dumbbell Press", "Chest", ["Compound", "Dumbbell"]),
            ("Cable Flyes", "Chest", ["Isolation", "Cable"]),

            // Back
            ("Deadlift", "Back", ["Compound", "Barbell"]),
            ("Pull-ups", "Back", ["Compound", "Bodyweight"]),
            ("Barbell Row", "Back", ["Compound", "Barbell"]),
            ("Lat Pulldown", "Back", ["Compound", "Cable"]),

            // Legs
            ("Squat", "Legs", ["Compound", "Barbell"]),
            ("Leg Press", "Legs", ["Compound", "Machine"]),
            ("Romanian Deadlift", "Legs", ["Compound", "Barbell"]),
            ("Leg Curl", "Legs", ["Isolation", "Machine"]),

            // Shoulders
            ("Overhead Press", "Shoulders", ["Compound", "Barbell"]),
            ("Lateral Raise", "Shoulders", ["Isolation", "Dumbbell"]),

            // Arms
            ("Barbell Curl", "Arms", ["Isolation", "Barbell"]),
            ("Tricep Pushdown", "Arms", ["Isolation", "Cable"]),
            ("Hammer Curl", "Arms", ["Isolation", "Dumbbell"])
        ]

        var exercises: [Exercise] = []

        for data in exerciseData {
            let exercise = Exercise(
                name: data.name,
                muscleGroup: data.muscleGroup,
                tags: data.tags
            )
            context.insert(exercise)
            exercises.append(exercise)
        }

        print("📝 Created \(exercises.count) sample exercises")
        return exercises
    }

    private static func createSampleRoutines(exercises: [Exercise], context: ModelContext) -> [WorkoutRoutine] {
        var routines: [WorkoutRoutine] = []

        // Push Day
        let pushExercises = exercises.filter { ["Chest", "Shoulders"].contains($0.muscleGroup) || $0.name.contains("Tricep") }
        let pushRoutine = WorkoutRoutine(
            name: "Push Day",
            routineDescription: "Chest, shoulders, and triceps",
            emoji: "💪",
            exercises: Array(pushExercises.prefix(5))
        )
        context.insert(pushRoutine)
        routines.append(pushRoutine)

        // Pull Day
        let pullExercises = exercises.filter { $0.muscleGroup == "Back" || $0.name.contains("Curl") }
        let pullRoutine = WorkoutRoutine(
            name: "Pull Day",
            routineDescription: "Back and biceps",
            emoji: "🏋️",
            exercises: Array(pullExercises.prefix(5))
        )
        context.insert(pullRoutine)
        routines.append(pullRoutine)

        // Leg Day
        let legExercises = exercises.filter { $0.muscleGroup == "Legs" }
        let legRoutine = WorkoutRoutine(
            name: "Leg Day",
            routineDescription: "Quads, hamstrings, and glutes",
            emoji: "🦵",
            exercises: legExercises
        )
        context.insert(legRoutine)
        routines.append(legRoutine)

        print("📋 Created \(routines.count) sample routines")
        return routines
    }

    private static func createSampleWorkouts(exercises: [Exercise], routines: [WorkoutRoutine], context: ModelContext) {
        let calendar = Calendar.current
        let today = Date()

        // Create 7 workouts over the past 2 weeks
        let workoutDates = [
            calendar.date(byAdding: .day, value: -14, to: today)!,
            calendar.date(byAdding: .day, value: -12, to: today)!,
            calendar.date(byAdding: .day, value: -10, to: today)!,
            calendar.date(byAdding: .day, value: -7, to: today)!,
            calendar.date(byAdding: .day, value: -5, to: today)!,
            calendar.date(byAdding: .day, value: -3, to: today)!,
            calendar.date(byAdding: .day, value: -1, to: today)!
        ]

        for (index, date) in workoutDates.enumerated() {
            let routine = routines[index % routines.count]
            let workoutExercises = routine.exercises.prefix(3).map { exercise -> WorkoutExerciseData in
                // Generate realistic sets with progressive weight
                let baseWeight = getBaseWeight(for: exercise.name)
                let sets = (1...3).map { setNumber in
                    WorkoutSet(
                        setNumber: setNumber,
                        weightsAndReps: [WeightRep(
                            weight: baseWeight + Double(index) * 2.5, // Progressive overload
                            reps: 10 - setNumber // Descending reps
                        )]
                    )
                }

                return WorkoutExerciseData(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    sets: sets
                )
            }

            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_GB")
            dateFormatter.dateFormat = "d MMM yyyy"

            let workout = WorkoutEntry(
                name: "\(routine.name) - \(dateFormatter.string(from: date))",
                date: date,
                routine: routine,
                exercisesData: Array(workoutExercises)
            )
            context.insert(workout)
        }

        print("🏋️ Created \(workoutDates.count) sample workouts")
    }

    private static func getBaseWeight(for exerciseName: String) -> Double {
        // Return realistic starting weights for different exercises
        switch exerciseName {
        case let name where name.contains("Bench Press"):
            return 60.0
        case let name where name.contains("Squat"):
            return 80.0
        case let name where name.contains("Deadlift"):
            return 100.0
        case let name where name.contains("Press") && name.contains("Overhead"):
            return 40.0
        case let name where name.contains("Row"):
            return 50.0
        case let name where name.contains("Pull"):
            return 70.0
        case let name where name.contains("Curl"):
            return 15.0
        case let name where name.contains("Raise"):
            return 10.0
        case let name where name.contains("Leg"):
            return 60.0
        default:
            return 20.0
        }
    }
}

#endif