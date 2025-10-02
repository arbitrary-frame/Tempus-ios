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
    @Binding var selectedPeriod: VolumeChartCard.TimePeriod

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

    private var movingAverage: [(date: Date, average: Double)] {
        guard volumeData.count >= 7 else { return [] }

        var result: [(date: Date, average: Double)] = []
        for i in 6..<volumeData.count {
            let window = volumeData[(i-6)...i]
            let avg = window.reduce(0.0) { $0 + $1.volume } / 7.0
            result.append((date: volumeData[i].date, average: avg))
        }
        return result
    }

    private var averageVolume: Double {
        guard !volumeData.isEmpty else { return 0 }
        return volumeData.reduce(0.0) { $0 + $1.volume } / Double(volumeData.count)
    }

    private var maxVolume: Double {
        volumeData.map(\.volume).max() ?? 0
    }

    private var totalVolume: Double {
        volumeData.reduce(0.0) { $0 + $1.volume }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Period selector
                    Picker("Period", selection: $selectedPeriod) {
                        ForEach(VolumeChartCard.TimePeriod.allCases, id: \.self) { period in
                            Text(period.rawValue).tag(period)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    // Large chart
                    if volumeData.isEmpty {
                        ContentUnavailableView {
                            Label("No Data", systemImage: "chart.line.uptrend.xyaxis")
                        } description: {
                            Text("No workouts in this period")
                        }
                        .frame(height: 300)
                    } else {
                        VStack(alignment: .leading, spacing: 12) {
                            Chart {
                                ForEach(volumeData, id: \.date) { point in
                                    LineMark(
                                        x: .value("Date", point.date),
                                        y: .value("Volume", point.volume)
                                    )
                                    .foregroundStyle(.orange)
                                    .interpolationMethod(.catmullRom)
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
                                    .interpolationMethod(.catmullRom)
                                }

                                // 7-day moving average
                                if !movingAverage.isEmpty {
                                    ForEach(movingAverage, id: \.date) { point in
                                        LineMark(
                                            x: .value("Date", point.date),
                                            y: .value("Average", point.average)
                                        )
                                        .foregroundStyle(.blue.opacity(0.6))
                                        .lineStyle(StrokeStyle(lineWidth: 2, dash: [5, 3]))
                                    }
                                }
                            }
                            .chartYAxis {
                                AxisMarks(position: .leading) { value in
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
                                AxisMarks { value in
                                    AxisGridLine()
                                    AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                                        .font(.caption)
                                }
                            }
                            .frame(height: 300)
                            .padding()
                            .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
                            .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                            // Legend
                            if !movingAverage.isEmpty {
                                HStack(spacing: 16) {
                                    HStack(spacing: 6) {
                                        Circle()
                                            .fill(.orange)
                                            .frame(width: 10, height: 10)
                                        Text("Daily Volume")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }

                                    HStack(spacing: 6) {
                                        RoundedRectangle(cornerRadius: 2)
                                            .fill(.blue.opacity(0.6))
                                            .frame(width: 16, height: 3)
                                        Text("7-Day Average")
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                }
                                .padding(.horizontal)
                            }
                        }
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
                }
                .padding(.top)
            }
            .navigationTitle("Volume Over Time")
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
    VolumeDetailView(workouts: [], selectedPeriod: .constant(.thirtyDays))
}
