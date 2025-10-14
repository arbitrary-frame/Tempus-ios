//
//  ExercisesListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct ExercisesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3
    @State private var searchText = ""
    @State private var showingCreateForm = false
    @State private var showingPresetBrowser = false
    @State private var selectedExercise: Exercise?
    @State private var showingDeleteConfirmation = false
    @State private var showingCannotDeleteAlert = false
    @State private var exerciseToDelete: Exercise?

    private var currentStreak: Int {
        AnalyticsHelper.calculateCurrentStreak(workouts: workouts, weeklyGoal: weeklyWorkoutGoal)
    }

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises.filter { !$0.isArchived }
        } else {
            return exercises.filter { !$0.isArchived && $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.muscleGroup }
    }

    // Check if exercise has been used in any workouts
    private func isExerciseUsed(_ exercise: Exercise) -> Bool {
        return workouts.contains { workout in
            workout.exercisesData.contains { $0.exerciseID == exercise.id }
        }
    }

    private func requestDelete(_ exercise: Exercise) {
        exerciseToDelete = exercise
        if isExerciseUsed(exercise) {
            showingCannotDeleteAlert = true
        } else {
            showingDeleteConfirmation = true
        }
    }

    private func confirmDelete() {
        guard let exercise = exerciseToDelete else { return }
        modelContext.delete(exercise)
        try? modelContext.save()
        exerciseToDelete = nil
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredExercises.isEmpty {
                    VStack(spacing: 24) {
                        ContentUnavailableView {
                            Label("No Exercises Yet", systemImage: "list.bullet.clipboard")
                        } description: {
                            Text("Get started with preset exercises or create your own")
                        }

                        VStack(spacing: 12) {
                            Button {
                                showingPresetBrowser = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.grid.3x3.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Browse Preset Exercises")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(Color.accentColor)
                                .foregroundStyle(.white)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }

                            Button {
                                showingCreateForm = true
                            } label: {
                                HStack {
                                    Image(systemName: "plus.circle")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Create Custom Exercise")
                                }
                                .font(.headline)
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(.regularMaterial)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                            }
                        }
                        .padding(.horizontal, 40)
                    }
                } else {
                    List {
                        ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
                            Section {
                                ForEach(groupedExercises[muscleGroup] ?? []) { exercise in
                                    Button {
                                        selectedExercise = exercise
                                    } label: {
                                        ExerciseRowView(exercise: exercise)
                                            .frame(maxWidth: .infinity, alignment: .leading)
                                            .contentShape(Rectangle())
                                    }
                                    .buttonStyle(.plain)
                                    .listRowBackground(
                                        RoundedRectangle(cornerRadius: 10)
                                            .fill(.ultraThinMaterial)
                                            .padding(.vertical, 2)
                                    )
                                    .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                        Button(role: .destructive) {
                                            requestDelete(exercise)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
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
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    StreakBadge(currentStreak: currentStreak, weeklyGoal: weeklyWorkoutGoal)

                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                ExerciseFormView()
            }
            .sheet(isPresented: $showingPresetBrowser) {
                PresetExercisesBrowserView()
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseFormView(exercise: exercise)
            }
            .alert("Delete this exercise?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone.")
            }
            .alert("Cannot Delete Exercise", isPresented: $showingCannotDeleteAlert) {
                Button("OK", role: .cancel) { }
            } message: {
                if let exercise = exerciseToDelete {
                    Text("'\(exercise.name)' has been used in past workouts and cannot be deleted. Historical workout data will be preserved.")
                }
            }
        }
    }
}

struct ExerciseRowView: View {
    let exercise: Exercise

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(exercise.name)
                .font(.headline)

            if !exercise.tags.isEmpty {
                HStack(spacing: 8) {
                    ForEach(exercise.tags.prefix(3), id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(Color.secondary.opacity(0.2))
                            .clipShape(Capsule())
                    }
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    ExercisesListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}