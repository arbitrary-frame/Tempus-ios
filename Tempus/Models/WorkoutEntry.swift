//
//  WorkoutEntry.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutEntry {
    @Attribute(.unique) var id: UUID
    var workoutName: String
    var workoutDate: Date
    var notes: String?
    var createdAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify)
    var routine: WorkoutRoutine?

    // Embedded exercises data (not relationships to preserve history)
    // This ensures workout data remains intact even if exercises are modified/deleted
    var exercisesData: [WorkoutExerciseData]

    init(name: String, date: Date, routine: WorkoutRoutine? = nil, exercisesData: [WorkoutExerciseData] = [], notes: String? = nil) {
        self.id = UUID()
        self.workoutName = name
        self.workoutDate = date
        self.routine = routine
        self.exercisesData = exercisesData
        self.notes = notes
        self.createdAt = Date()

        // DEBUG: Workout entry created
        print("DEBUG: WorkoutEntry created - \(name) on \(date) with \(exercisesData.count) exercises")
    }
}