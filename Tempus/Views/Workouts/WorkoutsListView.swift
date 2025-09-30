//
//  WorkoutsListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @State private var showingWorkoutLogging = false

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts Yet", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Tap + to log your first workout")
                    }
                } else {
                    List {
                        ForEach(workouts) { workout in
                            WorkoutRowView(workout: workout)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingWorkoutLogging = true
                        print("DEBUG: Add workout button tapped")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingWorkoutLogging) {
                WorkoutLoggingView()
            }
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutEntry

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.workoutName)
                .font(.headline)

            HStack {
                Label("\(workout.exercisesData.count) exercises", systemImage: "figure.mixed.cardio")
                    .font(.caption)

                Spacer()

                Text(workout.workoutDate, style: .relative)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutsListView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}