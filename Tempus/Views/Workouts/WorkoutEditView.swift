//
//  WorkoutEditView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutEditView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let workout: WorkoutEntry

    var body: some View {
        NavigationStack {
            List {
                // Header Section - Workout Name and Date
                Section {
                    Text(workout.workoutName)
                        .font(.title2.bold())

                    HStack {
                        Text("Date:")
                            .foregroundStyle(.secondary)
                        Spacer()
                        Text(workout.workoutDate, style: .date)
                    }
                } header: {
                    Text("Workout Details")
                }

                // Exercises Section
                ForEach(workout.exercisesData) { exerciseData in
                    Section {
                        ForEach(exerciseData.sets) { set in
                            HStack(spacing: 12) {
                                Text("Set \(set.setNumber)")
                                    .font(.subheadline)
                                    .frame(width: 50, alignment: .leading)

                                ForEach(set.weightsAndReps) { wr in
                                    HStack(spacing: 4) {
                                        Text("\(wr.weight, specifier: "%.1f") kg")
                                            .font(.caption)
                                        Text("×")
                                            .foregroundStyle(.secondary)
                                            .font(.caption)
                                        Text("\(wr.reps)")
                                            .font(.caption)
                                    }
                                }
                            }
                        }

                        if let notes = exerciseData.notes, !notes.isEmpty {
                            Text(notes)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    } header: {
                        Text(exerciseData.exerciseName)
                            .font(.headline)
                    }
                }

                // Notes Section
                if let notes = workout.notes, !notes.isEmpty {
                    Section {
                        Text(notes)
                    } header: {
                        Text("Workout Notes")
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("View Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    let config = ModelConfiguration(isStoredInMemoryOnly: true)
    let container = try! ModelContainer(for: WorkoutEntry.self, configurations: config)

    let workout = WorkoutEntry(
        name: "Test Workout",
        date: Date(),
        exercisesData: [
            WorkoutExerciseData(
                exerciseID: UUID(),
                exerciseName: "Bench Press",
                sets: [
                    WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 60, reps: 10)]),
                    WorkoutSet(setNumber: 2, weightsAndReps: [WeightRep(weight: 65, reps: 8)])
                ]
            )
        ]
    )
    container.mainContext.insert(workout)

    return WorkoutEditView(workout: workout)
        .modelContainer(container)
}