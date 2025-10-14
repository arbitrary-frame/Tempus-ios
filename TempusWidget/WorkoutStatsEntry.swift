//
//  WorkoutStatsEntry.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import WidgetKit

struct WorkoutStatsEntry: TimelineEntry {
    let date: Date
    let workoutsCompleted: Int
    let weeklyGoal: Int
    let exercisesThisWeek: Int
    let totalWeightThisWeek: Double
    let totalWeightLastWeek: Double?

    var progress: Double {
        guard weeklyGoal > 0 else { return 0 }
        return min(Double(workoutsCompleted) / Double(weeklyGoal), 1.0)
    }

    var formattedWeight: String {
        let kg = Int(totalWeightThisWeek)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }

    /// Week-on-week weight change in kg (nil if no previous week data)
    var weekOnWeekWeightChange: Double? {
        guard let lastWeek = totalWeightLastWeek, lastWeek > 0 else { return nil }
        return totalWeightThisWeek - lastWeek
    }

    /// Formatted week-on-week change (e.g., "+250", "-12.7k", "—")
    var weekOnWeekChangeFormatted: String {
        guard let change = weekOnWeekWeightChange else { return "—" }
        let kg = Int(change)

        if kg == 0 {
            return "—"
        }

        let absKg = abs(kg)
        let prefix = kg > 0 ? "+" : ""

        if absKg >= 1000 {
            return String(format: "%@%.1fk", prefix, Double(kg) / 1000.0)
        }

        return "\(prefix)\(kg)"
    }
}
