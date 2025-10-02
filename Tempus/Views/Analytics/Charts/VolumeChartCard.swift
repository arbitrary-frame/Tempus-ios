//
//  VolumeChartCard.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import SwiftUI
import Charts

struct VolumeChartCard: View {
    let workouts: [WorkoutEntry]
    @State private var selectedPeriod: TimePeriod = .sevenDays
    @State private var showingDetailView = false

    enum TimePeriod: String, CaseIterable {
        case sevenDays = "7D"
        case thirtyDays = "30D"
        case ninetyDays = "90D"
        case all = "All"

        var days: Int? {
            switch self {
            case .sevenDays: return 7
            case .thirtyDays: return 30
            case .ninetyDays: return 90
            case .all: return nil
            }
        }
    }

    private var filteredWorkouts: [WorkoutEntry] {
        guard let days = selectedPeriod.days else { return workouts }
        let cutoffDate = Calendar.current.date(byAdding: .day, value: -days, to: Date()) ?? Date()
        return workouts.filter { $0.workoutDate >= cutoffDate }
    }

    private var volumeData: [(date: Date, volume: Double)] {
        filteredWorkouts
            .sorted { $0.workoutDate < $1.workoutDate }
            .map { (date: $0.workoutDate, volume: $0.totalVolume) }
    }

    private var trendPercentage: Double? {
        guard volumeData.count >= 4 else { return nil }

        let midpoint = volumeData.count / 2
        let firstHalf = volumeData.prefix(midpoint)
        let secondHalf = volumeData.suffix(midpoint)

        let firstAvg = firstHalf.reduce(0.0) { $0 + $1.volume } / Double(firstHalf.count)
        let secondAvg = secondHalf.reduce(0.0) { $0 + $1.volume } / Double(secondHalf.count)

        guard firstAvg > 0 else { return nil }
        return ((secondAvg - firstAvg) / firstAvg) * 100
    }


    private func formatXAxisLabel(_ date: Date) -> String {
        switch selectedPeriod {
        case .sevenDays:
            return date.formatted(.dateTime.weekday(.abbreviated))
        case .thirtyDays, .ninetyDays, .all:
            return date.formatted(.dateTime.month(.abbreviated).day())
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
                    Text("Total Weight Lifted")
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .frame(width: 180)
                }

                // Mini chart
                if volumeData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No workouts in this period")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                } else {
                    Chart(volumeData, id: \.date) { point in
                        LineMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(.orange)
                        .interpolationMethod(.monotone)

                        AreaMark(
                            x: .value("Date", point.date),
                            y: .value("Volume", point.volume)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [.orange.opacity(0.3), .orange.opacity(0.05)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.monotone)
                    }
                    .chartYAxis {
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { value in
                            AxisValueLabel {
                                if let kg = value.as(Double.self) {
                                    Text(formatVolume(kg))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        switch selectedPeriod {
                        case .sevenDays:
                            AxisMarks(values: .stride(by: .day)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatXAxisLabel(date))
                                    }
                                    .font(.caption2)
                                }
                            }
                        case .thirtyDays:
                            AxisMarks(values: .stride(by: .day, count: 5)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatXAxisLabel(date))
                                    }
                                    .font(.caption2)
                                }
                            }
                        case .ninetyDays:
                            AxisMarks(values: .stride(by: .weekOfYear, count: 2)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatXAxisLabel(date))
                                    }
                                    .font(.caption2)
                                }
                            }
                        case .all:
                            AxisMarks(values: .stride(by: .month)) { value in
                                if let date = value.as(Date.self) {
                                    AxisValueLabel {
                                        Text(formatXAxisLabel(date))
                                    }
                                    .font(.caption2)
                                }
                            }
                        }
                    }
                    .frame(height: 120)
                }

                // Tap to view more
                Button {
                    HapticManager.shared.trigger(.light)
                    showingDetailView = true
                } label: {
                    HStack {
                        Text("View Details")
                            .font(.subheadline.bold())
                        Image(systemName: "chevron.right")
                            .font(.caption)
                    }
                    .foregroundStyle(.orange)
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingDetailView) {
            VolumeDetailView(workouts: workouts, selectedPeriod: $selectedPeriod)
        }
    }

    private func formatVolume(_ volume: Double) -> String {
        let kg = Int(volume)
        if kg >= 10000 {
            return String(format: "%.0fk", Double(kg) / 1000.0)
        } else if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }
}

#Preview {
    VolumeChartCard(workouts: [])
        .padding()
}
