//
//  WorkoutEditView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData
import WidgetKit

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
    @State private var showingReorderSheet = false
    @State private var selectedExerciseForHistory: Exercise?
    @FocusState private var focusedField: Bool

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
            WorkoutExerciseEntry(from: data)
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
                            HStack(spacing: 8) {
                                // Tapping the name opens the exercise's lift history
                                if let exercise = allExercises.first(where: { $0.id == exerciseEntry.exerciseID }) {
                                    Button {
                                        HapticManager.shared.trigger(.light)
                                        selectedExerciseForHistory = exercise
                                    } label: {
                                        HStack(spacing: 6) {
                                            Text(exerciseEntry.exerciseName)
                                                .font(.headline)
                                                .foregroundStyle(.primary)

                                            Image(systemName: "clock.arrow.circlepath")
                                                .font(.caption)
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundStyle(.secondary)
                                        }
                                    }
                                    .buttonStyle(.borderless)
                                } else {
                                    Text(exerciseEntry.exerciseName)
                                        .font(.headline)
                                }

                                // Unilateral badge (if applicable)
                                if exerciseEntry.isUnilateral {
                                    Text("Unilateral")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial, in: Capsule())
                                }

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
            .scrollDismissesKeyboard(.interactively)
            .navigationTitle("Edit")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            showingReorderSheet = true
                        } label: {
                            Label("Reorder Exercises", systemImage: "line.3.horizontal")
                        }
                        .disabled(workoutExercises.count < 2)

                        Button {
                            showingSaveAsRoutine = true
                        } label: {
                            Label("Save as Routine", systemImage: "arrow.triangle.2.circlepath")
                        }

                        Divider()

                        Button(role: .destructive) {
                            showingDeleteConfirmation = true
                        } label: {
                            Label("Delete Workout", systemImage: "trash")
                        }
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Image(systemName: "plus")
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
            .sheet(isPresented: $showingSaveAsRoutine) {
                SaveWorkoutAsTemplateView(workoutExercises: workoutExercises, defaultName: workoutName)
            }
            .sheet(isPresented: $showingReorderSheet) {
                WorkoutExerciseReorderView(exercises: $workoutExercises)
            }
            .sheet(item: $selectedExerciseForHistory) { exercise in
                ExerciseHistoryView(exercise: exercise, excludingWorkoutID: workout.id)
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
        // Look up current exercise to get latest isUnilateral status from tags
        let exercisesData = workoutExercises.map { entry in
            // Try to find the exercise in the current library
            let exercise = allExercises.first { $0.id == entry.exerciseID }
            let isUnilateral = exercise?.tags.contains("unilateral") ?? entry.isUnilateral

            return WorkoutExerciseData(
                exerciseID: entry.exerciseID,
                exerciseName: entry.exerciseName,
                isUnilateral: isUnilateral,
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

        // Dismiss first to avoid crash
        dismiss()

        // Delay deletion slightly to allow sheet to dismiss
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            modelContext.delete(workout)

            // Save and refresh widgets after deletion
            do {
                try modelContext.save()
                print("✅ Workout deleted from SwiftData (Edit View)")
            } catch {
                print("❌ Failed to save after deletion: \(error)")
            }

            print("🔄 Requesting widget refresh after deletion...")
            WidgetCenter.shared.reloadAllTimelines()
            WidgetCenter.shared.reloadTimelines(ofKind: "GoalProgressWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "ExercisesWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
            WidgetCenter.shared.reloadTimelines(ofKind: "CombinedStatsWidget")
        }
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