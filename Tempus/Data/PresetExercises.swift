//
//  PresetExercises.swift
//  Tempus
//
//  Preset exercise library for beta testing onboarding.
//  Users can import these exercises to get started quickly.
//

import Foundation

/// Template data for a preset exercise
struct PresetExercise: Identifiable {
    let id = UUID()
    let name: String
    let muscleGroup: String
    let description: String
    let tags: [String]
}

/// Curated library of preset exercises across all muscle groups
enum PresetExercises {
    // MARK: - Chest (5 exercises)
    static let chest: [PresetExercise] = [
        PresetExercise(
            name: "Barbell Bench Press",
            muscleGroup: "Chest",
            description: "Lie on bench, lower barbell to chest, press up to starting position.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Dumbbell Bench Press",
            muscleGroup: "Chest",
            description: "Lie on bench with dumbbells, press weights up until arms are extended.",
            tags: ["dumbbells", "compound"]
        ),
        PresetExercise(
            name: "Incline Dumbbell Press",
            muscleGroup: "Chest",
            description: "Press dumbbells on inclined bench to target upper chest.",
            tags: ["dumbbells", "compound"]
        ),
        PresetExercise(
            name: "Cable Chest Fly",
            muscleGroup: "Chest",
            description: "Pull cable handles together in front of chest with slight bend in elbows.",
            tags: ["cable", "isolation"]
        ),
        PresetExercise(
            name: "Press-Ups",
            muscleGroup: "Chest",
            description: "Lower chest to floor, push back up to starting position.",
            tags: ["bodyweight", "compound"]
        )
    ]

    // MARK: - Back (5 exercises)
    static let back: [PresetExercise] = [
        PresetExercise(
            name: "Barbell Deadlift",
            muscleGroup: "Back",
            description: "Lift barbell from floor to hip height, keeping back straight throughout.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Barbell Row",
            muscleGroup: "Back",
            description: "Bend forward, pull barbell to lower chest, squeeze shoulder blades together.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Lat Pull-Down",
            muscleGroup: "Back",
            description: "Pull bar down to upper chest, focusing on lat engagement.",
            tags: ["cable"]
        ),
        PresetExercise(
            name: "Dumbbell Row",
            muscleGroup: "Back",
            description: "Row dumbbell to hip with elbow close to body, one arm at a time.",
            tags: ["dumbbells", "unilateral"]
        ),
        PresetExercise(
            name: "Pull-Ups",
            muscleGroup: "Back",
            description: "Hang from bar, pull body up until chin is above bar.",
            tags: ["bodyweight", "compound"]
        )
    ]

    // MARK: - Shoulders (4 exercises)
    static let shoulders: [PresetExercise] = [
        PresetExercise(
            name: "Overhead Press",
            muscleGroup: "Shoulders",
            description: "Press barbell from shoulder height to overhead in one smooth motion.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Dumbbell Shoulder Press",
            muscleGroup: "Shoulders",
            description: "Press dumbbells overhead from shoulder height until arms are extended.",
            tags: ["dumbbells", "compound"]
        ),
        PresetExercise(
            name: "Lateral Raise",
            muscleGroup: "Shoulders",
            description: "Raise dumbbells out to sides until arms are parallel with floor.",
            tags: ["dumbbells", "unilateral", "isolation"]
        ),
        PresetExercise(
            name: "Face Pull",
            muscleGroup: "Shoulders",
            description: "Pull rope attachment towards face, focusing on rear delts.",
            tags: ["cable"]
        )
    ]

    // MARK: - Biceps (3 exercises)
    static let biceps: [PresetExercise] = [
        PresetExercise(
            name: "Barbell Curl",
            muscleGroup: "Biceps",
            description: "Curl barbell up to shoulders, keeping elbows stationary.",
            tags: ["barbell"]
        ),
        PresetExercise(
            name: "Dumbbell Curl",
            muscleGroup: "Biceps",
            description: "Curl dumbbells alternately or together, rotating palms up at top.",
            tags: ["dumbbells", "unilateral"]
        ),
        PresetExercise(
            name: "Hammer Curl",
            muscleGroup: "Biceps",
            description: "Curl dumbbells with neutral grip (palms facing each other).",
            tags: ["dumbbells", "unilateral"]
        )
    ]

