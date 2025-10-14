//
//  PresetRoutines.swift
//  Tempus
//
//  Preset routine library for beta testing onboarding.
//  Users can import these routines to get started quickly.
//

import Foundation

/// Template data for a preset routine
struct PresetRoutine: Identifiable {
    let id = UUID()
    let name: String
    let emoji: String
    let description: String
    let exerciseNames: [String]  // References preset exercises by exact name
}

/// Curated library of preset workout routines
enum PresetRoutines {
    static let all: [PresetRoutine] = [
        // Push Day - Chest, Shoulders, Triceps
        PresetRoutine(
            name: "Push Day",
            emoji: "💪",
            description: "Chest, shoulders, and triceps compound and isolation movements.",
            exerciseNames: [
                "Barbell Bench Press",
                "Overhead Press",
                "Incline Dumbbell Press",
                "Lateral Raise",
                "Tricep Dips",
                "Cable Pushdown"
            ]
        ),

        // Pull Day - Back, Biceps
        PresetRoutine(
            name: "Pull Day",
            emoji: "🏃",
            description: "Back and biceps pulling movements for a complete upper body pull session.",
            exerciseNames: [
                "Barbell Deadlift",
                "Pull-Ups",
                "Barbell Row",
                "Lat Pull-Down",
                "Barbell Curl",
                "Hammer Curl"
            ]
        ),

        // Leg Day - Comprehensive lower body
        PresetRoutine(
            name: "Leg Day",
            emoji: "🦵",
            description: "Complete lower body workout targeting quads, hamstrings, glutes, and calves.",
            exerciseNames: [
                "Barbell Squat",
                "Romanian Deadlift",
                "Leg Press",
                "Bulgarian Split Squat",
                "Calf Raise"
            ]
        ),

        // Upper Body - Chest, Back, Shoulders
        PresetRoutine(
            name: "Upper Body",
            emoji: "🏋️",
            description: "Comprehensive upper body session covering chest, back, and shoulders.",
            exerciseNames: [
                "Barbell Bench Press",
                "Barbell Row",
                "Overhead Press",
                "Pull-Ups",
                "Dumbbell Shoulder Press",
                "Cable Chest Fly"
            ]
        ),

        // Full Body - Compound movements
        PresetRoutine(
            name: "Full Body",
            emoji: "🔥",
            description: "Full body workout with compound movements for overall strength.",
            exerciseNames: [
                "Barbell Deadlift",
                "Barbell Squat",
                "Barbell Bench Press",
                "Pull-Ups",
                "Overhead Press"
            ]
        ),

        // Arm Day - Biceps and Triceps
        PresetRoutine(
            name: "Arm Day",
            emoji: "💪",
            description: "Dedicated arm session focusing on biceps and triceps development.",
            exerciseNames: [
                "Barbell Curl",
                "Dumbbell Curl",
                "Hammer Curl",
                "Close-Grip Bench Press",
                "Tricep Dips",
                "Cable Pushdown"
            ]
        ),

        // Core & Conditioning
        PresetRoutine(
            name: "Core & Conditioning",
            emoji: "🧠",
            description: "Core strength and full body conditioning movements.",
            exerciseNames: [
                "Plank",
                "Hanging Leg Raise",
                "Cable Crunch",
                "Burpees",
                "Kettlebell Swing"
            ]
        )
    ]
}
