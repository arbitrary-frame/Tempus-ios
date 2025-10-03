//
//  WorkoutRoutinesListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutRoutinesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRoutine.name) private var routines: [WorkoutRoutine]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3
    @State private var showingCreateForm = false
    @State private var selectedRoutine: WorkoutRoutine?
    @State private var routineToStart: WorkoutRoutine?
    @State private var cachedStreak: Int = 0

    private var currentStreak: Int {
        AnalyticsHelper.calculateCurrentStreak(workouts: workouts, weeklyGoal: weeklyWorkoutGoal)
    }

    var body: some View {
        NavigationStack {
            Group {
                if routines.isEmpty {
                    ContentUnavailableView {
                        Label("No Routines Yet", systemImage: "arrow.triangle.2.circlepath")
                    } description: {
                        Text("Create routines from your workouts to quickly start familiar training sessions")
                    }
                } else {
                    List {
                        ForEach(routines) { routine in
                            Button {
                                selectedRoutine = routine
                            } label: {
                                RoutineRowView(routine: routine)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                                    .padding(.vertical, 2)
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteRoutine(routine)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    routineToStart = routine
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                }
                                .tint(.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Routines")
            .onAppear {
                cachedStreak = currentStreak
            }
            .onChange(of: weeklyWorkoutGoal) { oldValue, newValue in
                cachedStreak = currentStreak
            }
            .onChange(of: workouts.count) { oldValue, newValue in
                cachedStreak = currentStreak
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    StreakBadge(currentStreak: cachedStreak, weeklyGoal: weeklyWorkoutGoal)

                    Button {
                        showingCreateForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                WorkoutRoutineFormView()
            }
            .sheet(item: $selectedRoutine) { routine in
                WorkoutRoutineFormView(routine: routine)
            }
            .fullScreenCover(item: $routineToStart) { routine in
                WorkoutLoggingView(routine: routine)
            }
        }
    }

    private func deleteRoutine(_ routine: WorkoutRoutine) {
        HapticManager.shared.trigger(.warning)
        withAnimation {
            modelContext.delete(routine)
        }
    }
}

struct RoutineRowView: View {
    let routine: WorkoutRoutine

    var body: some View {
        HStack(spacing: 12) {
            // Show emoji icon or default icon
            if let emoji = routine.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "arrow.triangle.2.circlepath")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(routine.name)
                    .font(.headline)

                HStack {
                    Image(systemName: "figure.mixed.cardio")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(routine.exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let description = routine.routineDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutRoutinesListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}