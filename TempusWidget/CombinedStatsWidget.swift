//
//  CombinedStatsWidget.swift
//  TempusWidget
//
//  Created by Ronak Pattani on 01/10/2025.
//

import SwiftUI
import WidgetKit

struct CombinedStatsWidget: Widget {
    let kind: String = "CombinedStatsWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: WorkoutStatsProvider()) { entry in
            CombinedStatsWidgetView(entry: entry)
                .containerBackground(for: .widget) {
                    Color.clear
                }
        }
        .configurationDisplayName("Weekly Stats")
        .description("All three workout stats in one widget")
        .supportedFamilies([.systemMedium])
    }
}

struct CombinedStatsWidgetView: View {
    let entry: WorkoutStatsEntry
    @Environment(\.widgetRenderingMode) var renderingMode

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

            HStack(spacing: 8) {
                // Goal Progress Ring
                goalRingCard

                // Exercises
                statCard(
                    icon: "list.bullet.clipboard",
                    value: "\(entry.exercisesThisWeek)",
                    label: "Exercises",
                    accentColor: .orange
                )

                // Weight with week-on-week change
                statCardWithChange(
                    icon: "dumbbell.fill",
                    value: entry.formattedWeight,
                    label: "kg",
                    accentColor: .orange,
                    change: entry.weekOnWeekWeightChange
                )
            }
        }
        .padding()
        .widgetURL(URL(string: "tempus://workouts"))
        .widgetAccentable()
    }

    private var goalRingCard: some View {
        VStack(spacing: 4) {
            // Progress Ring
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.2),
                        lineWidth: 4
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: entry.progress)
                    .stroke(
                        entry.workoutsCompleted >= entry.weeklyGoal ? Color.green : .orange,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
            }
            .frame(height: 50)
            .aspectRatio(1, contentMode: .fit)

            // Value
            Text("\(entry.workoutsCompleted)/\(entry.weeklyGoal)")
                .font(.title3.bold())
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            // Label
            Text("Workouts")
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statCard(icon: String, value: String, label: String, accentColor: Color) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(accentColor)
                .symbolRenderingMode(.hierarchical)
                .frame(height: 50)

            Text(value)
                .font(.title3.bold())
                .minimumScaleFactor(0.8)
                .lineLimit(1)

            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .padding(.horizontal, 4)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func statCardWithChange(icon: String, value: String, label: String, accentColor: Color, change: Double?) -> some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 4) {
                Image(systemName: icon)
                    .font(.title2)
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 50)

                Text(value)
                    .font(.title3.bold())
                    .minimumScaleFactor(0.8)
                    .lineLimit(1)

                Text(label)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 8)
            .padding(.horizontal, 4)

            // Week-on-week change badge (top-left)
            if let weightChange = change, weightChange != 0 {
                let formattedChange = formatWeightChange(Int(weightChange))
                HStack(spacing: 1) {
                    Image(systemName: weightChange > 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 6, weight: .bold))
                    Text(formattedChange)
                        .font(.system(size: 7, weight: .semibold))
                }
                .foregroundStyle(weightChange > 0 ? .green : .secondary)
                .padding(.horizontal, 3)
                .padding(.vertical, 1)
                .background(
                    (weightChange > 0 ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1)),
                    in: Capsule()
                )
                .padding(4)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }

    private func formatWeightChange(_ change: Int) -> String {
        let absChange = abs(change)
        let prefix = change >= 0 ? "+" : "-"

        if absChange >= 1000 {
            return String(format: "%@%.1fk", prefix, Double(absChange) / 1000.0)
        }

        return "\(prefix)\(absChange)"
    }
}

#Preview(as: .systemMedium) {
    CombinedStatsWidget()
} timeline: {
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 2,
        weeklyGoal: 3,
        exercisesThisWeek: 8,
        totalWeightThisWeek: 1250.0,
        totalWeightLastWeek: 1000.0
    )
    WorkoutStatsEntry(
        date: Date(),
        workoutsCompleted: 3,
        weeklyGoal: 3,
        exercisesThisWeek: 15,
        totalWeightThisWeek: 2450.0,
        totalWeightLastWeek: 2200.0
    )
}
