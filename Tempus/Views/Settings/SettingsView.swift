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
    @Query private var routines: [WorkoutRoutine]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("userName") private var userName: String = ""
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @State private var showingExportSheet = false
    @State private var exportData: Data?
    @State private var showingResetConfirmation = false
    @State private var showingSampleDataLoaded = false
    @State private var showingDataCleared = false

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

                    HStack {
                        Text("Routines")
                        Spacer()
                        Text("\(routines.count)")
                            .foregroundStyle(.secondary)
                    }
                }

                // Danger Zone Section
                Section {
                    Button(role: .destructive) {
                        showingResetConfirmation = true
                    } label: {
                        Label("Reset App to Default", systemImage: "exclamationmark.triangle.fill")
                    }
                } header: {
                    Text("Danger Zone")
                } footer: {
                    Text("This will delete all workouts, exercises, routines, and reset all settings. This action cannot be undone.")
                        .foregroundStyle(.secondary)
                }

                #if DEBUG
                // Developer Section (Debug only)
                Section {
                    Button {
                        SampleDataManager.loadSampleData(into: modelContext)
                        HapticManager.shared.trigger(.success)
                        showingSampleDataLoaded = true
                    } label: {
                        Label("Load Sample Data", systemImage: "tray.and.arrow.down.fill")
                    }

                    Button(role: .destructive) {
                        SampleDataManager.clearAllData(from: modelContext)
                        HapticManager.shared.trigger(.success)
                        showingDataCleared = true
                    } label: {
                        Label("Clear All Data", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("DEBUG BUILD ONLY: These options help with testing and will not appear in production builds.")
                        .foregroundStyle(.orange)
                }
                #endif

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
            .alert("Reset App to Default?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset App", role: .destructive) {
                    resetAppToDefault()
                }
            } message: {
                Text("This will permanently delete all your workouts, exercises, routines, and settings. You will need to go through onboarding again. This action cannot be undone.")
            }
            #if DEBUG
            .alert("Sample Data Loaded!", isPresented: $showingSampleDataLoaded) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Successfully loaded 16 exercises, 3 routines, and 7 workouts. Check the Workouts and Exercises tabs to see them!")
            }
            .alert("Data Cleared!", isPresented: $showingDataCleared) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All exercises, routines, and workouts have been deleted from the database.")
            }
            #endif
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
            // Handle error silently for now
        }
    }

    private func resetAppToDefault() {
        HapticManager.shared.trigger(.warning)

        // Delete all workouts
        for workout in workouts {
            modelContext.delete(workout)
        }

        // Delete all routines
        for routine in routines {
            modelContext.delete(routine)
        }

        // Delete all exercises
        for exercise in exercises {
            modelContext.delete(exercise)
        }

        // Save context
        try? modelContext.save()

        // Reset user preferences (but keep theme preference)
        userName = ""
        hasCompletedOnboarding = false

        // Trigger success haptic
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Export Data Models

struct ExportData: Codable, Sendable {
    let version: String
    let workouts: [ExportWorkout]
    let exercises: [ExportExerciseDefinition]
    let exportDate: Date
}

struct ExportWorkout: Codable, Sendable {
    let id: String
    let name: String
    let date: Date
    let notes: String?
    let exercises: [ExportExercise]
}

struct ExportExercise: Codable, Sendable {
    let name: String
    let sets: [ExportSet]
    let notes: String?
}

struct ExportSet: Codable, Sendable {
    let setNumber: Int
    let weightsAndReps: [ExportWeightRep]
}

struct ExportWeightRep: Codable, Sendable {
    let weight: Double
    let reps: Int
}

struct ExportExerciseDefinition: Codable, Sendable {
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