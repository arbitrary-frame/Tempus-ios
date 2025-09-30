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

    private var currentStreak: Int {
        let calendar = Calendar.current
        var streak = 0
        var currentDate = calendar.startOfDay(for: Date())

        for workout in workouts {
            let workoutDate = calendar.startOfDay(for: workout.workoutDate)
            let daysDiff = calendar.dateComponents([.day], from: workoutDate, to: currentDate).day ?? 0

            if daysDiff == streak {
                streak += 1
            } else if daysDiff > streak {
                break
            }
        }

        return streak
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts Yet", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Tap + to log your first workout")
                    }
                } else {
                    // Statistics Summary Card - distinct header section
                    WorkoutStatsCard(
                        workoutsThisWeek: workoutsThisWeek,
                        totalExercises: totalExercisesCompleted,
                        totalSets: totalSetsCompleted,
                        currentStreak: currentStreak
                    )
                    .padding(.horizontal, 16)
                    .padding(.top, 8)
                    .padding(.bottom, 12)

                    // Workouts List
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
    let currentStreak: Int

    var body: some View {
        ZStack {
            // Liquid Glass background
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(spacing: 16) {
                HStack(spacing: 4) {
                    Image(systemName: "chart.bar.fill")
                        .font(.title3)
                        .foregroundStyle(.accent)
                        .symbolRenderingMode(.hierarchical)
                    Text("This Week")
                        .font(.headline)
                        .foregroundStyle(.primary)
                    Spacer()
                }

                // Statistics Grid
                HStack(spacing: 12) {
                    StatBubble(
                        value: "\(workoutsThisWeek)",
                        label: "Workouts",
                        icon: "figure.strengthtraining.traditional"
                    )

                    StatBubble(
                        value: "\(totalExercises)",
                        label: "Exercises",
                        icon: "list.bullet.clipboard"
                    )

                    StatBubble(
                        value: "\(totalSets)",
                        label: "Sets",
                        icon: "square.stack.3d.up.fill"
                    )

                    if currentStreak > 0 {
                        StatBubble(
                            value: "\(currentStreak)",
                            label: currentStreak == 1 ? "Day" : "Days",
                            icon: "flame.fill",
                            accentColor: .orange
                        )
                    }
                }
            }
            .padding(20)
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
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.title2.bold())
                .foregroundStyle(.primary)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutsListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}