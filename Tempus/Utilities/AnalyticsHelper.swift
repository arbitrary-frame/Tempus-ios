//
//  AnalyticsHelper.swift
//  Tempus
//
//  Created by Ronak Pattani on 03/10/2025.
//

import Foundation

struct AnalyticsHelper {
    /// Calculates the current weekly workout streak
    /// - Parameters:
    ///   - workouts: Array of workout entries
    ///   - weeklyGoal: Weekly workout goal target
    /// - Returns: Number of consecutive weeks meeting the goal
    static func calculateCurrentStreak(workouts: [WorkoutEntry], weeklyGoal: Int) -> Int {
        guard weeklyGoal > 0 else { return 0 }

        let calendar = Calendar.current
        let now = Date()
        var streak = 0
        var currentWeekDate = now
        var isCurrentWeek = true

        // Group workouts by week
        var workoutsByWeek: [Date: Int] = [:]
        for workout in workouts {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)
            ) else {
                continue
            }
            workoutsByWeek[weekStart, default: 0] += 1
        }

        // Get current week start for comparison
        guard let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) else {
            return 0
        }

        // Count backwards from current week
        while true {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: currentWeekDate)
            ) else {
                break
            }

            let workoutsThisWeek = workoutsByWeek[weekStart] ?? 0

            if workoutsThisWeek >= weeklyGoal {
                streak += 1
                guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekDate) else {
                    break
                }
                currentWeekDate = previousWeek
                isCurrentWeek = false
            } else {
                // If current week hasn't met goal yet, skip it and check previous weeks
                if isCurrentWeek && weekStart == currentWeekStart {
                    guard let previousWeek = calendar.date(byAdding: .weekOfYear, value: -1, to: currentWeekDate) else {
                        break
                    }
                    currentWeekDate = previousWeek
                    isCurrentWeek = false
                } else {
                    break
                }
            }
        }

        return streak
    }
}
