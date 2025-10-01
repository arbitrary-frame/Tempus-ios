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
}
