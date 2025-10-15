//
//  ArchivedExercisesView.swift
//  Tempus
//
//  Created by Ronak Pattani on 15/10/2025.
//

import SwiftUI
import SwiftData

struct ArchivedExercisesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @State private var searchText = ""
    @State private var exerciseToRestore: Exercise?
    @State private var showingRestoreConfirmation = false
    @State private var exerciseToDelete: Exercise?
    @State private var showingDeleteConfirmation = false

    private var archivedExercises: [Exercise] {
        if searchText.isEmpty {
            return allExercises.filter { $0.isArchived }
        } else {
            return allExercises.filter { $0.isArchived && $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    private var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: archivedExercises) { $0.muscleGroup }
    }

    // Check if exercise has been used in any workouts
    private func isExerciseUsed(_ exercise: Exercise) -> Bool {
        return workouts.contains { workout in
            workout.exercisesData.contains { $0.exerciseID == exercise.id }
        }
    }

    private func restoreExercise(_ exercise: Exercise) {
        exercise.isArchived = false
        exercise.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
    }

    private func confirmRestore() {
        guard let exercise = exerciseToRestore else { return }
        restoreExercise(exercise)
        exerciseToRestore = nil
    }

    private func requestDelete(_ exercise: Exercise) {
        exerciseToDelete = exercise
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        guard let exercise = exerciseToDelete else { return }
        modelContext.delete(exercise)
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        exerciseToDelete = nil
    }

    var body: some View {
        Group {
            if archivedExercises.isEmpty {
                ContentUnavailableView {
                    Label("No Archived Exercises", systemImage: "archivebox")
                } description: {
                    Text("Exercises you archive will appear here")
                }
            } else {
                List {
                    ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
                        Section {
                            ForEach(groupedExercises[muscleGroup] ?? []) { exercise in
                                ExerciseRowView(exercise: exercise)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        // Restore is primary action
                                        Button {
                                            exerciseToRestore = exercise
                                            showingRestoreConfirmation = true
                                        } label: {
                                            Label("Restore", systemImage: "arrow.uturn.backward")
                                        }
                                        .tint(.green)

                                        // Only show delete if exercise hasn't been used
                                        if !isExerciseUsed(exercise) {
                                            Button(role: .destructive) {
                                                requestDelete(exercise)
                                            } label: {
                                                Label("Delete", systemImage: "trash")
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
            }
        }
        .navigationTitle("Archived Exercises")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search archived exercises")
        .alert("Restore this exercise?", isPresented: $showingRestoreConfirmation) {
            Button("Restore") {
                confirmRestore()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let exercise = exerciseToRestore {
                Text("'\(exercise.name)' will be moved back to your exercises list.")
            }
        }
        .alert("Delete this exercise?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone.")
        }
    }
}

#Preview {
    NavigationStack {
        ArchivedExercisesView()
            .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
    }
}