    // MARK: - Triceps (3 exercises)
    static let triceps: [PresetExercise] = [
        PresetExercise(
            name: "Close-Grip Bench Press",
            muscleGroup: "Triceps",
            description: "Bench press with hands closer together to emphasise triceps.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Tricep Dips",
            muscleGroup: "Triceps",
            description: "Lower body between parallel bars, push back up to start.",
            tags: ["bodyweight"]
        ),
        PresetExercise(
            name: "Cable Pushdown",
            muscleGroup: "Triceps",
            description: "Push cable attachment down, extending arms fully at bottom.",
            tags: ["cable"]
        )
    ]

    // MARK: - Legs (5 exercises)
    static let legs: [PresetExercise] = [
        PresetExercise(
            name: "Barbell Squat",
            muscleGroup: "Legs",
            description: "Lower hips until thighs are parallel to floor, drive through heels to stand.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Romanian Deadlift",
            muscleGroup: "Legs",
            description: "Lower barbell by hinging at hips, keeping legs mostly straight to target hamstrings.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Leg Press",
            muscleGroup: "Legs",
            description: "Push platform away by extending legs, control descent back to start.",
            tags: ["machine", "compound"]
        ),
        PresetExercise(
            name: "Bulgarian Split Squat",
            muscleGroup: "Legs",
            description: "Rear foot elevated, lower front leg until thigh is parallel to floor.",
            tags: ["dumbbells", "unilateral"]
        ),
        PresetExercise(
            name: "Calf Raise",
            muscleGroup: "Legs",
            description: "Rise up onto toes, hold briefly, lower back down with control.",
            tags: ["machine", "unilateral"]
        )
    ]

    // MARK: - Core (4 exercises)
    static let core: [PresetExercise] = [
        PresetExercise(
            name: "Plank",
            muscleGroup: "Core",
            description: "Hold rigid body position on forearms and toes, maintain straight line.",
            tags: ["bodyweight", "isometric"]
        ),
        PresetExercise(
            name: "Ab Wheel Rollout",
            muscleGroup: "Core",
            description: "Roll wheel forward while maintaining straight body, return to start.",
            tags: ["equipment"]
        ),
        PresetExercise(
            name: "Hanging Leg Raise",
            muscleGroup: "Core",
            description: "Hang from bar, raise legs to 90 degrees, lower with control.",
            tags: ["bodyweight"]
        ),
        PresetExercise(
            name: "Cable Crunch",
            muscleGroup: "Core",
            description: "Kneel with rope attachment, crunch abs down towards floor.",
            tags: ["cable"]
        )
    ]

    // MARK: - Full Body (3 exercises)
    static let fullBody: [PresetExercise] = [
        PresetExercise(
            name: "Barbell Clean",
            muscleGroup: "Full Body",
            description: "Explosively pull barbell from floor to shoulders in one motion.",
            tags: ["barbell", "compound"]
        ),
        PresetExercise(
            name: "Kettlebell Swing",
            muscleGroup: "Full Body",
            description: "Swing kettlebell between legs and up to chest height using hip thrust.",
            tags: ["kettlebell", "compound"]
        ),
        PresetExercise(
            name: "Burpees",
            muscleGroup: "Full Body",
            description: "Drop to press-up, jump feet back in, jump up explosively.",
            tags: ["bodyweight", "compound"]
        )
    ]

    // MARK: - All Presets
    /// All preset exercises across all muscle groups (excluding Other)
    static let all: [PresetExercise] = chest + back + shoulders + biceps + triceps + legs + core + fullBody

    /// Preset exercises grouped by muscle group for display
    static let grouped: [(muscleGroup: String, exercises: [PresetExercise])] = [
        ("Chest", chest),
        ("Back", back),
        ("Shoulders", shoulders),
        ("Biceps", biceps),
        ("Triceps", triceps),
        ("Legs", legs),
        ("Core", core),
        ("Full Body", fullBody)
    ]
}
