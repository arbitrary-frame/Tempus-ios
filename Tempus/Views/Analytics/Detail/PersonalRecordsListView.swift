//
//  PersonalRecordsListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import SwiftUI

struct PersonalRecordsListView: View {
    @Environment(\.dismiss) private var dismiss
    let workouts: [WorkoutEntry]
    let exercises: [Exercise]

    @State private var groupedPRs: [String: [ExercisePRGroup]] = [:]
    @State private var selectedExercise: String?

    private func loadPRs() {
        // Get all unique exercises from workouts
        let exerciseNames = Set(workouts.flatMap { workout in
            workout.exercisesData.map { $0.exerciseName }
        })

        // Group by muscle group
        var grouped: [String: [ExercisePRGroup]] = [:]

        for exerciseName in exerciseNames {
            let prs = AnalyticsService.detectPersonalRecords(for: exerciseName, in: workouts)
            guard !prs.isEmpty,
                  let latestPR = prs.sorted(by: { $0.date > $1.date }).first else {
                continue
            }

            // Get muscle group from exercise library
            let muscleGroup = exercises.first { $0.name == exerciseName }?.muscleGroup ?? "Other"

            let prGroup = ExercisePRGroup(
                exerciseName: exerciseName,
                muscleGroup: muscleGroup,
                latestPR: latestPR,
                totalPRs: prs.count
            )

            grouped[muscleGroup, default: []].append(prGroup)
        }

        // Sort each group by latest PR date
        for (key, value) in grouped {
            grouped[key] = value.sorted { $0.latestPR.date > $1.latestPR.date }
        }

        groupedPRs = grouped
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                if groupedPRs.isEmpty {
                    ContentUnavailableView {
                        Label("No Personal Records", systemImage: "trophy.fill")
                    } description: {
                        Text("Set a new PR by lifting heavier weights!")
                    }
                    .padding(.top, 100)
                } else {
                    LazyVStack(spacing: 20, pinnedViews: [.sectionHeaders]) {
                        ForEach(groupedPRs.keys.sorted(), id: \.self) { muscleGroup in
                            Section {
                                VStack(spacing: 12) {
                                    ForEach(groupedPRs[muscleGroup] ?? [], id: \.exerciseName) { prGroup in
                                        PRDetailRow(prGroup: prGroup)
                                            .onTapGesture {
                                                HapticManager.shared.trigger(.light)
                                                selectedExercise = prGroup.exerciseName
                                            }
                                    }
                                }
                                .padding(.horizontal)
                            } header: {
                                HStack {
                                    Text(muscleGroup)
                                        .font(.headline)
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Text("\(groupedPRs[muscleGroup]?.count ?? 0) exercises")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 8)
                                .background(.ultraThinMaterial)
                            }
                        }
                    }
                    .padding(.top)
                }
            }
            .navigationTitle("Personal Records")
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
            .onAppear {
                loadPRs()
            }
            .sheet(item: Binding(
                get: { selectedExercise.map { ExerciseSelection(name: $0) } },
                set: { selectedExercise = $0?.name }
            )) { selection in
                ExerciseDetailView(
                    exerciseName: selection.name,
                    workouts: workouts,
                    exercises: exercises
                )
            }
        }
    }
}

struct ExerciseSelection: Identifiable {
    let id = UUID()
    let name: String
}

struct PRDetailRow: View {
    let prGroup: ExercisePRGroup

    private var formattedDate: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        return formatter.string(from: prGroup.latestPR.date)
    }

    private var estimated1RM: String {
        String(format: "%.1f", prGroup.latestPR.estimatedOneRM)
    }

    var body: some View {
        ZStack {
            RoundedRectangle(cornerRadius: 16)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

            VStack(spacing: 12) {
                HStack {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(prGroup.exerciseName)
                            .font(.headline)
                            .foregroundStyle(.primary)

                        Text("Latest PR: \(formattedDate)")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }

                    Spacer()

                    Text("🏆")
                        .font(.title2)
                }

                Divider()

                HStack(spacing: 20) {
                    // Weight x Reps
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text("\(Int(prGroup.latestPR.weight))")
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text("×")
                                .font(.caption)
                                .foregroundStyle(.tertiary)
                            Text("\(prGroup.latestPR.reps)")
                                .font(.title3.bold())
                                .foregroundStyle(.orange)
                        }
                        Text("Best Set")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 30)

                    // Estimated 1RM
                    VStack(spacing: 4) {
                        HStack(spacing: 4) {
                            Text(estimated1RM)
                                .font(.title3.bold())
                                .foregroundStyle(.blue)
                            Text("kg")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        Text("Est. 1RM")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)

                    Divider()
                        .frame(height: 30)

                    // Total PRs
                    VStack(spacing: 4) {
                        Text("\(prGroup.totalPRs)")
                            .font(.title3.bold())
                            .foregroundStyle(.green)
                        Text("Total PRs")
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                }
            }
            .padding(16)
        }
    }
}

#Preview {
    PersonalRecordsListView(workouts: [], exercises: [])
}
