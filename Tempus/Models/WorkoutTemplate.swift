//
//  WorkoutTemplate.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation
import SwiftData

@Model
final class WorkoutTemplate {
    @Attribute(.unique) var id: UUID
    var name: String
    var templateDescription: String?
    var emoji: String?
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify)
    var exercises: [Exercise]

    @Relationship(deleteRule: .nullify, inverse: \WorkoutEntry.template)
    var workouts: [WorkoutEntry]?

    init(name: String, templateDescription: String? = nil, emoji: String? = nil, exercises: [Exercise] = []) {
        self.id = UUID()
        self.name = name
        self.templateDescription = templateDescription
        self.emoji = emoji
        self.exercises = exercises
        self.createdAt = Date()
        self.updatedAt = Date()

        // DEBUG: Template created
        print("DEBUG: WorkoutTemplate created - \(name) with \(exercises.count) exercises")
    }
}