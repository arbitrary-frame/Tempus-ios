//
//  ExerciseFormView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct ExerciseFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    @State private var name: String = ""
    @State private var exerciseDescription: String = ""
    @State private var muscleGroup: MuscleGroup = .chest
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var showingValidationError = false
    @State private var validationMessage = ""

    let isEditing: Bool
    let exerciseToEdit: Exercise?

    init(exercise: Exercise? = nil) {
        self.isEditing = exercise != nil
        self.exerciseToEdit = exercise

        if let exercise = exercise {
            _name = State(initialValue: exercise.name)
            _exerciseDescription = State(initialValue: exercise.exerciseDescription ?? "")
            _muscleGroup = State(initialValue: MuscleGroup(rawValue: exercise.muscleGroup) ?? .chest)
            _tags = State(initialValue: exercise.tags)
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        NavigationStack {
            Form {
                Section("Basic Information") {
                    TextField("Exercise Name", text: $name)
                        .autocorrectionDisabled()

                    TextField("Description (optional)", text: $exerciseDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section("Classification") {
                    Picker("Muscle Group", selection: $muscleGroup) {
                        ForEach(MuscleGroup.allCases) { group in
                            Label {
                                Text(group.rawValue)
                            } icon: {
                                Image(systemName: group.icon)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.accent)
                            }
                            .tag(group)
                        }
                    }
                    .pickerStyle(.menu)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Tags")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)

                        // Display current tags with animations
                        if !tags.isEmpty {
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: 8) {
                                    ForEach(tags, id: \.self) { tag in
                                        HStack(spacing: 4) {
                                            Text(tag)
                                                .font(.caption)
                                            Button {
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                    removeTag(tag)
                                                }
                                            } label: {
                                                Image(systemName: "xmark.circle.fill")
                                                    .font(.caption)
                                                    .symbolRenderingMode(.hierarchical)
                                            }
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial, in: Capsule())
                                        .transition(.scale.combined(with: .opacity))
                                    }
                                }
                            }
                        }

                        // Suggested tags
                        let availableSuggestions = ExerciseTag.suggestedTags.filter { !tags.contains($0) }
                        if !availableSuggestions.isEmpty {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Suggested:")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)

                                FlowLayout(spacing: 8) {
                                    ForEach(availableSuggestions, id: \.self) { tag in
                                        Button {
                                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                addSuggestedTag(tag)
                                            }
                                        } label: {
                                            Text(tag)
                                                .font(.caption)
                                                .padding(.horizontal, 10)
                                                .padding(.vertical, 6)
                                        }
                                        .buttonStyle(.bordered)
                                    }
                                }

                                // Helpful tip for unilateral exercises
                                if availableSuggestions.contains("unilateral") {
                                    Text("💡 **Unilateral:** Single-limb exercises (dumbbell curls, single-leg presses) for accurate volume tracking")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                        .padding(.top, 2)
                                }
                            }
                        }

                        // Tag input
                        HStack {
                            TextField("Add custom tag", text: $tagInput)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled()
                                .onSubmit {
                                    addTag()
                                }

                            if !tagInput.isEmpty {
                                Button("Add") {
                                    addTag()
                                }
                                .buttonStyle(.borderedProminent)
                            }
                        }
                    }
                }

                if showingValidationError {
                    Section {
                        Text(validationMessage)
                            .foregroundStyle(.red)
                            .font(.caption)
                    }
                }
            }
            .navigationTitle(isEditing ? "Edit Exercise" : "New Exercise")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
        }
    }

    private func addTag() {
        let trimmedTag = tagInput.trimmingCharacters(in: .whitespaces)
        guard !trimmedTag.isEmpty, !tags.contains(trimmedTag) else {
            tagInput = ""
            return
        }
        HapticManager.shared.trigger(.light)
        tags.append(trimmedTag)
        tagInput = ""
    }

    private func addSuggestedTag(_ tag: String) {
        guard !tags.contains(tag) else { return }
        HapticManager.shared.trigger(.light)
        tags.append(tag)
    }

    private func removeTag(_ tag: String) {
        HapticManager.shared.trigger(.light)
        tags.removeAll { $0 == tag }
    }

    private func saveExercise() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)

        // Validate unique name (case-insensitive)
        let isDuplicate = allExercises.contains { exercise in
            exercise.name.lowercased() == trimmedName.lowercased() &&
            exercise.id != exerciseToEdit?.id
        }

        if isDuplicate {
            validationMessage = "An exercise with this name already exists"
            showingValidationError = true
            HapticManager.shared.trigger(.error)
            return
        }

        if isEditing, let exercise = exerciseToEdit {
            // Update existing exercise
            exercise.name = trimmedName
            exercise.exerciseDescription = exerciseDescription.isEmpty ? nil : exerciseDescription
            exercise.muscleGroup = muscleGroup.rawValue
            exercise.tags = tags
            exercise.updatedAt = Date()
        } else {
            // Create new exercise
            let newExercise = Exercise(
                name: trimmedName,
                muscleGroup: muscleGroup.rawValue,
                tags: tags,
                exerciseDescription: exerciseDescription.isEmpty ? nil : exerciseDescription
            )
            modelContext.insert(newExercise)
        }

        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

#Preview {
    ExerciseFormView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}