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

    /// SF Symbol icon for each muscle group
    var icon: String {
        switch self {
        case .chest:
            return "figure.strengthtraining.traditional"
        case .back:
            return "figure.cooldown"
        case .shoulders:
            return "figure.arms.open"
        case .biceps:
            return "figure.flexibility"
        case .triceps:
            return "figure.flexibility"
        case .legs:
            return "figure.walk"
        case .core:
            return "figure.core.training"
        case .cardio:
            return "figure.run"
        case .fullBody:
            return "figure.mixed.cardio"
        case .other:
            return "figure.play"
        }
    }
}