//
//  SaveWorkoutAsRoutineView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct SaveWorkoutAsTemplateView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    let workoutExercises: [WorkoutExerciseEntry]
    @State private var routineName: String
    @State private var routineDescription: String = ""
    @State private var emoji: String = ""

    init(workoutExercises: [WorkoutExerciseEntry], defaultName: String) {
        self.workoutExercises = workoutExercises
        _routineName = State(initialValue: defaultName + " Routine")
    }

    var isValid: Bool {
        !routineName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Routine Details") {
                    HStack(spacing: 12) {
                        EmojiIconPicker(selectedEmoji: Binding(
                            get: { emoji.isEmpty ? nil : emoji },
                            set: { emoji = $0 ?? "" }
                        ))

                        TextField("Routine Name", text: $routineName)
                            .autocorrectionDisabled()
                    }

                    TextField("Description (optional)", text: $routineDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Exercises") {
                    ForEach(workoutExercises) { entry in
                        HStack {
                            if let exercise = allExercises.first(where: { $0.id == entry.exerciseID }),
                               let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                                Image(systemName: group.icon)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Text(entry.exerciseName)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Save as Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveRoutine()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveRoutine() {
        let trimmedName = routineName.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)

        // Get the actual Exercise objects
        let exercises = workoutExercises.compactMap { entry in
            allExercises.first(where: { $0.id == entry.exerciseID })
        }

        let routine = WorkoutRoutine(
            name: trimmedName,
            routineDescription: routineDescription.isEmpty ? nil : routineDescription,
            emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
            exercises: exercises
        )

        modelContext.insert(routine)
        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

#Preview {
    SaveWorkoutAsTemplateView(
        workoutExercises: [],
        defaultName: "Push Day"
    )
    .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}