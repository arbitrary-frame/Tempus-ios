//
//  Exercise.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation
import SwiftData

@Model
final class Exercise {
    @Attribute(.unique) var id: UUID
    var name: String
    var exerciseDescription: String?
    var muscleGroup: String
    var tags: [String]
    var imageURL: String?
    var isArchived: Bool
    var createdAt: Date
    var updatedAt: Date

    // Relationships
    @Relationship(deleteRule: .nullify, inverse: \WorkoutRoutine.exercises)
    var routines: [WorkoutRoutine]?

    init(name: String, muscleGroup: String, tags: [String] = [], exerciseDescription: String? = nil, imageURL: String? = nil) {
        self.id = UUID()
        self.name = name
        self.muscleGroup = muscleGroup
        self.tags = tags
        self.exerciseDescription = exerciseDescription
        self.imageURL = imageURL
        self.isArchived = false
        self.createdAt = Date()
        self.updatedAt = Date()

        // DEBUG: Exercise created
        print("DEBUG: Exercise created - \(name) (\(muscleGroup))")
    }
}