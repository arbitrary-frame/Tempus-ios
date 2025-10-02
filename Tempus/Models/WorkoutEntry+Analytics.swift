//
//  WorkoutEntry+Analytics.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import Foundation

// MARK: - WorkoutEntry Analytics Extensions

extension WorkoutEntry {
    /// Total volume for this workout (weight × reps sum)
    var totalVolume: Double {
        AnalyticsService.calculateWorkoutVolume(self)
    }

    /// Number of exercises in this workout
    var exerciseCount: Int {
        exercisesData.count
    }

    /// Total number of sets across all exercises
    var totalSets: Int {
        exercisesData.reduce(0) { $0 + $1.sets.count }
    }

    /// Get all unique muscle groups represented in this workout
    /// Note: Requires exercise library to look up muscle groups
    func uniqueMuscleGroups(from exercises: [Exercise]) -> Set<String> {
        var muscleGroups = Set<String>()

        for exerciseData in exercisesData {
            if let exercise = exercises.first(where: { $0.id == exerciseData.exerciseID }) {
                muscleGroups.insert(exercise.muscleGroup)
            }
        }

        return muscleGroups
    }

    /// Get the maximum weight lifted in this workout
    var maxWeight: Double {
        var max = 0.0

        for exercise in exercisesData {
            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    max = Swift.max(max, weightRep.weight)
                }
            }
        }

        return max
    }
}

// MARK: - Array<WorkoutEntry> Analytics Extensions

extension Array where Element == WorkoutEntry {
    /// Filter workouts that contain exercises from a specific muscle group
    func filtered(byMuscleGroup muscleGroup: String, exercises: [Exercise]) -> [WorkoutEntry] {
        return filter { workout in
            workout.exercisesData.contains { exerciseData in
                exercises.first(where: { $0.id == exerciseData.exerciseID })?.muscleGroup == muscleGroup
            }
        }
    }

    /// Filter workouts containing a specific exercise
    func filtered(byExerciseName name: String) -> [WorkoutEntry] {
        return filter { workout in
            workout.exercisesData.contains { $0.exerciseName == name }
        }
    }

    /// Filter workouts within a date range
    func filtered(from startDate: Date, to endDate: Date) -> [WorkoutEntry] {
        return filter { workout in
            workout.workoutDate >= startDate && workout.workoutDate <= endDate
        }
    }

    /// Get volume trend over time
    var volumeTrend: [(date: Date, volume: Double)] {
        AnalyticsService.volumeTrend(for: self)
    }

    /// Calculate total volume across all workouts
    var totalVolume: Double {
        reduce(0) { $0 + $1.totalVolume }
    }

    /// Get the most recent workout
    var mostRecent: WorkoutEntry? {
        self.max { $0.workoutDate < $1.workoutDate }
    }

    /// Get the oldest workout
    var oldest: WorkoutEntry? {
        self.min { $0.workoutDate < $1.workoutDate }
    }

    /// Calculate average workouts per week
    func averageWorkoutsPerWeek() -> Double? {
        guard !isEmpty else { return nil }
        guard let earliest = oldest?.workoutDate,
              let latest = mostRecent?.workoutDate else {
            return nil
        }

        let calendar = Calendar.current
        let components = calendar.dateComponents([.weekOfYear], from: earliest, to: latest)
        guard let weeks = components.weekOfYear, weeks > 0 else {
            return nil
        }

        return Double(count) / Double(weeks)
    }
}
