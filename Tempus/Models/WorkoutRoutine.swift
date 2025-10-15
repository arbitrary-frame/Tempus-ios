//
//  WorkoutRoutine.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutRoutine {
    @Attribute(.unique) var id: UUID
    var name: String
    var routineDescription: String?
    var emoji: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify)
    var exercises: [Exercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutEntry.routine)
    var workouts: [WorkoutEntry]?

    init(name: String, routineDescription: String? = nil, emoji: String? = nil, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.routineDescription = routineDescription
        self.emoji = emoji
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()
    }
}