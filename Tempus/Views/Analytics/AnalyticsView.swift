//
//  AnalyticsView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [WorkoutEntry]
    @Query private var exercises: [Exercise]
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3

    // Calculate total weeks where goal was met
    private var totalGoalsMet: Int {
        guard weeklyWorkoutGoal > 0 else { return 0 }

        let calendar = Calendar.current
        var weeksMetGoal = 0

        // Group workouts by week
        var workoutsByWeek: [Date: Int] = [:]

        for workout in workouts {
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)) else {
                continue
            }
            workoutsByWeek[weekStart, default: 0] += 1
        }

        // Count weeks that met goal
        for (_, count) in workoutsByWeek {
            if count >= weeklyWorkoutGoal {
                weeksMetGoal += 1
            }
        }

        return weeksMetGoal
    }

    // Calculate current streak of consecutive weeks meeting goal
    private var currentStreak: Int {
        guard weeklyWorkoutGoal > 0 else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var currentWeekDate = now
        var isCurrentWeek = true

        // Group workouts by week
        var workoutsByWeek: [Date: Int] = [:]
        for workout in workouts {
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)) else {
                continue
            }
            workoutsByWeek[weekStart, default: 0] += 1
        }

        // Get current week start for comparison
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return 0
        }

        // Count backwards from current week
        while true {
            guard let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentWeekDate)) else {
                break
            }

            let workoutsThisWeek = workoutsByWeek[weekStart] ?? 0

            if workoutsThisWeek >= weeklyWorkoutGoal {
                streak += 1
                // Move to previous week
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekDate) else {
                    break
                }
                currentWeekDate = previousWeek
                isCurrentWeek = false
            } else {
                // If this is the current week and it's not complete, don't break the streak yet
                if isCurrentWeek && weekStart == currentWeekStart {
                    // Current week in progress - move to previous week
                    guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekDate) else {
                        break
                    }
                    currentWeekDate = previousWeek
                    isCurrentWeek = false
                } else {
                    // Past week didn't meet goal - streak broken
                    break
                }
            }
        }

        return streak
    }

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Analytics Yet", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Log your first workout to see progress")
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Weekly Consistency Graph
                            ConsistencyGraphCard(workouts: workouts, weeklyGoal: weeklyWorkoutGoal)
                                .padding(.horizontal)

                            // Personal Records Card
                            PersonalRecordsCard(workouts: workouts, exercises: exercises)
                                .padding(.horizontal)
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Analytics")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    StreakBadge(currentStreak: currentStreak, weeklyGoal: weeklyWorkoutGoal)
                }
            }
        }
    }
}

// MARK: - Streak Badge Component
struct StreakBadge: View {
    let currentStreak: Int
    let weeklyGoal: Int
    @State private var showingInfo = false

    var body: some View {
        Button {
            HapticManager.shared.trigger(.light)
            showingInfo = true
        } label: {
            HStack(spacing: 4) {
                Text("🔥")
                    .font(.system(size: 18))
                Text("\(currentStreak)")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundStyle(.primary)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
        }
        .buttonStyle(NoHighlightButtonStyle())
        .popover(isPresented: $showingInfo, arrowEdge: .top) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Week Streak")
                    .font(.headline)

                Text("Consecutive weeks meeting your goal of \(weeklyGoal) workout\(weeklyGoal == 1 ? "" : "s") per week.")
                    .font(.subheadline)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding()
            .frame(width: 240)
            .presentationCompactAdaptation(.popover)
        }
    }
}

// MARK: - Custom Button Style
struct NoHighlightButtonStyle: ButtonStyle {
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .opacity(configuration.isPressed ? 0.9 : 1.0)
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
