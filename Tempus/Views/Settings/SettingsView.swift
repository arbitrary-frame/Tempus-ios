//
//  SettingsView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [WorkoutEntry]
    @Query private var exercises: [Exercise]
    @EnvironmentObject var themeManager: ThemeManager

    @State private var showingExportSheet = false
    @State private var exportData: Data?

    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                }

                // Data Section
                Section("Data") {
                    Button {
                        exportAllData()
                    } label: {
                        Label("Export All Data", systemImage: "square.and.arrow.up")
                    }

                    HStack {
                        Text("Workouts")
                        Spacer()
                        Text("\(workouts.count)")
                            .foregroundStyle(.secondary)
                    }

                    HStack {
                        Text("Exercises")
                        Spacer()
                        Text("\(exercises.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // About Section
                Section("About") {
                    HStack {
                        Text("Version")
                        Spacer()
                        Text("1.0.0")
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Settings")
            .sheet(isPresented: $showingExportSheet) {
                if let data = exportData {
                    ShareSheet(items: [data])
                }
            }
        }
    }

    private func exportAllData() {
        let exportModel = ExportData(
            version: "1.0.0",
            workouts: workouts.map { workout in
                ExportWorkout(
                    id: workout.id.uuidString,
                    name: workout.workoutName,
                    date: workout.workoutDate,
                    notes: workout.notes,
                    exercises: workout.exercisesData.map { exercise in
                        ExportExercise(
                            name: exercise.exerciseName,
                            sets: exercise.sets.map { set in
                                ExportSet(
                                    setNumber: set.setNumber,
                                    weightsAndReps: set.weightsAndReps.map { wr in
                                        ExportWeightRep(weight: wr.weight, reps: wr.reps)
                                    }
                                )
                            },
                            notes: exercise.notes
                        )
                    }
                )
            },
            exercises: exercises.map { exercise in
                ExportExerciseDefinition(
                    id: exercise.id.uuidString,
                    name: exercise.name,
                    description: exercise.exerciseDescription,
                    muscleGroup: exercise.muscleGroup,
                    tags: exercise.tags
                )
            },
            exportDate: Date()
        )

        do {
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            exportData = try encoder.encode(exportModel)
            showingExportSheet = true
        } catch {
        }
    }
}

// MARK: - Export Data Models

struct ExportData: Codable {
    let version: String
    let workouts: [ExportWorkout]
    let exercises: [ExportExerciseDefinition]
    let exportDate: Date
}

struct ExportWorkout: Codable {
    let id: String
    let name: String
    let date: Date
    let notes: String?
    let exercises: [ExportExercise]
}

struct ExportExercise: Codable {
    let name: String
    let sets: [ExportSet]
    let notes: String?
}

struct ExportSet: Codable {
    let setNumber: Int
    let weightsAndReps: [ExportWeightRep]
}

struct ExportWeightRep: Codable {
    let weight: Double
    let reps: Int
}

struct ExportExerciseDefinition: Codable {
    let id: String
    let name: String
    let description: String?
    let muscleGroup: String
    let tags: [String]
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)
        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {}
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}