//
//  WorkoutEditView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]

    let workout: WorkoutEntry

    @State private var workoutName: String
    @State private var workoutDate: Date
    @State private var workoutExercises: [WorkoutExerciseEntry]
    @State private var workoutNotes: String
    @State private var showingExercisePicker = false
    @State private var showingDeleteConfirmation = false
    @State private var showingSaveAsRoutine = false
    @FocusState private var focusedField: FieldID?

    // Calculate all fields across all exercises for keyboard navigation
    private var allFields: [FieldID] {
        var fields: [FieldID] = []
        for exercise in workoutExercises {
            for setIndex in exercise.sets.indices {
                for dropSetIndex in exercise.sets[setIndex].weightsAndReps.indices {
                    fields.append(FieldID(setIndex: setIndex, dropSetIndex: dropSetIndex, isWeight: true))
                    fields.append(FieldID(setIndex: setIndex, dropSetIndex: dropSetIndex, isWeight: false))
                }
            }
        }
        return fields
    }

    // Cached previous workout data lookup - prevents N+1 query pattern
    private var previousWorkoutDataCache: [UUID: WorkoutExerciseData] {
        var cache: [UUID: WorkoutExerciseData] = [:]
        for otherWorkout in allWorkouts {
            // Skip current workout and only look at workouts before the current one
            guard otherWorkout.id != workout.id, otherWorkout.workoutDate < workoutDate else {
                continue
            }
            for exerciseData in otherWorkout.exercisesData {
                // Only keep the most recent (first occurrence due to reverse sort)
                if cache[exerciseData.exerciseID] == nil {
                    cache[exerciseData.exerciseID] = exerciseData
                }
            }
        }
        return cache
    }

    init(workout: WorkoutEntry) {
        self.workout = workout
        _workoutName = State(initialValue: workout.workoutName)
        _workoutDate = State(initialValue: workout.workoutDate)
        _workoutNotes = State(initialValue: workout.notes ?? "")

        // Convert WorkoutExerciseData to WorkoutExerciseEntry for editing
        let entries = workout.exercisesData.map { data in
            WorkoutExerciseEntry(
                exerciseID: data.exerciseID,
                exerciseName: data.exerciseName,
                sets: data.sets,
                notes: data.notes
            )
        }
        _workoutExercises = State(initialValue: entries)
    }

    var body: some View {
        NavigationStack {
            List {
                // Header Section - Workout Name and Date
                Section {
                    TextField("Workout Name", text: $workoutName)
                        .font(.title2.bold())

                    DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "en_GB"))
                } header: {
                    Text("Workout Details")
                }

                // Exercises Section
                if !workoutExercises.isEmpty {
                    ForEach($workoutExercises) { $exerciseEntry in
                        Section {
                            ExerciseEntryView(
                                exerciseEntry: $exerciseEntry,
                                previousData: previousWorkoutDataCache[exerciseEntry.exerciseID],
                                focusedField: $focusedField
                            )
                        } header: {
                            HStack {
                                Text(exerciseEntry.exerciseName)
                                    .font(.headline)
                                Spacer()
                                Button(role: .destructive) {
                                    removeExercise(exerciseEntry)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                // Add Exercise Button
                Section {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }

                // Notes Section
                Section {
                    TextField("Workout notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Edit Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .destructiveAction) {
                    Button(role: .destructive) {
                        showingDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                }
                ToolbarItem(placement: .primaryAction) {
                    Menu {
                        Button {
                            showingSaveAsRoutine = true
                        } label: {
                            Label("Save as Routine", systemImage: "arrow.triangle.2.circlepath")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(workoutExercises.isEmpty || workoutName.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $workoutExercises)
            }
            .keyboardToolbar(focusedField: $focusedField, allFields: allFields)
            .sheet(isPresented: $showingSaveAsRoutine) {
                SaveWorkoutAsTemplateView(workoutExercises: workoutExercises, defaultName: workoutName)
            }
            .confirmationDialog("Delete this workout?", isPresented: $showingDeleteConfirmation, titleVisibility: .visible) {
                Button("Delete Workout", role: .destructive) {
                    deleteWorkout()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
        }
    }

    private func removeExercise(_ exercise: WorkoutExerciseEntry) {
        HapticManager.shared.trigger(.light)
        workoutExercises.removeAll { $0.id == exercise.id }
    }


    private func saveWorkout() {
        // Convert WorkoutExerciseEntry back to WorkoutExerciseData
        let exercisesData = workoutExercises.map { entry in
            WorkoutExerciseData(
                exerciseID: entry.exerciseID,
                exerciseName: entry.exerciseName,
                sets: entry.sets,
                notes: entry.notes
            )
        }

        // Update the existing workout
        workout.workoutName = workoutName
        workout.workoutDate = workoutDate
        workout.exercisesData = exercisesData
        workout.notes = workoutNotes.isEmpty ? nil : workoutNotes

        HapticManager.shared.trigger(.success)
        dismiss()
    }

    private func deleteWorkout() {
        HapticManager.shared.trigger(.warning)
        modelContext.delete(workout)
        dismiss()
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutEntry.self, configurations: config)

    let workout = WorkoutEntry(
        name: "Test Workout",
        date: Date(),
        exercisesData: [
            WorkoutExerciseData(
                exerciseID: UUID(),
                exerciseName: "Bench Press",
                sets: [
                    WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 60, reps: 10)]),
                    WorkoutSet(setNumber: 2, weightsAndReps: [WeightRep(weight: 65, reps: 8)])
                ]
            )
        ]
    )
    container.mainContext.insert(workout)

    return WorkoutEditView(workout: workout)
        .modelContainer(container)
}