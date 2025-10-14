//
//  ConsistencyGraphCard.swift
//  Tempus
//
//  Created by Ronak Pattani on 03/10/2025.
//

import SwiftUI
import Charts

struct ConsistencyGraphCard: View {
    let workouts: [WorkoutEntry]
    let weeklyGoal: Int

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
    struct WeeklyData: Identifiable {
        let id = UUID()
        let weekStart: Date
        let workoutCount: Int
    }

    private var weeklyData: [WeeklyData] {
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

        // Group workouts by week
        var workoutsByWeek: [Date: Int] = [:]
        for workout in workouts {
            guard let weekStart = calendar.date(
                from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: workout.workoutDate)
            ) else { continue }

            workoutsByWeek[weekStart, default: 0] += 1
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

        // Fill in weeks from start to current
        var allWeeks: [WeeklyData] = []
        var currentWeek = startDate

        while currentWeek <= currentWeekStart {
            let count = workoutsByWeek[currentWeek] ?? 0
            allWeeks.append(WeeklyData(weekStart: currentWeek, workoutCount: count))

            guard let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: currentWeek) else {
                break
            }
            currentWeek = nextWeek
        }

        return allWeeks.sorted { $0.weekStart < $1.weekStart }
    }

    private var maxWorkouts: Int {
        weeklyData.map { $0.workoutCount }.max() ?? 0
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

    private var selectedDate: Date? {
        guard let rawSelectedDate else { return nil }
        // Find closest week in weeklyData
        return weeklyData.min(by: {
            abs($0.weekStart.timeIntervalSince(rawSelectedDate)) <
            abs($1.weekStart.timeIntervalSince(rawSelectedDate))
        })?.weekStart
    }

    private var displayedWeeks: [WeeklyData] {
        // Show last 12 weeks by default for initial view
        Array(weeklyData.suffix(12))
    }

    @ViewBuilder
    private var selectionPopover: some View {
        if let selectedDate,
           let dataPoint = weeklyData.first(where: { $0.weekStart == selectedDate }) {
            VStack(spacing: 4) {
                Text(selectedDate, format: .dateTime.month(.abbreviated).day())
                    .font(.caption2.bold())
                Text("\(dataPoint.workoutCount) workout\(dataPoint.workoutCount == 1 ? "" : "s")")
                    .font(.caption)
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
                        Text("Weekly Consistency")
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

                        Text("Log workouts for 2+ weeks to see consistency trends")
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
                                // Workouts legend item
                                HStack(spacing: 4) {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 8, height: 8)
                                    Text("Workouts")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }

                                // Goal legend item
                                HStack(spacing: 4) {
                                    Rectangle()
                                        .stroke(style: StrokeStyle(lineWidth: 2, dash: [4, 3]))
                                        .foregroundStyle(Color.gray)
                                        .frame(width: 16, height: 2)
                                    Text("Goal (\(weeklyGoal))")
                                        .font(.caption2)
                                        .foregroundStyle(.secondary)
                                }
                            }
                        }

                        // Consistency chart (simplified - no scrolling, use range picker instead)
                        Chart {
                            // Main line: Actual workouts per week
                            ForEach(weeklyData) { dataPoint in
                                LineMark(
                                    x: .value("Week", dataPoint.weekStart, unit: .weekOfYear),
                                    y: .value("Workouts", dataPoint.workoutCount)
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

                            // Goal reference line (dashed) - no annotation
                            RuleMark(y: .value("Goal", weeklyGoal))
                                .foregroundStyle(Color.gray)
                                .lineStyle(StrokeStyle(lineWidth: 2, dash: [8, 6]))

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
                        .chartYScale(domain: 0...max(weeklyGoal + 2, maxWorkouts + 1))
                        .chartXAxis {
                            AxisMarks(values: .stride(by: .weekOfYear, count: xAxisStride)) { _ in
                                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                    .font(.caption2)
                            }
                        }
                        .chartYAxis {
                            AxisMarks(position: .leading) { value in
                                AxisValueLabel {
                                    if let intValue = value.as(Int.self) {
                                        Text("\(intValue)")
                                            .font(.caption2)
                                    }
                                }
                            }
                        }
                        .chartXSelection(value: $rawSelectedDate)
                        .frame(height: 200)
                        .accessibilityLabel("Weekly consistency chart showing workouts per week with a goal line at \(weeklyGoal) workouts")
                    }
                }
            }
            .padding(20)
        }
    }
}

#Preview {
    ConsistencyGraphCard(workouts: [], weeklyGoal: 3)
        .padding()
}
