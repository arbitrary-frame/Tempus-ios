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
    @State private var showingDetailView = false

    /// Last 7 workouts for preview
    private var previewData: [WorkoutVolumePoint] {
        workouts
            .sorted { $0.workoutDate < $1.workoutDate }
            .suffix(7)
            .map { WorkoutVolumePoint(from: $0) }
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
                }

                // Mini chart preview
                if previewData.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "chart.line.uptrend.xyaxis")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No workouts yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(height: 120)
                    .frame(maxWidth: .infinity)
                } else {
                    Chart(previewData) { point in
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
                        AxisMarks(position: .leading, values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel {
                                if let kg = value.as(Double.self) {
                                    Text(formatVolume(kg))
                                        .font(.caption2)
                                }
                            }
                        }
                    }
                    .chartXAxis {
                        AxisMarks(values: .automatic(desiredCount: 3)) { value in
                            AxisValueLabel {
                                if let date = value.as(Date.self) {
                                    Text(date, format: .dateTime.month(.abbreviated).day())
                                }
                            }
                            .font(.caption2)
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
            VolumeDetailView(workouts: workouts)
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
