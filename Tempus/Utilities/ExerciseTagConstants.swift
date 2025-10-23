//
//  ExerciseTagConstants.swift
//  Tempus
//
//  Created by Ronak Pattani on 09/10/2025.
//

import Foundation

enum ExerciseTag {
    /// Default suggested tags shown in the exercise form for quick selection
    static let defaultSuggestedTags = [
        "dumbbells",
        "barbell",
        "compound",
        "unilateral"
    ]

    /// Returns all unique tags from exercises, prioritising default tags first, then custom tags alphabetically
    static func getSuggestedTags(from exercises: [Exercise]) -> [String] {
        // Collect all unique tags from exercises
        let allTags = Set(exercises.flatMap { $0.tags })

        // Separate into default and custom tags
        let customTags = allTags.filter { !defaultSuggestedTags.contains($0) }.sorted()

        // Return default tags first, then custom tags
        return defaultSuggestedTags + customTags
    }
}
