//
//  ExerciseDetailView.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import SwiftUI

struct ExerciseDetailView: View {
    @Environment(\.dismiss) private var dismiss
    let exerciseName: String
    let workouts: [WorkoutEntry]
    let exercises: [Exercise]
    @State private var showingInfo = false

    private var exerciseWorkouts: [WorkoutEntry] {
        workouts.filter { workout in
            workout.exercisesData.contains { $0.exerciseName == exerciseName }
        }
    }

    private var muscleGroup: String {
        exercises.first { $0.name == exerciseName }?.muscleGroup ?? "Unknown"
    }

    private var personalRecords: [PersonalRecord] {
        AnalyticsService.detectPersonalRecords(for: exerciseName, in: workouts)
            .sorted { $0.date > $1.date }
    }

    private var averageWeight: Double? {
        AnalyticsService.averageWeight(for: exerciseName, in: workouts)
    }

    private var averageReps: Double? {
        AnalyticsService.averageReps(for: exerciseName, in: workouts)
    }

    private var totalSets: Int {
        exerciseWorkouts.reduce(0) { total, workout in
            total + (workout.exercisesData.first { $0.exerciseName == exerciseName }?.sets.count ?? 0)
        }
    }

    private var frequency: Int {
        exerciseWorkouts.count
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Exercise header
                    VStack(spacing: 8) {
                        Text(exerciseName)
                            .font(.title.bold())
                            .foregroundStyle(.primary)
                            .multilineTextAlignment(.center)

                        Text(muscleGroup)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .padding(.horizontal, 16)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                    }
                    .padding(.top)

                    // Quick stats
                    HStack(spacing: 12) {
                        QuickStatCard(
                            title: "Frequency",
                            value: "\(frequency)",
                            subtitle: "workouts",
                            icon: "calendar",
                            color: .blue
                        )

                        QuickStatCard(
                            title: "Total Sets",
                            value: "\(totalSets)",
                            subtitle: "performed",
                            icon: "list.bullet",
                            color: .green
                        )

                        QuickStatCard(
                            title: "PRs",
                            value: "\(personalRecords.count)",
                            subtitle: "achieved",
                            icon: "trophy.fill",
                            color: .orange
                        )
                    }
                    .padding(.horizontal)

                    // Average stats
                    HStack(spacing: 12) {
                        if let avgWeight = averageWeight {
                            AverageStatCard(
                                title: "Avg Weight",
                                value: "\(Int(avgWeight))kg",
                                icon: "scalemass.fill"
                            )
                        }

                        if let avgReps = averageReps {
                            AverageStatCard(
                                title: "Avg Reps",
                                value: String(format: "%.1f", avgReps),
                                icon: "repeat"
                            )
                        }
                    }
                    .padding(.horizontal)

                    // Personal Records timeline
                    if !personalRecords.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text("Personal Records Timeline")
                                .font(.headline)
                                .padding(.horizontal)

                            VStack(spacing: 12) {
                                ForEach(personalRecords.prefix(10)) { pr in
                                    PRTimelineRow(pr: pr)
                                }
                            }
                            .padding(.horizontal)
                        }
                    }
                }
                .padding(.bottom, 20)
            }
            .navigationTitle("Exercise Details")
            .navigationBarTitleDisplayMode(.inline)
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
}

struct QuickStatCard: View {
    let title: String
    let value: String
    let subtitle: String
    let icon: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(color)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.title3.bold())
                .foregroundStyle(.primary)

            Text(title)
                .font(.caption2.bold())
                .foregroundStyle(.secondary)

            Text(subtitle)
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct AverageStatCard: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        HStack {
            Image(systemName: icon)
                .font(.title3)
                .foregroundStyle(.orange)
                .symbolRenderingMode(.hierarchical)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text(value)
                    .font(.title3.bold())
                    .foregroundStyle(.primary)
            }

            Spacer()
        }
        .padding()
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

struct PRTimelineRow: View {
    let pr: PersonalRecord
    @State private var showingInfo = false

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        return formatter.string(from: pr.date)
    }

    var body: some View {
        HStack {
            // PR badge
            ZStack {
                Circle()
                    .fill(.green.opacity(0.2))
                    .frame(width: 40, height: 40)
                Text("🏆")
                    .font(.title3)
            }

            VStack(alignment: .leading, spacing: 4) {
                HStack(spacing: 6) {
                    Text("\(Int(pr.weight))kg")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                    Text("×")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(pr.reps) reps")
                        .font(.subheadline.bold())
                        .foregroundStyle(.primary)
                }

                Text(formattedDate)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("Est. 1RM")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Button {
                        HapticManager.shared.trigger(.light)
                        showingInfo = true
                    } label: {
                        Image(systemName: "info.circle")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                }
                Text(String(format: "%.1fkg", pr.estimatedOneRM))
                    .font(.caption.bold())
                    .foregroundStyle(.blue)
            }
            .popover(isPresented: $showingInfo, arrowEdge: .top) {
                VStack(alignment: .leading, spacing: 8) {
                    Text("Estimated 1RM")
                        .font(.headline)

                    Text("Max weight you could lift for 1 rep, calculated using:")
                        .font(.subheadline)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Weight ÷ (1.0278 - 0.0278 × Reps)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .monospaced()
                        .fixedSize(horizontal: false, vertical: true)

                    Text("Brzycki formula")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
                .padding()
                .frame(width: 280)
                .presentationCompactAdaptation(.popover)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 4, x: 0, y: 2)
    }
}

#Preview {
    ExerciseDetailView(exerciseName: "Bench Press", workouts: [], exercises: [])
}
