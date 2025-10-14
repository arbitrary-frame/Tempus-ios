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
    case fullBody = "Full Body"
    case other = "Other"

    var id: String { rawValue }

    /// SF Symbols 7 icon for each muscle group
    /// Each icon is unique and represents the exercises for that group
    var icon: String {
        switch self {
        case .chest:
            // Pushing movements - bench press, push-ups
            return "figure.strengthtraining.functional"
        case .back:
            // Pulling movements - rows, pull-ups, deadlifts
            return "figure.cooldown"
        case .shoulders:
            // Overhead pressing, lateral raises
            return "figure.arms.open"
        case .biceps:
            // Curling movements - bicep curls
            return "dumbbell.fill"
        case .triceps:
            // Extension movements - tricep extensions, dips
            return "figure.strengthtraining.traditional"
        case .legs:
            // Squats, lunges, leg press
            return "figure.walk"
        case .core:
            // Abs, planks, core stability (perfect symbol exists!)
            return "figure.core.training"
        case .fullBody:
            // Compound movements involving multiple muscle groups
            return "figure.mixed.cardio"
        case .other:
            // General/miscellaneous exercises
            return "figure.play"
        }
    }
}