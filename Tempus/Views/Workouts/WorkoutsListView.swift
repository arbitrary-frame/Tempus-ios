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
    @Query(sort: \WorkoutRoutine.name) private var routines: [WorkoutRoutine]
    @State private var showingWorkoutLogging = false
    @State private var selectedWorkout: WorkoutEntry?
    @State private var showingRoutinePicker = false
    @State private var routineToStart: WorkoutRoutine?
    @AppStorage("userName") private var userName: String = ""

    private var navigationTitle: String {
        guard !userName.isEmpty else { return "Workouts" }

        let hour = Calendar.current.component(.hour, from: Date())
        let messages: [String]

        switch hour {
        case 5..<12:
            messages = [
                "Morning \(userName)",
                "Let's go \(userName)",
                "Ready \(userName)?",
                "Time to train \(userName)"
            ]
        case 12..<17:
            messages = [
                "Hey \(userName)",
                "Let's work \(userName)",
                "Ready \(userName)?",
                "Time to move \(userName)"
            ]
        case 17..<22:
            messages = [
                "Evening \(userName)",
                "Let's go \(userName)",
                "Ready \(userName)?",
                "Time to push \(userName)"
            ]
        default:
            messages = [
                "Hey \(userName)",
                "Can't sleep \(userName)?",
                "Night owl \(userName)?",
                "Late session \(userName)?"
            ]
        }

        return messages.randomElement() ?? messages[0]
    }

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
                            WorkoutCardView(workout: workout)
                                .onTapGesture {
                                    selectedWorkout = workout
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWorkout(workout)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                }
            }
            .navigationTitle(navigationTitle)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingWorkoutLogging = true
                        } label: {
                            Label("Quick Log", systemImage: "plus.circle")
                        }

                        if !routines.isEmpty {
                            Divider()

                            Menu {
                                ForEach(routines) { routine in
                                    Button {
                                        routineToStart = routine
                                    } label: {
                                        Text(routine.name)
                                    }
                                }
                            } label: {
                                Label("Start from Routine", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingWorkoutLogging) {
                WorkoutLoggingView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                WorkoutEditView(workout: workout)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .fullScreenCover(item: $routineToStart) { routine in
                WorkoutLoggingView(routine: routine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func deleteWorkout(_ workout: WorkoutEntry) {
        HapticManager.shared.trigger(.warning)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(workout)
        }
    }
}

// Enhanced Workout Card with Liquid Glass effects
struct WorkoutCardView: View {
    let workout: WorkoutEntry
    @State private var isPressed = false

    var formattedDate: String {
        let calendar = Calendar.current
        let now = Date()
        let interval = now.timeIntervalSince(workout.workoutDate)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes <= 1 ? "1 min ago" : "\(minutes) mins ago"
        }

        if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        if calendar.isDateInYesterday(workout.workoutDate) {
            return "Yesterday"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter.string(from: workout.workoutDate)
    }

    var body: some View {
        ZStack {
            // Liquid Glass background with depth
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Show routine emoji if workout created from routine, otherwise default icon
                    if let emoji = workout.routine?.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.largeTitle)
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title)
                            .symbolRenderingMode(.multicolor)
                    }

                    Spacer()

                    // Exercise count badge
                    HStack(spacing: 4) {
                        Image(systemName: "figure.mixed.cardio")
                            .font(.caption)
                        Text("\(workout.exercisesData.count)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutName)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

#Preview {
    WorkoutsListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}