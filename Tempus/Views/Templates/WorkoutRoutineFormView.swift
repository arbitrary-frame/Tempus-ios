//
//  WorkoutRoutineFormView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutRoutineFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var name: String
    @State private var routineDescription: String
    @State private var emoji: String
    @State private var selectedExercises: [Exercise]
    @State private var showingExercisePicker = false

    let isEditing: Bool
    let routineToEdit: WorkoutRoutine?

    init(routine: WorkoutRoutine? = nil) {
        self.isEditing = routine != nil
        self.routineToEdit = routine

        if let routine = routine {
            _name = State(initialValue: routine.name)
            _routineDescription = State(initialValue: routine.routineDescription ?? "")
            _emoji = State(initialValue: routine.emoji ?? "")
            _selectedExercises = State(initialValue: routine.exercises)
        } else {
            _name = State(initialValue: "")
            _routineDescription = State(initialValue: "")
            _emoji = State(initialValue: "")
            _selectedExercises = State(initialValue: [])
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedExercises.isEmpty
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

                        TextField("Routine Name", text: $name)
                            .autocorrectionDisabled()
                    }

                    TextField("Description (optional)", text: $routineDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    if selectedExercises.isEmpty {
                        Text("No exercises added")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                if let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                                    Image(systemName: group.icon)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(exercise.name)
                                Spacer()
                                Button(role: .destructive) {
                                    removeExercise(exercise)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("DEBUG: Routine form cancelled")
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveRoutine()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                RoutineExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }

    private func removeExercise(_ exercise: Exercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
        print("DEBUG: Removed exercise from routine - \(exercise.name)")
    }

    private func saveRoutine() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)

        if isEditing, let routine = routineToEdit {
            // Update existing routine
            routine.name = trimmedName
            routine.routineDescription = routineDescription.isEmpty ? nil : routineDescription
            routine.emoji = trimmedEmoji.isEmpty ? nil : trimmedEmoji
            routine.exercises = selectedExercises
            routine.updatedAt = Date()
            print("DEBUG: Routine updated - \(trimmedName)")
        } else {
            // Create new routine
            let newRoutine = WorkoutRoutine(
                name: trimmedName,
                routineDescription: routineDescription.isEmpty ? nil : routineDescription,
                emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
                exercises: selectedExercises
            )
            modelContext.insert(newRoutine)
            print("DEBUG: Routine created - \(trimmedName)")
        }

        dismiss()
    }
}

// Exercise picker for routines
struct RoutineExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        let available = allExercises.filter { !$0.isArchived }
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.muscleGroup }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
                    Section {
                        ForEach(groupedExercises[muscleGroup]!) { exercise in
                            Button {
                                toggleExercise(exercise)
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    if isSelected(exercise) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.accent)
                                            .symbolRenderingMode(.hierarchical)
                                    }
                                }
                            }
                        }
                    } header: {
                        if let group = MuscleGroup(rawValue: muscleGroup) {
                            Label(muscleGroup, systemImage: group.icon)
                        } else {
                            Text(muscleGroup)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.id == exercise.id }
    }

    private func toggleExercise(_ exercise: Exercise) {
        if isSelected(exercise) {
            selectedExercises.removeAll { $0.id == exercise.id }
            print("DEBUG: Removed \(exercise.name) from routine")
        } else {
            selectedExercises.append(exercise)
            print("DEBUG: Added \(exercise.name) to routine")
        }
    }
}

#Preview {
    WorkoutRoutineFormView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}