//
//  VolumeDetailView.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import SwiftUI
import Charts

struct VolumeDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let workouts: [WorkoutEntry]

    @State private var selectedDate: Date?
    @State private var showMovingAverage = false

    /// All workout volumes, sorted by date
    private var volumeData: [WorkoutVolumePoint] {
        workouts
            .sorted { $0.workoutDate < $1.workoutDate }
            .map { WorkoutVolumePoint(from: $0) }
    }

    /// 7-day moving average
    private var movingAverage: [WorkoutVolumePoint] {
        guard volumeData.count >= 7 else { return [] }

        var result: [WorkoutVolumePoint] = []
        for i in 6..<volumeData.count {
            let window = volumeData[(i-6)...i]
            let avg = window.reduce(0.0) { $0 + $1.volume } / 7.0
            result.append(WorkoutVolumePoint(
                date: volumeData[i].date,
                volume: avg,
                workoutName: "7-Day Avg"
            ))
        }
        return result
    }

    /// Currently selected point data
    private var selectedPoint: WorkoutVolumePoint? {
        guard let selectedDate else { return nil }
        return volumeData.first { Calendar.current.isDate($0.date, inSameDayAs: selectedDate) }
    }

    /// Stats
    private var totalVolume: Double {
        volumeData.reduce(0.0) { $0 + $1.volume }
    }

    private var averageVolume: Double {
        guard !volumeData.isEmpty else { return 0 }
        return totalVolume / Double(volumeData.count)
    }

    private var maxVolume: Double {
        volumeData.map(\.volume).max() ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Chart
                    if volumeData.isEmpty {
                        ContentUnavailableView {
                            Label("No Data", systemImage: "chart.line.uptrend.xyaxis")
                        } description: {
                            Text("No workouts to display")
                        }
                        .frame(height: 300)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Chart {
                                // Main volume line
                                ForEach(volumeData) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Volume", point.volume)
                                    )
                                    .foregroundStyle(.orange)
                                    .interpolationMethod(.monotone)
                                    .lineStyle(StrokeStyle(lineWidth: 3))
                                    .symbol(Circle().strokeBorder(lineWidth: 2))
                                    .symbolSize(30)

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

                                // Moving average (optional)
                                if showMovingAverage && !movingAverage.isEmpty {
                                    ForEach(movingAverage) { point in
                                        LineMark(
                                            x: .value("Date", point.date),
                                            y: .value("Average", point.volume)
                                        )
                                        .foregroundStyle(.blue.opacity(0.6))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                        .interpolationMethod(.monotone)
                                    }
                                }

                                // Selection indicator
                                if let selectedDate {
                                    RuleMark(x: .value("Selected", selectedDate))
                                        .foregroundStyle(.gray.opacity(0.3))
                                        .lineStyle(StrokeStyle(lineWidth: 2))
                                        .annotation(position: .top, spacing: 0) {
                                            if let point = selectedPoint {
                                                VStack(spacing: 4) {
                                                    Text(point.date, format: .dateTime.day().month().year())
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                    Text("\(Int(point.volume))kg")
                                                        .font(.title3.bold())
                                                        .foregroundStyle(.orange)
                                                    Text(point.workoutName)
                                                        .font(.caption2)
                                                        .foregroundStyle(.secondary)
                                                }
                                                .padding(8)
                                                .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                                                .shadow(color: .black.opacity(0.1), radius: 4, x: 0, y: 2)
                                            }
                                        }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading, values: .automatic(desiredCount: 5)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let kg = value.as(Double.self) {
                                            Text(formatVolume(kg))
                                                .font(.caption)
                                        }
                                    }
                                }
                            }
                            .chartXAxis {
                                AxisMarks(values: .automatic(desiredCount: 6)) { value in
                                    AxisGridLine()
                                    AxisValueLabel {
                                        if let date = value.as(Date.self) {
                                            Text(date, format: .dateTime.month(.abbreviated).day())
                                        }
                                    }
                                    .font(.caption)
                                }
                            }
                            .chartScrollableAxes(.horizontal)
                            .chartXSelection(value: $selectedDate)
                            .frame(height: 300)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            // Legend
                            HStack(spacing: 16) {
                                HStack(spacing: 6) {
                                    Circle()
                                        .fill(.orange)
                                        .frame(width: 10, height: 10)
                                    Text("Workout Volume")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }

                                if showMovingAverage && !movingAverage.isEmpty {
                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(.blue.opacity(0.6))
                                            .frame(width: 16, height: 3)
                                        Text("7-Day Average")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                            }
                            .padding(.horizontal)
                        }
                    }

                    // Toggle for moving average
                    if volumeData.count >= 7 {
                        Toggle("Show 7-Day Average", isOn: $showMovingAverage)
                            .padding(.horizontal)
                    }

                    // Summary stats
                    if !volumeData.isEmpty {
                        HStack(spacing: 12) {
                            StatSummaryCard(
                                title: "Total",
                                value: formatVolume(totalVolume),
                                subtitle: "kg lifted",
                                icon: "dumbbell.fill",
                                color: .orange
                            )

                            StatSummaryCard(
                                title: "Average",
                                value: formatVolume(averageVolume),
                                subtitle: "per workout",
                                icon: "chart.bar.fill",
                                color: .blue
                            )

                            StatSummaryCard(
                                title: "Best",
                                value: formatVolume(maxVolume),
                                subtitle: "single workout",
                                icon: "star.fill",
                                color: .green
                            )
                        }
                        .padding(.horizontal)
                    }

                    // Instructions
                    if !volumeData.isEmpty && volumeData.count > 7 {
                        Text("Swipe left/right to scroll • Tap any point to see details")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                            .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
            .navigationTitle("Total Weight Lifted")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
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

struct StatSummaryCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            VStack(spacing: 2) {
                Text(title)
                    .font(.caption2.bold())
                    .foregroundStyle(.secondary)
                Text(subtitle)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 16)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    VolumeDetailView(workouts: [])
}
