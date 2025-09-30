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
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @State private var showingWorkoutLogging = false
    @State private var selectedWorkout: WorkoutEntry?
    @State private var showingTemplatePicker = false
    @State private var templateToStart: WorkoutTemplate?

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
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            ForEach(workouts) { workout in
                                WorkoutCardView(workout: workout)
                                    .onTapGesture {
                                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                            selectedWorkout = workout
                                        }
                                        print("DEBUG: Workout tapped - \(workout.workoutName)")
                                    }
                                    .contextMenu {
                                        Button(role: .destructive) {
                                            deleteWorkout(workout)
                                        } label: {
                                            Label("Delete", systemImage: "trash")
                                        }
                                    }
                                    .transition(.asymmetric(
                                        insertion: .scale.combined(with: .opacity),
                                        removal: .scale.combined(with: .opacity)
                                    ))
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle("Workouts")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Menu {
                        Button {
                            showingWorkoutLogging = true
                            print("DEBUG: Quick log workout tapped")
                        } label: {
                            Label("Quick Log", systemImage: "plus.circle")
                        }

                        if !templates.isEmpty {
                            Divider()

                            Menu {
                                ForEach(templates) { template in
                                    Button {
                                        templateToStart = template
                                        print("DEBUG: Starting workout from template - \(template.name)")
                                    } label: {
                                        Text(template.name)
                                    }
                                }
                            } label: {
                                Label("Start from Template", systemImage: "doc.text")
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
            .fullScreenCover(item: $templateToStart) { template in
                WorkoutLoggingView(template: template)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
    }

    private func deleteWorkout(_ workout: WorkoutEntry) {
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(workout)
        }
        print("DEBUG: Deleted workout - \(workout.workoutName)")
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
                    Image(systemName: "figure.strengthtraining.traditional")
                        .font(.title)
                        .symbolRenderingMode(.multicolor)

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
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}