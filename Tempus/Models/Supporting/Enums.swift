//
//  Enums.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import Foundation

/// Muscle groups for exercise classification
enum MuscleGroup: String, CaseIterable, Identifiable {
    case chest = "Chest"
    case back = "Back"
    case shoulders = "Shoulders"
    case biceps = "Biceps"
    case triceps = "Triceps"
    case legs = "Legs"
    case core = "Core"
    case cardio = "Cardio"
    case fullBody = "Full Body"
    case other = "Other"

    var id: String { rawValue }
}