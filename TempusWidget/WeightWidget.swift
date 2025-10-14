//
//  WeightWidget.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import SwiftUI
import WidgetKit

struct WeightWidget: Widget {
    let kind: String = "WeightWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutStatsProvider()) { entry in
            WeightWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Weight This Week")
        .description("Total weight lifted this week")
        .supportedFamilies([.systemSmall])
    }
}

struct WeightWidgetView: View {
    let entry: WorkoutStatsEntry
    @Environment(\.widgetRenderingMode) var renderingMode

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 6) {
                Text("This Week")
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Spacer()

                // Icon
                Image(systemName: "dumbbell.fill")
                    .font(.system(size: 40))
                    .foregroundStyle(.orange)
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 50)

                // Value
                Text(entry.formattedWeight)
                    .font(.system(size: 32, weight: .bold, design: .rounded))
                    .minimumScaleFactor(0.5)
                    .lineLimit(1)

                // Label
                Text("kg")
                    .font(.caption)
                    .foregroundStyle(.secondary)

                Spacer()
            }

            // Week-on-week change badge (top-left corner overlay)
            if let change = entry.weekOnWeekWeightChange, change != 0 {
                HStack(spacing: 2) {
                    Image(systemName: change > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(entry.weekOnWeekChangeFormatted)
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(change > 0 ? .green : .secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    (change > 0 ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1)),
                    in: Capsule()
                )
                .padding(6)
            }
        }
        .padding()
        .widgetURL(URL(string: "tempus://workouts"))
        .widgetAccentable()
    }
}

#Preview(as: .systemSmall) {
    WeightWidget()
} timeline: {
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 2,
        weeklyGoal: 3,
        exercisesThisWeek: 8,
        totalWeightThisWeek: 450.0,
        totalWeightLastWeek: 400.0
    )
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 3,
        weeklyGoal: 3,
        exercisesThisWeek: 15,
        totalWeightThisWeek: 1850.0,
        totalWeightLastWeek: 1600.0
    )
}
