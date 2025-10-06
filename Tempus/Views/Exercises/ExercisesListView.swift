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
    @State private var selectedExercise: Exercise?

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

    var body: some View {
        NavigationStack {
            Group {
                if filteredExercises.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises Yet", systemImage: "list.bullet.clipboard")
                    } description: {
                        Text("Tap + to create your first exercise")
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
            .sheet(item: $selectedExercise) { exercise in
                ExerciseFormView(exercise: exercise)
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