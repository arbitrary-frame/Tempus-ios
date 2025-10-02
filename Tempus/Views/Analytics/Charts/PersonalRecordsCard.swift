//
//  PersonalRecordsCard.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import SwiftUI

struct PersonalRecordsCard: View {
    let workouts: [WorkoutEntry]
    let exercises: [Exercise]
    @State private var showingAllPRs = false

    private var allPRs: [ExercisePRGroup] {
        // Get all unique exercises from workouts
        let exerciseNames = Set(workouts.flatMap { workout in
            workout.exercisesData.map { $0.exerciseName }
        })

        // For each exercise, get PRs
        var prGroups: [ExercisePRGroup] = []
        for exerciseName in exerciseNames {
            let prs = AnalyticsService.detectPersonalRecords(for: exerciseName, in: workouts)
            if let latestPR = prs.sorted(by: { $0.date > $1.date }).first {
                // Get muscle group from exercise library
                let muscleGroup = exercises.first { $0.name == exerciseName }?.muscleGroup ?? "Unknown"
                prGroups.append(ExercisePRGroup(
                    exerciseName: exerciseName,
                    muscleGroup: muscleGroup,
                    latestPR: latestPR,
                    totalPRs: prs.count
                ))
            }
        }

        return prGroups.sorted { $0.latestPR.date > $1.latestPR.date }
    }

    private var recentPRs: [ExercisePRGroup] {
        Array(allPRs.prefix(3))
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
                        Text("Personal Records")
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("\(allPRs.count) exercises with PRs")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("🏆")
                        .font(.system(size: 32))
                }

                if recentPRs.isEmpty {
                    VStack(spacing: 8) {
                        Image(systemName: "trophy.fill")
                            .font(.title)
                            .foregroundStyle(.secondary)
                        Text("No personal records yet")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text("Keep lifting to set your first PR!")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical)
                } else {
                    // Recent PRs list
                    VStack(spacing: 12) {
                        ForEach(recentPRs, id: \.exerciseName) { prGroup in
                            PRRow(prGroup: prGroup)
                        }
                    }

                    // View all button
                    Button {
                        HapticManager.shared.trigger(.light)
                        showingAllPRs = true
                    } label: {
                        HStack {
                            Text("View All PRs")
                                .font(.subheadline.bold())
                            Image(systemName: "chevron.right")
                                .font(.caption)
                        }
                        .foregroundStyle(.orange)
                    }
                }
            }
            .padding(20)
        }
        .sheet(isPresented: $showingAllPRs) {
            PersonalRecordsListView(workouts: workouts, exercises: exercises)
        }
    }
}

struct ExercisePRGroup {
    let exerciseName: String
    let muscleGroup: String
    let latestPR: PersonalRecord
    let totalPRs: Int
}

struct PRRow: View {
    let prGroup: ExercisePRGroup

    private var formattedDate: String {
        let formatter = RelativeDateTimeFormatter()
        formatter.unitsStyle = .short
        return formatter.localizedString(for: prGroup.latestPR.date, relativeTo: Date())
    }

    var body: some View {
        HStack(spacing: 12) {
            // Exercise info
            VStack(alignment: .leading, spacing: 4) {
                Text(prGroup.exerciseName)
                    .font(.subheadline.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)

                Text(prGroup.muscleGroup)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // PR details
            VStack(alignment: .trailing, spacing: 4) {
                HStack(spacing: 4) {
                    Text("\(Int(prGroup.latestPR.weight))kg")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                    Text("×")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text("\(prGroup.latestPR.reps)")
                        .font(.subheadline.bold())
                        .foregroundStyle(.orange)
                }

                Text(formattedDate)
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(12)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    PersonalRecordsCard(workouts: [], exercises: [])
        .padding()
}
