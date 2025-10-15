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
    @State private var showingPresetBrowser = false
    @State private var selectedRoutine: WorkoutRoutine?
    @State private var routineToStart: WorkoutRoutine?
    @State private var routineToDelete: WorkoutRoutine?
    @State private var showingDeleteConfirmation = false
    @State private var showingCannotDeleteAlert = false

    private var currentStreak: Int {
        AnalyticsHelper.calculateCurrentStreak(workouts: workouts, weeklyGoal: weeklyWorkoutGoal)
    }

    var filteredRoutines: [WorkoutRoutine] {
        routines.filter { !$0.isArchived }
    }

    var archivedRoutines: [WorkoutRoutine] {
        routines.filter { $0.isArchived }
    }

    var hasArchivedRoutines: Bool {
        !archivedRoutines.isEmpty
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredRoutines.isEmpty {
                    VStack(spacing: 0) {
                        Spacer()

                        VStack(spacing: 24) {
                            ContentUnavailableView {
                                Label("No Routines Yet", systemImage: "arrow.triangle.2.circlepath")
                            } description: {
                                Text("Get started with preset routines or create your own")
                            }

                            VStack(spacing: 12) {
                            Button {
                                showingPresetBrowser = true
                            } label: {
                                HStack {
                                    Image(systemName: "square.grid.3x3.fill")
                                        .symbolRenderingMode(.hierarchical)
                                    Text("Browse Preset Routines")
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
                                    Text("Create Routine")
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

                        Spacer()
                        Spacer()
                    }
                } else {
                    List {
                        // Archive entry point (WhatsApp-style)
                        if hasArchivedRoutines {
                            Section {
                                NavigationLink(destination: ArchivedRoutinesView()) {
                                    HStack {
                                        Image(systemName: "archivebox")
                                            .font(.title3)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.secondary)

                                        Text("Archived")
                                            .font(.headline)
                                            .foregroundStyle(.secondary)

                                        Spacer()

                                        Text("\(archivedRoutines.count)")
                                            .font(.subheadline)
                                            .foregroundStyle(.tertiary)

                                        Image(systemName: "chevron.right")
                                            .font(.caption)
                                            .foregroundStyle(.tertiary)
                                    }
                                    .padding(.vertical, 4)
                                }
                            }
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.regularMaterial)
                                    .padding(.vertical, 2)
                            )
                        }

                        ForEach(filteredRoutines) { routine in
                            Button {
                                selectedRoutine = routine
                            } label: {
                                RoutineRowView(routine: routine)
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
                                    requestDelete(routine)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    archiveRoutine(routine)
                                } label: {
                                    Label("Archive", systemImage: "archivebox")
                                }
                                .tint(.orange)

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
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    StreakBadge(currentStreak: currentStreak, weeklyGoal: weeklyWorkoutGoal)

                    Menu {
                        Button {
                            showingCreateForm = true
                        } label: {
                            Label("Create Routine", systemImage: "plus.circle")
                        }

                        Divider()

                        Button {
                            showingPresetBrowser = true
                        } label: {
                            Label("Add from Presets", systemImage: "square.grid.3x3.fill")
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                WorkoutRoutineFormView()
            }
            .sheet(isPresented: $showingPresetBrowser) {
                PresetRoutinesBrowserView()
            }
            .sheet(item: $selectedRoutine) { routine in
                WorkoutRoutineFormView(routine: routine)
            }
            .fullScreenCover(item: $routineToStart) { routine in
                WorkoutLoggingView(routine: routine)
            }
            .alert("Delete this routine?", isPresented: $showingDeleteConfirmation) {
                Button("Delete", role: .destructive) {
                    confirmDelete()
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("This action cannot be undone. The exercises in this routine will not be affected.")
            }
            .alert("Cannot Delete Routine", isPresented: $showingCannotDeleteAlert) {
                Button("Archive Instead", role: .destructive) {
                    archiveRoutine(routineToDelete)
                }
                Button("Cancel", role: .cancel) {
                    routineToDelete = nil
                }
            } message: {
                if let routine = routineToDelete {
                    Text("'\(routine.name)' has been used in past workouts and cannot be deleted. You can archive it instead to hide it from this list whilst preserving all historical data.")
                }
            }
        }
    }

    // Check if routine has been used in any workouts
    private func isRoutineUsed(_ routine: WorkoutRoutine) -> Bool {
        return workouts.contains { workout in
            workout.routine?.id == routine.id
        }
    }

    private func requestDelete(_ routine: WorkoutRoutine) {
        routineToDelete = routine
        if isRoutineUsed(routine) {
            showingCannotDeleteAlert = true
        } else {
            showingDeleteConfirmation = true
        }
    }

    private func confirmDelete() {
        guard let routine = routineToDelete else { return }
        modelContext.delete(routine)
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        routineToDelete = nil
    }

    private func archiveRoutine(_ routine: WorkoutRoutine?) {
        guard let routine else { return }
        routine.isArchived = true
        routine.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        routineToDelete = nil
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