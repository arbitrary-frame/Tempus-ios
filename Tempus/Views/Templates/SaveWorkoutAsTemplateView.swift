//
//  SaveWorkoutAsTemplateView.swift
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
    @State private var templateName: String
    @State private var templateDescription: String = ""
    @State private var emoji: String = ""

    init(workoutExercises: [WorkoutExerciseEntry], defaultName: String) {
        self.workoutExercises = workoutExercises
        _templateName = State(initialValue: defaultName + " Template")
    }

    var isValid: Bool {
        !templateName.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Template Details") {
                    HStack(spacing: 12) {
                        EmojiIconPicker(selectedEmoji: Binding(
                            get: { emoji.isEmpty ? nil : emoji },
                            set: { emoji = $0 ?? "" }
                        ))

                        TextField("Template Name", text: $templateName)
                            .autocorrectionDisabled()
                    }

                    TextField("Description (optional)", text: $templateDescription, axis: .vertical)
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
            .navigationTitle("Save as Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveTemplate()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func saveTemplate() {
        let trimmedName = templateName.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)

        // Get the actual Exercise objects
        let exercises = workoutExercises.compactMap { entry in
            allExercises.first(where: { $0.id == entry.exerciseID })
        }

        let template = WorkoutTemplate(
            name: trimmedName,
            templateDescription: templateDescription.isEmpty ? nil : templateDescription,
            emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
            exercises: exercises
        )

        modelContext.insert(template)
        print("DEBUG: Saved workout as template - \(trimmedName)")
        dismiss()
    }
}

#Preview {
    SaveWorkoutAsTemplateView(
        workoutExercises: [],
        defaultName: "Push Day"
    )
    .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}