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
                            }
                        }
                        .onMove(perform: moveExercise)
                        .onDelete(perform: deleteExercise)
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                } footer: {
                    if !selectedExercises.isEmpty {
                        Text("Drag to reorder • This determines exercise order when starting a workout")
                            .font(.caption)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .environment(\.editMode, .constant(.active))
            .navigationTitle(isEditing ? "Edit Routine" : "New Routine")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
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

    private func deleteExercise(at offsets: IndexSet) {
        HapticManager.shared.trigger(.light)
        selectedExercises.remove(atOffsets: offsets)
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        selectedExercises.move(fromOffsets: source, toOffset: destination)
        HapticManager.shared.trigger(.light)
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
        } else {
            // Create new routine
            let newRoutine = WorkoutRoutine(
                name: trimmedName,
                routineDescription: routineDescription.isEmpty ? nil : routineDescription,
                emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
                exercises: selectedExercises
            )
            modelContext.insert(newRoutine)
        }

        HapticManager.shared.trigger(.success)
        dismiss()
    }
}

// Exercise picker for routines
struct RoutineExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
    @State private var searchText = ""
    @State private var showingExerciseForm = false

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
                ToolbarItem(placement: .topBarLeading) {
                    Button {
                        showingExerciseForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExerciseForm) {
                ExerciseFormView()
            }
        }
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.id == exercise.id }
    }

    private func toggleExercise(_ exercise: Exercise) {
        HapticManager.shared.trigger(.selection)
        if isSelected(exercise) {
            selectedExercises.removeAll { $0.id == exercise.id }
        } else {
            selectedExercises.append(exercise)
        }
    }
}

#Preview {
    WorkoutRoutineFormView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}