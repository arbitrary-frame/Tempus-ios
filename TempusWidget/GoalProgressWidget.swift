//
//  GoalProgressWidget.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import SwiftUI
import WidgetKit

struct GoalProgressWidget: Widget {
    let kind: String = "GoalProgressWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutStatsProvider()) { entry in
            GoalProgressWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Workout Goal")
        .description("Track progress towards your weekly workout goal")
        .supportedFamilies([.systemSmall])
    }
}

struct GoalProgressWidgetView: View {
    let entry: WorkoutStatsEntry
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        VStack(spacing: 6) {
            Text("This Week")
                .font(.caption2)
                .foregroundStyle(.secondary)

            Spacer()

            // Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.2),
                        lineWidth: 6
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.workoutsCompleted >= entry.weeklyGoal ? Color.green : .orange,
                        style: StrokeStyle(lineWidth: 6, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))

                // Center text
                VStack(spacing: 2) {
                    Text("\(entry.workoutsCompleted)")
                        .font(.system(size: 28, weight: .bold, design: .rounded))
                    Text("/\(entry.weeklyGoal)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }
            .frame(height: 80)

            Text("Workouts")
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
    GoalProgressWidget()
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
        exercisesThisWeek: 12,
        totalWeightThisWeek: 1850.0
    )
}
