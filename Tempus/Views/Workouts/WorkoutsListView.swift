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
    @State private var selectedWorkout: WorkoutEntry?

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
                            Button {
                                selectedWorkout = workout
                                print("DEBUG: Workout tapped - \(workout.workoutName)")
                            } label: {
                                WorkoutRowView(workout: workout)
                            }
                            .buttonStyle(.plain)
                        }
                        .onDelete(perform: deleteWorkouts)
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
            .fullScreenCover(item: $selectedWorkout) { workout in
                WorkoutEditView(workout: workout)
            }
        }
    }

    private func deleteWorkouts(at offsets: IndexSet) {
        for index in offsets {
            let workout = workouts[index]
            modelContext.delete(workout)
            print("DEBUG: Deleted workout - \(workout.workoutName)")
        }
    }
}

struct WorkoutRowView: View {
    let workout: WorkoutEntry

    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()

        // Get time interval
        let interval = now.timeIntervalSince(workout.workoutDate)

        // Less than 1 hour - show minutes
        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes <= 1 ? "1 min ago" : "\(minutes) mins ago"
        }

        // Less than 24 hours - show hours
        if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        // Check if yesterday
        if calendar.isDateInYesterday(workout.workoutDate) {
            return "Yesterday"
        }

        // More than 1 day - show actual date (UK format)
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workout.workoutDate)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(workout.workoutName)
                .font(.headline)

            HStack {
                Label("\(workout.exercisesData.count) exercises", systemImage: "figure.mixed.cardio")
                    .font(.caption)

                Spacer()

                Text(formattedDate)
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