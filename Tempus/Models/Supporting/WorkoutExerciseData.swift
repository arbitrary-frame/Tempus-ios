//
//  WorkoutExerciseData.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation

// Codable struct for embedded exercise data in WorkoutEntry
// This preserves historical data even if the Exercise is modified or deleted
struct WorkoutExerciseData: Codable, Identifiable {
    let id: UUID
    let exerciseID: UUID
    let exerciseName: String
    let isUnilateral: Bool // Preserved for accurate historical calculations
    var sets: [WorkoutSet]
    var notes: String?

    init(exerciseID: UUID, exerciseName: String, isUnilateral: Bool = false, sets: [WorkoutSet] = [], notes: String? = nil) {
        self.id = UUID()
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.isUnilateral = isUnilateral
        self.sets = sets
        self.notes = notes
    }
}

struct WorkoutSet: Codable, Identifiable {
    let id: UUID
    let setNumber: Int
    var weightsAndReps: [WeightRep]

    init(setNumber: Int, weightsAndReps: [WeightRep] = []) {
        self.id = UUID()
        self.setNumber = setNumber
        self.weightsAndReps = weightsAndReps
    }
}

struct WeightRep: Codable, Identifiable {
    let id: UUID
    var weight: Double // in kg, supports decimals (0.5kg increments)
    var reps: Int

    init(weight: Double = 0, reps: Int = 0) {
        self.id = UUID()
        self.weight = weight
        self.reps = reps
    }
}