//
//  ExercisesWidget.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import SwiftUI
import WidgetKit

struct ExercisesWidget: Widget {
    let kind: String = "ExercisesWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutStatsProvider()) { entry in
            ExercisesWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Exercises This Week")
        .description("Number of exercises completed this week")
        .supportedFamilies([.systemSmall])
    }
}

struct ExercisesWidgetView: View {
    let entry: WorkoutStatsEntry
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        VStack(spacing: 6) {
            Text("This Week")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // Icon
            Image(systemName: "list.bullet.clipboard")
                .font(.system(size: 40))
                .foregroundStyle(Color.accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 50)

            // Value
            Text("\(entry.exercisesThisWeek)")
                .font(.system(size: 32, weight: .bold, design: .rounded))
                .minimumScaleFactor(0.5)
                .lineLimit(1)

            // Label
            Text("Exercises")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
        .widgetURL(URL(string: "tempus://workouts"))
        .widgetAccentable()
    }
}

#Preview(as: .systemSmall) {
    ExercisesWidget()
} timeline: {
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 2,
        weeklyGoal: 3,
        exercisesThisWeek: 8,
        totalWeightThisWeek: 1250.0
    )
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 3,
        weeklyGoal: 3,
        exercisesThisWeek: 15,
        totalWeightThisWeek: 1850.0
    )
}
