//
//  DemoDataGenerator.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation
import SwiftData

/// Generates demo data for onboarding experience
struct DemoDataGenerator {
    private static let demoTag = "__DEMO__"

    /// Creates demo exercises covering major muscle groups
    static func createDemoExercises(in context: ModelContext) -> [Exercise] {
        let exercises = [
            Exercise(name: "Bench Press", muscleGroup: "Chest", tags: [demoTag], exerciseDescription: "Classic chest builder"),
            Exercise(name: "Squat", muscleGroup: "Legs", tags: [demoTag], exerciseDescription: "King of leg exercises"),
            Exercise(name: "Deadlift", muscleGroup: "Back", tags: [demoTag], exerciseDescription: "Full body power move"),
            Exercise(name: "Overhead Press", muscleGroup: "Shoulders", tags: [demoTag], exerciseDescription: "Build strong shoulders"),
            Exercise(name: "Barbell Row", muscleGroup: "Back", tags: [demoTag], exerciseDescription: "Thick back builder"),
            Exercise(name: "Pull-ups", muscleGroup: "Back", tags: [demoTag], exerciseDescription: "Bodyweight back exercise"),
            Exercise(name: "Dips", muscleGroup: "Chest", tags: [demoTag, "Triceps"], exerciseDescription: "Upper body compound"),
            Exercise(name: "Bicep Curls", muscleGroup: "Arms", tags: [demoTag], exerciseDescription: "Isolate the biceps")
        ]

        exercises.forEach { context.insert($0) }
        return exercises
    }

    /// Creates a demo routine with selected exercises
    static func createDemoRoutine(exercises: [Exercise], in context: ModelContext) -> WorkoutRoutine {
        // Create "Push Day" routine with bench, overhead press, and dips
        let pushExercises = exercises.filter { ["Bench Press", "Overhead Press", "Dips"].contains($0.name) }

        let routine = WorkoutRoutine(
            name: "Push Day",
            routineDescription: "Upper body pushing exercises",
            emoji: "💪",
            exercises: pushExercises
        )

        context.insert(routine)
        return routine
    }

    /// Creates a demo completed workout with realistic data
    static func createDemoWorkout(routine: WorkoutRoutine, in context: ModelContext) -> WorkoutEntry {
        // Create realistic workout data
        let exercisesData: [WorkoutExerciseData] = routine.exercises.map { exercise in
            var sets: [WorkoutSet] = []

            switch exercise.name {
            case "Bench Press":
                sets = [
                    WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 60, reps: 10)]),
                    WorkoutSet(setNumber: 2, weightsAndReps: [WeightRep(weight: 65, reps: 8)]),
                    WorkoutSet(setNumber: 3, weightsAndReps: [WeightRep(weight: 70, reps: 6)])
                ]
            case "Overhead Press":
                sets = [
                    WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 40, reps: 10)]),
                    WorkoutSet(setNumber: 2, weightsAndReps: [WeightRep(weight: 45, reps: 8)]),
                    WorkoutSet(setNumber: 3, weightsAndReps: [WeightRep(weight: 45, reps: 7)])
                ]
            case "Dips":
                sets = [
                    WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 0, reps: 12)]),
                    WorkoutSet(setNumber: 2, weightsAndReps: [WeightRep(weight: 0, reps: 10)]),
                    WorkoutSet(setNumber: 3, weightsAndReps: [WeightRep(weight: 0, reps: 8)])
                ]
            default:
                sets = [WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 50, reps: 10)])]
            }

            return WorkoutExerciseData(
                exerciseID: exercise.id,
                exerciseName: exercise.name,
                sets: sets,
                notes: nil
            )
        }

        // Create workout dated 3 days ago
        let threeDaysAgo = Calendar.current.date(byAdding: .day, value: -3, to: Date()) ?? Date()

        let workout = WorkoutEntry(
            name: "Push Day - Demo",
            date: threeDaysAgo,
            routine: routine,
            exercisesData: exercisesData,
            notes: "This is a demo workout to show you how Tempus works!"
        )

        context.insert(workout)
        return workout
    }

    /// Deletes all demo data from the context
    static func clearDemoData(in context: ModelContext) {
        // Delete all items with demo tag
        let exerciseFetchDescriptor = FetchDescriptor<Exercise>(
            predicate: #Predicate { exercise in
                exercise.tags.contains(demoTag)
            }
        )

        let routineFetchDescriptor = FetchDescriptor<WorkoutRoutine>(
            predicate: #Predicate { routine in
                routine.name.contains("Demo")
            }
        )

        let workoutFetchDescriptor = FetchDescriptor<WorkoutEntry>(
            predicate: #Predicate { workout in
                workout.workoutName.contains("Demo")
            }
        )

        do {
            let demoExercises = try context.fetch(exerciseFetchDescriptor)
            let demoRoutines = try context.fetch(routineFetchDescriptor)
            let demoWorkouts = try context.fetch(workoutFetchDescriptor)

            demoExercises.forEach { context.delete($0) }
            demoRoutines.forEach { context.delete($0) }
            demoWorkouts.forEach { context.delete($0) }

            try context.save()
        } catch {
            print("Error clearing demo data: \(error)")
        }
    }

    /// Creates all demo data at once
    static func generateAllDemoData(in context: ModelContext) {
        let exercises = createDemoExercises(in: context)
        let routine = createDemoRoutine(exercises: exercises, in: context)
        _ = createDemoWorkout(routine: routine, in: context)

        do {
            try context.save()
        } catch {
            print("Error saving demo data: \(error)")
        }
    }
}