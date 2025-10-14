//
//  AnalyticsService.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import Foundation

/// Centralized service for all analytics calculations
/// Provides a single source of truth for metrics used throughout the app
actor AnalyticsService {

    // MARK: - Volume Calculations

    /// Calculate total volume for a workout (sum of weight × reps for all sets)
    /// - Parameter workout: The workout entry to calculate volume for
    /// - Returns: Total volume in kg (weight × reps, doubled for unilateral exercises)
    static func calculateWorkoutVolume(_ workout: WorkoutEntry) -> Double {
        var total = 0.0
        for exercise in workout.exercisesData {
            let multiplier = exercise.isUnilateral ? 2.0 : 1.0
            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    total += weightRep.weight * Double(weightRep.reps) * multiplier
                }
            }
        }
        return total
    }

    /// Calculate volume for a specific exercise across multiple workouts
    /// - Parameters:
    ///   - exerciseName: Name of the exercise to track
    ///   - workouts: Array of workouts to search
    /// - Returns: Array of tuples with date and volume for that exercise (doubled for unilateral)
    static func calculateExerciseVolume(
        exerciseName: String,
        in workouts: [WorkoutEntry]
    ) -> [(date: Date, volume: Double)] {
        var results: [(date: Date, volume: Double)] = []

        for workout in workouts {
            // Find this exercise in the workout
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            // Calculate volume for this exercise in this workout
            let multiplier = exercise.isUnilateral ? 2.0 : 1.0
            var exerciseVolume = 0.0
            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    exerciseVolume += weightRep.weight * Double(weightRep.reps) * multiplier
                }
            }

            results.append((date: workout.workoutDate, volume: exerciseVolume))
        }

        return results.sorted { $0.date < $1.date }
    }

    /// Calculate volume trend over time for all workouts
    /// - Parameter workouts: Array of workouts
    /// - Returns: Array of tuples with date and total volume
    static func volumeTrend(for workouts: [WorkoutEntry]) -> [(date: Date, volume: Double)] {
        return workouts
            .map { (date: $0.workoutDate, volume: calculateWorkoutVolume($0)) }
            .sorted { $0.date < $1.date }
    }

    // MARK: - Max Weight Tracking

    /// Find the maximum weight lifted for a specific exercise across all workouts
    /// - Parameters:
    ///   - exerciseName: Name of the exercise
    ///   - workouts: Array of workouts to search
    /// - Returns: Maximum weight in kg, or nil if exercise not found
    static func findMaxWeight(for exerciseName: String, in workouts: [WorkoutEntry]) -> Double? {
        var maxWeight: Double?

        for workout in workouts {
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    if let current = maxWeight {
                        maxWeight = max(current, weightRep.weight)
                    } else {
                        maxWeight = weightRep.weight
                    }
                }
            }
        }

        return maxWeight
    }

    /// Get max weight progression over time for an exercise
    /// - Parameters:
    ///   - exerciseName: Name of the exercise
    ///   - workouts: Array of workouts
    /// - Returns: Array of tuples with date and max weight for that workout
    static func maxWeightProgression(
        for exerciseName: String,
        in workouts: [WorkoutEntry]
    ) -> [(date: Date, maxWeight: Double)] {
        var results: [(date: Date, maxWeight: Double)] = []

        for workout in workouts {
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            // Find max weight in this workout for this exercise
            var workoutMax = 0.0
            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    workoutMax = max(workoutMax, weightRep.weight)
                }
            }

            if workoutMax > 0 {
                results.append((date: workout.workoutDate, maxWeight: workoutMax))
            }
        }

        return results.sorted { $0.date < $1.date }
    }

    // MARK: - Personal Records

    /// Detect personal records for a specific exercise
    /// - Parameters:
    ///   - exerciseName: Name of the exercise
    ///   - workouts: Array of workouts sorted by date
    /// - Returns: Array of personal records
    static func detectPersonalRecords(
        for exerciseName: String,
        in workouts: [WorkoutEntry]
    ) -> [PersonalRecord] {
        var records: [PersonalRecord] = []
        var currentBest1RM: Double = 0

        // Sort workouts by date
        let sortedWorkouts = workouts.sorted { $0.workoutDate < $1.workoutDate }

        for workout in sortedWorkouts {
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            // Check all sets for PRs
            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    let estimated1RM = estimate1RM(weight: weightRep.weight, reps: weightRep.reps)

                    if estimated1RM > currentBest1RM {
                        currentBest1RM = estimated1RM
                        let pr = PersonalRecord(
                            date: workout.workoutDate,
                            weight: weightRep.weight,
                            reps: weightRep.reps,
                            estimatedOneRM: estimated1RM
                        )
                        records.append(pr)
                    }
                }
            }
        }

        return records
    }

    // MARK: - 1RM Estimation

    /// Estimate 1 rep max using the Brzycki formula
    /// Formula: weight × (36 / (37 - reps))
    /// - Parameters:
    ///   - weight: Weight lifted in kg
    ///   - reps: Number of reps performed
    /// - Returns: Estimated 1RM in kg
    static func estimate1RM(weight: Double, reps: Int) -> Double {
        // For 1 rep, the weight is already the 1RM
        guard reps > 1 else { return weight }

        // Brzycki formula is accurate up to 36 reps
        guard reps < 37 else { return weight }

        return weight * (36.0 / (37.0 - Double(reps)))
    }

    // MARK: - Muscle Group Analysis

    /// Calculate volume distribution across muscle groups
    /// - Parameters:
    ///   - workouts: Array of workouts
    ///   - exerciseMuscleGroupMap: Dictionary mapping exercise names to muscle groups
    /// - Returns: Dictionary of muscle group to total volume (doubled for unilateral exercises)
    static func calculateMuscleGroupDistribution(
        in workouts: [WorkoutEntry],
        exerciseMuscleGroupMap: [String: String]
    ) -> [String: Double] {
        var distribution: [String: Double] = [:]

        for workout in workouts {
            for exercise in workout.exercisesData {
                // Look up muscle group for this exercise
                guard let muscleGroup = exerciseMuscleGroupMap[exercise.exerciseName] else {
                    continue
                }

                // Calculate volume for this exercise
                let multiplier = exercise.isUnilateral ? 2.0 : 1.0
                var exerciseVolume = 0.0
                for set in exercise.sets {
                    for weightRep in set.weightsAndReps {
                        exerciseVolume += weightRep.weight * Double(weightRep.reps) * multiplier
                    }
                }

                // Add to muscle group total
                distribution[muscleGroup, default: 0] += exerciseVolume
            }
        }

        return distribution
    }

    // MARK: - Frequency Analysis

    /// Calculate how many times each exercise was performed
    /// - Parameter workouts: Array of workouts
    /// - Returns: Dictionary of exercise name to count
    static func exerciseFrequency(in workouts: [WorkoutEntry]) -> [String: Int] {
        var frequency: [String: Int] = [:]

        for workout in workouts {
            for exercise in workout.exercisesData {
                frequency[exercise.exerciseName, default: 0] += 1
            }
        }

        return frequency
    }

    /// Calculate workout frequency by week
    /// - Parameter workouts: Array of workouts
    /// - Returns: Dictionary of week start date to workout count
    static func weeklyFrequency(workouts: [WorkoutEntry]) -> [Date: Int] {
        var frequency: [Date: Int] = [:]
        let calendar = Calendar.current

        for workout in workouts {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)
            ) else {
                continue
            }

            frequency[weekStart, default: 0] += 1
        }

        return frequency
    }

    // MARK: - Average Calculations

    /// Calculate average weight for an exercise across all workouts
    /// - Parameters:
    ///   - exerciseName: Name of the exercise
    ///   - workouts: Array of workouts
    /// - Returns: Average weight in kg, or nil if no data
    static func averageWeight(for exerciseName: String, in workouts: [WorkoutEntry]) -> Double? {
        var totalWeight = 0.0
        var count = 0

        for workout in workouts {
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    totalWeight += weightRep.weight
                    count += 1
                }
            }
        }

        guard count > 0 else { return nil }
        return totalWeight / Double(count)
    }

    /// Calculate average reps for an exercise across all workouts
    /// - Parameters:
    ///   - exerciseName: Name of the exercise
    ///   - workouts: Array of workouts
    /// - Returns: Average reps, or nil if no data
    static func averageReps(for exerciseName: String, in workouts: [WorkoutEntry]) -> Double? {
        var totalReps = 0
        var count = 0

        for workout in workouts {
            guard let exercise = workout.exercisesData.first(where: { $0.exerciseName == exerciseName }) else {
                continue
            }

            for set in exercise.sets {
                for weightRep in set.weightsAndReps {
                    totalReps += weightRep.reps
                    count += 1
                }
            }
        }

        guard count > 0 else { return nil }
        return Double(totalReps) / Double(count)
    }
}

// MARK: - Supporting Models

/// Represents a personal record achievement
struct PersonalRecord: Identifiable, Codable, Sendable {
    let id: UUID
    let date: Date
    let weight: Double
    let reps: Int
    let estimatedOneRM: Double

    nonisolated init(date: Date, weight: Double, reps: Int, estimatedOneRM: Double) {
        self.id = UUID()
        self.date = date
        self.weight = weight
        self.reps = reps
        self.estimatedOneRM = estimatedOneRM
    }
}
