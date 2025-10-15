//
//  ArchivedRoutinesView.swift
//  Tempus
//
//  Created by Ronak Pattani on 15/10/2025.
//

import SwiftUI
import SwiftData

struct ArchivedRoutinesView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutRoutine.name) private var allRoutines: [WorkoutRoutine]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @State private var searchText = ""
    @State private var routineToRestore: WorkoutRoutine?
    @State private var showingRestoreConfirmation = false
    @State private var routineToDelete: WorkoutRoutine?
    @State private var showingDeleteConfirmation = false

    private var archivedRoutines: [WorkoutRoutine] {
        if searchText.isEmpty {
            return allRoutines.filter { $0.isArchived }
        } else {
            return allRoutines.filter { $0.isArchived && $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    // Check if routine has been used in any workouts
    private func isRoutineUsed(_ routine: WorkoutRoutine) -> Bool {
        return workouts.contains { workout in
            workout.routine?.id == routine.id
        }
    }

    private func restoreRoutine(_ routine: WorkoutRoutine) {
        routine.isArchived = false
        routine.updatedAt = Date()
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
    }

    private func confirmRestore() {
        guard let routine = routineToRestore else { return }
        restoreRoutine(routine)
        routineToRestore = nil
    }

    private func requestDelete(_ routine: WorkoutRoutine) {
        routineToDelete = routine
        showingDeleteConfirmation = true
    }

    private func confirmDelete() {
        guard let routine = routineToDelete else { return }
        modelContext.delete(routine)
        try? modelContext.save()
        HapticManager.shared.trigger(.success)
        routineToDelete = nil
    }

    var body: some View {
        Group {
            if archivedRoutines.isEmpty {
                ContentUnavailableView {
                    Label("No Archived Routines", systemImage: "archivebox")
                } description: {
                    Text("Routines you archive will appear here")
                }
            } else {
                List {
                    ForEach(archivedRoutines) { routine in
                        RoutineRowView(routine: routine)
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                // Restore is primary action
                                Button {
                                    routineToRestore = routine
                                    showingRestoreConfirmation = true
                                } label: {
                                    Label("Restore", systemImage: "arrow.uturn.backward")
                                }
                                .tint(.green)

                                // Only show delete if routine hasn't been used
                                if !isRoutineUsed(routine) {
                                    Button(role: .destructive) {
                                        requestDelete(routine)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                            }
                    }
                }
                .listStyle(.insetGrouped)
            }
        }
        .navigationTitle("Archived Routines")
        .navigationBarTitleDisplayMode(.inline)
        .searchable(text: $searchText, prompt: "Search archived routines")
        .alert("Restore this routine?", isPresented: $showingRestoreConfirmation) {
            Button("Restore") {
                confirmRestore()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            if let routine = routineToRestore {
                Text("'\(routine.name)' will be moved back to your routines list.")
            }
        }
        .alert("Delete this routine?", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                confirmDelete()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This action cannot be undone. The exercises in this routine will not be affected.")
        }
    }
}

#Preview {
    NavigationStack {
        ArchivedRoutinesView()
            .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
    }
}
