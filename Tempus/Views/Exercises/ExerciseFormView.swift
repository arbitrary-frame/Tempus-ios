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
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]

    @State private var name: String = ""
    @State private var exerciseDescription: String = ""
    @State private var muscleGroup: MuscleGroup?
    @State private var tagInput: String = ""
    @State private var tags: [String] = []
    @State private var showingValidationError = false
    @State private var validationMessage = ""
    @State private var showingUnilateralMigrationConfirm = false
    @State private var pendingUnilateralChange: UnilateralChange?
    @State private var showingDeleteConfirmation = false
    @State private var showingArchiveConfirmation = false
    @State private var showingCannotDeleteAlert = false

    enum UnilateralChange {
        case addingUnilateral
        case removingUnilateral

        var affectedWorkoutsCount: Int {
            // Will be set when showing dialog
            0
        }
    }

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
        !name.trimmingCharacters(in: .whitespaces).isEmpty && muscleGroup != nil
    }

    private func affectedWorkoutsCount(for exerciseID: UUID) -> Int {
        return allWorkouts.filter { workout in
            workout.exercisesData.contains { $0.exerciseID == exerciseID }
        }.count
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
                        Text("Select")
                            .tag(nil as MuscleGroup?)
                        ForEach(MuscleGroup.allCases) { group in
                            Label {
                                Text(group.rawValue)
                            } icon: {
                                Image(systemName: group.icon)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.accent)
                            }
                            .tag(group as MuscleGroup?)
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

                        // Suggested tags (default + custom from user's exercises)
                        let allSuggestedTags = ExerciseTag.getSuggestedTags(from: allExercises)
                        let availableSuggestions = allSuggestedTags.filter { !tags.contains($0) }
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
                if isEditing {
                    ToolbarItem(placement: .primaryAction) {
                        Menu {
                            Button(role: .destructive) {
                                requestDelete()
                            } label: {
                                Label("Delete", systemImage: "trash")
                            }

                            Button {
                                showingArchiveConfirmation = true
                            } label: {
                                Label("Archive", systemImage: "archivebox")
                            }
                        } label: {
                            Image(systemName: "ellipsis.circle")
                        }
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveExercise()
                    }
                    .disabled(!isValid)
                }
            }
            .alert("Unilateral Tag Changed", isPresented: $showingUnilateralMigrationConfirm) {
                Button("Cancel", role: .cancel) {
                    // Revert tag change
                    if let change = pendingUnilateralChange {
                        switch change {
                        case .addingUnilateral:
                            tags.removeAll { $0 == "unilateral" }
                        case .removingUnilateral:
                            tags.append("unilateral")
                        }
                    }
                    pendingUnilateralChange = nil
                }
                Button("Update All Workouts", role: .destructive) {
                    saveExerciseWithMigration()
                }
            } message: {
                if let change = pendingUnilateralChange, let exercise = exerciseToEdit {
                    let count = affectedWorkoutsCount(for: exercise.id)
                    switch change {
                    case .addingUnilateral:
                        Text("You've added the 'unilateral' tag to this exercise. This exercise appears in \(count) workout\(count == 1 ? "" : "s"). All logged weights will be automatically halved (e.g., 60kg → 30kg) to maintain accurate volume tracking.\n\nAlternatively, cancel and create a new exercise instead.")
                    case .removingUnilateral:
                        Text("You've removed the 'unilateral' tag from this exercise. This exercise appears in \(count) workout\(count == 1 ? "" : "s"). All logged weights will be automatically doubled (e.g., 30kg → 60kg) to maintain accurate volume tracking.\n\nAlternatively, cancel and create a new exercise instead.")
                    }
                }
            }
            .alert("Cannot Delete Exercise", isPresented: $showingCannotDeleteAlert) {
                Button("Cancel", role: .cancel) {}
                Button("Archive Instead") {
                    showingArchiveConfirmation = true
                }
            } message: {
                Text("This exercise is used in your workout history and cannot be deleted. Would you like to archive it instead? Archived exercises are hidden from the library but remain in your workout history.")
            }
            .alert("Delete this exercise?", isPresented: $showingDeleteConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Delete Exercise", role: .destructive) {
                    confirmDelete()
                }
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Archive this exercise?", isPresented: $showingArchiveConfirmation) {
                Button("Cancel", role: .cancel) {}
                Button("Archive Exercise", role: .destructive) {
                    confirmArchive()
                }
            } message: {
                Text("This exercise will be hidden from the library but remain in your workout history.")
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

        // Check if unilateral status changed for an existing exercise with workouts
        if isEditing, let exercise = exerciseToEdit {
            let oldIsUnilateral = exercise.tags.contains("unilateral")
            let newIsUnilateral = tags.contains("unilateral")
            let affectedCount = affectedWorkoutsCount(for: exercise.id)

            if oldIsUnilateral != newIsUnilateral && affectedCount > 0 {
                // Show confirmation dialog
                pendingUnilateralChange = newIsUnilateral ? .addingUnilateral : .removingUnilateral
                showingUnilateralMigrationConfirm = true
                return
            }

            // No unilateral change or no workouts affected - save directly
            exercise.name = trimmedName
            exercise.exerciseDescription = exerciseDescription.isEmpty ? nil : exerciseDescription
            if let muscleGroup = muscleGroup {
                exercise.muscleGroup = muscleGroup.rawValue
            }
            exercise.tags = tags
            exercise.updatedAt = Date()
        } else {
            // Create new exercise
            guard let muscleGroup = muscleGroup else { return }
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

    private func saveExerciseWithMigration() {
        guard let exercise = exerciseToEdit, let change = pendingUnilateralChange else {
            dismiss()
            return
        }

        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let newIsUnilateral = tags.contains("unilateral")

        // Update all affected workouts
        for workout in allWorkouts {
            var needsUpdate = false
            var updatedExercisesData = workout.exercisesData

            for (index, exerciseData) in updatedExercisesData.enumerated() where exerciseData.exerciseID == exercise.id {
                needsUpdate = true

                // Update isUnilateral flag
                var updatedSets = exerciseData.sets

                // Adjust weights in all sets
                for (setIndex, set) in updatedSets.enumerated() {
                    var updatedWeightsAndReps = set.weightsAndReps

                    for (weightRepIndex, weightRep) in updatedWeightsAndReps.enumerated() {
                        var updatedWeightRep = weightRep

                        switch change {
                        case .addingUnilateral:
                            // Halve the weight (was non-unilateral, now unilateral)
                            updatedWeightRep.weight = weightRep.weight / 2.0
                        case .removingUnilateral:
                            // Double the weight (was unilateral, now non-unilateral)
                            updatedWeightRep.weight = weightRep.weight * 2.0
                        }

                        updatedWeightsAndReps[weightRepIndex] = updatedWeightRep
                    }

                    updatedSets[setIndex] = WorkoutSet(
                        setNumber: set.setNumber,
                        weightsAndReps: updatedWeightsAndReps
                    )
                }

                // Create new WorkoutExerciseData with updated values
                updatedExercisesData[index] = WorkoutExerciseData(
                    exerciseID: exerciseData.exerciseID,
                    exerciseName: exerciseData.exerciseName,
                    isUnilateral: newIsUnilateral,
                    sets: updatedSets,
                    notes: exerciseData.notes
                )
            }

            if needsUpdate {
                workout.exercisesData = updatedExercisesData
            }
        }

        // Update the exercise itself
        exercise.name = trimmedName
        exercise.exerciseDescription = exerciseDescription.isEmpty ? nil : exerciseDescription
        if let muscleGroup = muscleGroup {
            exercise.muscleGroup = muscleGroup.rawValue
        }
        exercise.tags = tags
        exercise.updatedAt = Date()

        // Save context
        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
        } catch {
            print("ERROR: Failed to save migration: \(error)")
            HapticManager.shared.trigger(.error)
        }

        pendingUnilateralChange = nil
        dismiss()
    }

    private func isExerciseUsed() -> Bool {
        guard let exercise = exerciseToEdit else { return false }
        return allWorkouts.contains { workout in
            workout.exercisesData.contains { $0.exerciseID == exercise.id }
        }
    }

    private func requestDelete() {
        if isExerciseUsed() {
            showingCannotDeleteAlert = true
        } else {
            showingDeleteConfirmation = true
        }
    }

    private func confirmDelete() {
        guard let exercise = exerciseToEdit else { return }
        HapticManager.shared.trigger(.warning)

        // Dismiss first to avoid crash
        dismiss()

        // Delay deletion slightly to allow sheet to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            modelContext.delete(exercise)
            try? modelContext.save()
        }
    }

    private func confirmArchive() {
        guard let exercise = exerciseToEdit else { return }
        exercise.isArchived = true
        exercise.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

#Preview {
    ExerciseFormView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
