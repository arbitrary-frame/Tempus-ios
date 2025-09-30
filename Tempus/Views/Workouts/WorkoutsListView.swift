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
    @State private var currentGreeting: String = "Workouts"

    // Statistics computed properties
    private var workoutsThisWeek: Int {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }
        return workouts.filter { $0.workoutDate >= weekStart }.count
    }

    private var totalExercisesCompleted: Int {
        workouts.reduce(0) { $0 + $1.exercisesData.count }
    }

    private var totalSetsCompleted: Int {
        workouts.reduce(0) { total, workout in
            total + workout.exercisesData.reduce(0) { $0 + $1.sets.count }
        }
    }

    private var totalWeightThisWeek: Double {
        let calendar = Calendar.current
        let now = Date()
        guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }

        let workoutsThisWeek = workouts.filter { $0.workoutDate >= weekStart }
        var totalWeight: Double = 0

        for workout in workoutsThisWeek {
            for exercise in workout.exercisesData {
                for set in exercise.sets {
                    for weightRep in set.weightsAndReps {
                        totalWeight += weightRep.weight * Double(weightRep.reps)
                    }
                }
            }
        }

        return totalWeight
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
                        // Statistics Summary - scrolls with content
                        Section {
                            WorkoutStatsCard(
                                workoutsThisWeek: workoutsThisWeek,
                                totalExercises: totalExercisesCompleted,
                                totalSets: totalSetsCompleted,
                                totalWeight: totalWeightThisWeek
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)

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
            .navigationTitle(currentGreeting)
            .onAppear {
                updateGreeting()
            }
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

    private func updateGreeting() {
        guard !userName.isEmpty else {
            currentGreeting = "Workouts"
            return
        }

        currentGreeting = Self.generateGreeting(for: userName)
    }

    // Static method to generate greeting - can be precomputed or memoized
    private static func generateGreeting(for userName: String) -> String {
        let hour = Calendar.current.component(.hour, from: Date())

        let messages: [String] = switch hour {
        case 5..<12:
            [
                "Morning \(userName)",
                "Let's go \(userName)",
                "Ready \(userName)?",
                "Time to train \(userName)"
            ]
        case 12..<17:
            [
                "Hey \(userName)",
                "Let's work \(userName)",
                "Ready \(userName)?",
                "Time to move \(userName)"
            ]
        case 17..<22:
            [
                "Evening \(userName)",
                "Let's go \(userName)",
                "Ready \(userName)?",
                "Time to push \(userName)"
            ]
        default:
            [
                "Hey \(userName)",
                "Can't sleep \(userName)?",
                "Night owl \(userName)?",
                "Late session \(userName)?"
            ]
        }

        return messages.randomElement() ?? messages[0]
    }
}

// Enhanced Workout Card with Liquid Glass effects
struct WorkoutCardView: View {
    let workout: WorkoutEntry
    @State private var isPressed = false

    private static let calendar = Calendar.current
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var formattedDate: String {
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

        if Self.calendar.isDateInYesterday(workout.workoutDate) {
            return "Yesterday"
        }

        return Self.dateFormatter.string(from: workout.workoutDate)
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

// Workout Statistics Card
struct WorkoutStatsCard: View {
    let workoutsThisWeek: Int
    let totalExercises: Int
    let totalSets: Int
    let totalWeight: Double

    var formattedWeight: String {
        let kg = Int(totalWeight)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }

    var body: some View {
        VStack(spacing: 8) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            // Statistics Grid
            HStack(spacing: 8) {
                StatBubble(
                    value: "\(workoutsThisWeek)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional"
                )
                .frame(maxWidth: .infinity)

                StatBubble(
                    value: "\(totalExercises)",
                    label: "Exercises",
                    icon: "list.bullet.clipboard"
                )
                .frame(maxWidth: .infinity)

                StatBubble(
                    value: "\(totalSets)",
                    label: "Sets",
                    icon: "square.stack.3d.up.fill"
                )
                .frame(maxWidth: .infinity)

                StatBubble(
                    value: formattedWeight,
                    label: "kg",
                    icon: "dumbbell.fill",
                    accentColor: .orange
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// Individual Stat Bubble
struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    var accentColor: Color = .accentColor

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 22)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutsListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}