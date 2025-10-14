//
//  VolumeProgressionCard.swift
//  Tempus
//
//  Created by Ronak Pattani on 14/10/2025.
//

import SwiftUI
import Charts

struct VolumeProgressionCard: View {
    let workouts: [WorkoutEntry]

    @State private var selectedRange: DateRange = .smart
    @State private var rawSelectedDate: Date?

    enum DateRange: String, CaseIterable {
        case fourWeeks = "4W"
        case twelveWeeks = "12W"
        case sixMonths = "6M"
        case all = "All"
        case smart = "Smart" // Hidden option, used as default

        var weeks: Int? {
            switch self {
            case .fourWeeks: return 4
            case .twelveWeeks: return 12
            case .sixMonths: return 26
            case .all, .smart: return nil
            }
        }

        var displayName: String {
            switch self {
            case .smart: return "Auto"
            default: return rawValue
            }
        }
    }

    // Data structure for chart
    struct WeeklyVolumeData: Identifiable {
        let id = UUID()
        let weekStart: Date
        let totalVolume: Double
        let movingAverage: Double?
    }

    private var weeklyData: [WeeklyVolumeData] {
        let calendar = Calendar.current
        let now = Date()

        guard let currentWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)
        ) else {
            return []
        }

        // Find earliest workout
        guard let earliestWorkout = workouts.min(by: { $0.workoutDate < $1.workoutDate }) else {
            return []
        }

        guard let earliestWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: earliestWorkout.workoutDate)
        ) else {
            return []
        }

        // Group workouts by week and calculate volume
        var volumeByWeek: [Date: Double] = [:]
        for workout in workouts {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)
            ) else { continue }

            volumeByWeek[weekStart, default: 0] += workout.totalVolume
        }

        // Calculate total weeks from earliest to current
        let totalWeeks = calendar.dateComponents([.weekOfYear], from: earliestWeekStart, to: currentWeekStart).weekOfYear ?? 0

        // Determine start date based on selected range
        let startDate: Date
        switch selectedRange {
        case .smart:
            // Smart default: show last 12 weeks OR from earliest workout (whichever is shorter)
            if totalWeeks > 12 {
                startDate = calendar.date(byAdding: .weekOfYear, value: -11, to: currentWeekStart) ?? earliestWeekStart
            } else {
                startDate = earliestWeekStart
            }
        case .all:
            startDate = earliestWeekStart
        default:
            // Fixed ranges (4W, 12W, 6M)
            if let weeks = selectedRange.weeks {
                startDate = calendar.date(byAdding: .weekOfYear, value: -(weeks - 1), to: currentWeekStart) ?? earliestWeekStart
            } else {
                startDate = earliestWeekStart
            }
        }

        // Fill in weeks from start to current with volume data
        var allWeeks: [WeeklyVolumeData] = []
        var currentWeek = startDate

        while currentWeek <= currentWeekStart {
            let volume = volumeByWeek[currentWeek] ?? 0
            allWeeks.append(WeeklyVolumeData(weekStart: currentWeek, totalVolume: volume, movingAverage: nil))

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) else {
                break
            }
            currentWeek = nextWeek
        }

        // Calculate 4-week moving averages
        var dataWithAverages: [WeeklyVolumeData] = []
        for (index, week) in allWeeks.enumerated() {
            let movingAvg: Double?
            if index >= 3 {
                // Calculate average of this week and previous 3 weeks
                let last4Weeks = allWeeks[(index - 3)...index]
                let sum = last4Weeks.reduce(0.0) { $0 + $1.totalVolume }
                movingAvg = sum / 4.0
            } else {
                movingAvg = nil
            }

            dataWithAverages.append(WeeklyVolumeData(
                weekStart: week.weekStart,
                totalVolume: week.totalVolume,
                movingAverage: movingAvg
            ))
        }

        return dataWithAverages.sorted { $0.weekStart < $1.weekStart }
    }

    private var maxVolume: Double {
        weeklyData.map { $0.totalVolume }.max() ?? 0
    }

    private var totalWeeksOfData: Int {
        // Calculate total weeks from earliest to current workout
        guard let earliestWorkout = workouts.min(by: { $0.workoutDate < $1.workoutDate }),
              let latestWorkout = workouts.max(by: { $0.workoutDate < $1.workoutDate }) else {
            return 0
        }

        let calendar = Calendar.current
        guard let earliestWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: earliestWorkout.workoutDate)
        ),
              let latestWeekStart = calendar.date(
            from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: latestWorkout.workoutDate)
        ) else {
            return 0
        }

        return calendar.dateComponents([.weekOfYear], from: earliestWeekStart, to: latestWeekStart).weekOfYear ?? 0
    }

    private var xAxisStride: Int {
        // Dynamic stride: show fewer labels when there's more data to prevent overlap
        let count = weeklyData.count
        if count <= 4 {
            return 1  // Show every week
        } else if count <= 8 {
            return 2  // Show every 2 weeks
        } else if count <= 16 {
            return 3  // Show every 3 weeks
        } else {
            return 4  // Show every 4 weeks for very long ranges
        }
    }

    private var dateRangeText: String {
        guard let firstWeek = weeklyData.first?.weekStart,
              let lastWeek = weeklyData.last?.weekStart else {
            return "Last 12 weeks"
        }

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM"

        let weekCount = weeklyData.count
        if weekCount <= 12 {
            return "Last \(weekCount) week\(weekCount == 1 ? "" : "s")"
        } else {
            return "\(formatter.string(from: firstWeek)) - \(formatter.string(from: lastWeek))"
        }
    }

    private var hasMovingAverage: Bool {
        weeklyData.contains { $0.movingAverage != nil }
    }

    private var averageOfMovingAverages: Double? {
        let movingAverages = weeklyData.compactMap { $0.movingAverage }
        guard !movingAverages.isEmpty else { return nil }
        return movingAverages.reduce(0.0, +) / Double(movingAverages.count)
    }

    private var selectedDate: Date? {
        guard let rawSelectedDate else { return nil }
        // Find closest week in weeklyData
        return weeklyData.min(by: {
            abs($0.weekStart.timeIntervalSince(rawSelectedDate)) <
            abs($1.weekStart.timeIntervalSince(rawSelectedDate))
        })?.weekStart
    }

    @ViewBuilder
    private var selectionPopover: some View {
        if let selectedDate,
           let index = weeklyData.firstIndex(where: { $0.weekStart == selectedDate }) {
            let dataPoint = weeklyData[index]
            VStack(spacing: 4) {
                Text(selectedDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.bold())
                Text("\(formatVolume(dataPoint.totalVolume)) kg lifted")
                    .font(.caption)
                // Show week-on-week change if not first week
                if index > 0 {
                    let previousVolume = weeklyData[index - 1].totalVolume
                    let change = dataPoint.totalVolume - previousVolume
                    Text(formatWeightChange(Int(change)))
                        .font(.caption2)
                        .foregroundStyle(change > 0 ? .green : .secondary)
                }
            }
            .padding(8)
            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
            .shadow(radius: 2)
        }
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

            VStack(alignment: .leading, spacing: 16) {
                // Header
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text("Volume Progression")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text(dateRangeText)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    // Date range picker (only show if >12 weeks of data)
                    if totalWeeksOfData > 12 {
                        HStack(spacing: 4) {
                            ForEach([DateRange.fourWeeks, .twelveWeeks, .sixMonths, .all], id: \.self) { range in
                                Button {
                                    HapticManager.shared.trigger(.light)
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        selectedRange = range
                                    }
                                } label: {
                                    Text(range.rawValue)
                                        .font(.caption2.bold())
                                        .foregroundStyle(selectedRange == range ? .orange : .secondary)
                                        .padding(.horizontal, 8)
                                        .padding(.vertical, 4)
                                        .background(
                                            selectedRange == range ? Color.orange.opacity(0.15) : Color.clear,
                                            in: Capsule()
                                        )
                                }
                            }
                        }
                    }
                }

                // Chart or empty state
                if weeklyData.count < 2 {
                    // Empty state
                    VStack(spacing: 12) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)

                        Text("Not Enough Data")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Log workouts for 2+ weeks to see volume trends")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                    .frame(maxWidth: .infinity)
                    .frame(height: 220)
                } else {
                    VStack(spacing: 8) {
                        // Legend (top right)
                        HStack {
                            Spacer()

                            HStack(spacing: 16) {
                                // Volume legend item
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Weekly Volume")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                // Moving average legend (if available)
                                if hasMovingAverage, let avgValue = averageOfMovingAverages {
                                    HStack(spacing: 4) {
                                        Rectangle()
                                            .fill(Color.gray)
                                            .frame(width: 16, height: 2)
                                        Text("4 wk avg (\(formatVolume(avgValue)) kg)")
                                            .font(.caption2)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                        }

                        // Volume progression chart
                        Chart {
                            // Main line: Weekly total volume
                            ForEach(weeklyData) { dataPoint in
                                LineMark(
                                    x: .value("Week", dataPoint.weekStart, unit: .weekOfYear),
                                    y: .value("Volume", dataPoint.totalVolume)
                                )
                                .foregroundStyle(.orange)
                                .lineStyle(StrokeStyle(lineWidth: 3))
                                .interpolationMethod(.catmullRom)
                                .symbol {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                }
                            }

                            // 4-week moving average reference line (horizontal)
                            if let avgValue = averageOfMovingAverages {
                                RuleMark(y: .value("Average", avgValue))
                                    .foregroundStyle(Color.gray)
                                    .lineStyle(StrokeStyle(lineWidth: 2))
                            }

                            // Selection indicator
                            if let selectedDate {
                                RuleMark(x: .value("Selected", selectedDate, unit: .weekOfYear))
                                    .foregroundStyle(Color.gray.opacity(0.3))
                                    .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 5]))
                                    .zIndex(-1)
                                    .annotation(position: .top, spacing: 0, overflowResolution: .init(x: .fit(to: .chart), y: .disabled)) {
                                        selectionPopover
                                    }
                            }
                        }
                        .chartYScale(domain: 0...(maxVolume * 1.1))
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear, count: xAxisStride)) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let doubleValue = value.as(Double.self) {
                                        Text(formatVolume(doubleValue))
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartXSelection(value: $rawSelectedDate)
                        .frame(height: 200)
                        .accessibilityLabel("Volume progression chart showing total weight lifted per week")
                    }
                }
            }
            .padding(20)
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        let kg = Int(volume)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
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

#Preview {
    VolumeProgressionCard(workouts: [])
        .padding()
}
