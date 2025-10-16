//
//  SettingsView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData
import WidgetKit
import UniformTypeIdentifiers

struct SettingsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [WorkoutEntry]
    @Query private var exercises: [Exercise]
    @Query private var routines: [WorkoutRoutine]
    @EnvironmentObject var themeManager: ThemeManager
    @AppStorage("userName") private var userName: String = ""
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @State private var exportItem: ExportItem?
    @State private var showingResetConfirmation = false
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    @State private var showingSampleDataLoaded = false
    @State private var showingDataCleared = false
    @State private var showingImportPicker = false
    @State private var showingImportConfirmation = false
    @State private var importData: ExportData?
    @State private var showingImportSuccess = false
    @State private var showingImportError = false
    @State private var importErrorMessage = ""

    var body: some View {
        NavigationStack {
            List {
                // Appearance Section
                Section("Appearance") {
                    Toggle("Dark Mode", isOn: $themeManager.isDarkMode)
                }

                // Goals Section
                Section {
                    Picker("Weekly Workout Goal", selection: $weeklyWorkoutGoal) {
                        ForEach(1...7, id: \.self) { number in
                            Text("\(number) workout\(number == 1 ? "" : "s")").tag(number)
                        }
                    }
                } header: {
                    Text("Goals")
                } footer: {
                    Text("Set your target number of workouts per week to help you stay consistent.")
                }

                // Data Section
                Section("Data") {
                    Button {
                        showingImportPicker = true
                    } label: {
                        Label("Import Data", systemImage: "square.and.arrow.down")
                    }

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

                #if DEVELOPMENT
                // Developer Section (Development scheme only)
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
                        Label("Clear Dev Data", systemImage: "trash.fill")
                    }
                } header: {
                    Text("Developer")
                } footer: {
                    Text("🧪 DEVELOPMENT BUILD: These options are only available in the Tempus Dev scheme and won't appear in production builds.")
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
            .sheet(item: $exportItem) { item in
                ShareSheet(items: [item.url])
                    .presentationDetents([.medium, .large])
            }
            .fileImporter(
                isPresented: $showingImportPicker,
                allowedContentTypes: [.json],
                allowsMultipleSelection: false
            ) { result in
                handleImportFile(result: result)
            }
            .alert("Export Error", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportErrorMessage)
            }
            .alert("Import Data?", isPresented: $showingImportConfirmation) {
                Button("Cancel", role: .cancel) {
                    importData = nil
                }
                Button("Import", role: .destructive) {
                    performImport()
                }
            } message: {
                if let data = importData {
                    Text("This will replace ALL your current data with the imported data.\n\nImporting: \(data.metadata.totalWorkouts) workouts, \(data.metadata.totalExercises) exercises, \(data.metadata.totalRoutines) routines.\n\nThis action cannot be undone.")
                }
            }
            .alert("Import Successful!", isPresented: $showingImportSuccess) {
                Button("OK", role: .cancel) { }
            } message: {
                if let data = importData {
                    Text("Successfully imported \(data.metadata.totalWorkouts) workouts, \(data.metadata.totalExercises) exercises, and \(data.metadata.totalRoutines) routines.")
                }
            }
            .alert("Import Error", isPresented: $showingImportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(importErrorMessage)
            }
            .alert("Reset App to Default?", isPresented: $showingResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset App", role: .destructive) {
                    resetAppToDefault()
                }
            } message: {
                Text("This will permanently delete all your workouts, exercises, routines, and settings. You will need to go through onboarding again. This action cannot be undone.")
            }
            #if DEVELOPMENT
            .alert("Sample Data Loaded!", isPresented: $showingSampleDataLoaded) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("Successfully loaded 17 exercises, 3 routines, and 7 workouts. Check the Workouts and Exercises tabs to see them!")
            }
            .alert("Data Cleared!", isPresented: $showingDataCleared) {
                Button("OK", role: .cancel) { }
            } message: {
                Text("All exercises, routines, and workouts have been deleted from the development database.")
            }
            #endif
        }
    }

    private func exportAllData() {
        // Calculate date range from workouts
        let sortedWorkouts = workouts.sorted { $0.workoutDate < $1.workoutDate }
        let dateRange: ExportDateRange? = {
            guard let earliest = sortedWorkouts.first?.workoutDate,
                  let latest = sortedWorkouts.last?.workoutDate else {
                return nil
            }
            return ExportDateRange(earliest: earliest, latest: latest)
        }()

        // Create metadata
        let metadata = ExportMetadata(
            exportDate: Date(),
            appVersion: "1.0.0",
            totalWorkouts: workouts.count,
            totalExercises: exercises.count,
            totalRoutines: routines.count,
            dateRange: dateRange
        )

        // Create user settings
        let userSettings = ExportUserSettings(
            userName: userName,
            weeklyWorkoutGoal: weeklyWorkoutGoal
        )

        let exportModel = ExportData(
            version: "1.1.0",
            userSettings: userSettings,
            metadata: metadata,
            workouts: workouts.map { workout in
                ExportWorkout(
                    id: workout.id.uuidString,
                    routineID: workout.routine?.id.uuidString,
                    name: workout.workoutName,
                    date: workout.workoutDate,
                    notes: workout.notes,
                    createdAt: workout.createdAt,
                    exercises: workout.exercisesData.map { exerciseData in
                        // Look up muscle group from Exercise database using exerciseID
                        let muscleGroup = exercises.first(where: { $0.id == exerciseData.exerciseID })?.muscleGroup

                        return ExportExercise(
                            exerciseID: exerciseData.exerciseID.uuidString,
                            name: exerciseData.exerciseName,
                            muscleGroup: muscleGroup,
                            isUnilateral: exerciseData.isUnilateral,
                            sets: exerciseData.sets.map { set in
                                ExportSet(
                                    setNumber: set.setNumber,
                                    weightsAndReps: set.weightsAndReps.map { wr in
                                        ExportWeightRep(weight: wr.weight, reps: wr.reps)
                                    }
                                )
                            },
                            notes: exerciseData.notes
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
                    tags: exercise.tags,
                    imageURL: exercise.imageURL,
                    isArchived: exercise.isArchived,
                    createdAt: exercise.createdAt,
                    updatedAt: exercise.updatedAt
                )
            },
            routines: routines.map { routine in
                ExportRoutine(
                    id: routine.id.uuidString,
                    name: routine.name,
                    description: routine.routineDescription,
                    emoji: routine.emoji,
                    exerciseIDs: routine.exercises.map { $0.id.uuidString },
                    createdAt: routine.createdAt,
                    updatedAt: routine.updatedAt
                )
            },
            exportDate: Date()
        )

        do {
            // Encode to JSON
            let encoder = JSONEncoder()
            encoder.dateEncodingStrategy = .iso8601
            encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
            let data = try encoder.encode(exportModel)

            // Create filename with date
            let dateFormatter = DateFormatter()
            dateFormatter.locale = Locale(identifier: "en_GB")
            dateFormatter.dateFormat = "yyyy-MM-dd"
            let dateString = dateFormatter.string(from: Date())
            let filename = "tempus-export-\(dateString).json"

            // Write to temporary file
            let tempURL = FileManager.default.temporaryDirectory
                .appendingPathComponent(filename)

            try data.write(to: tempURL)

            // Trigger success haptic and show share sheet
            HapticManager.shared.trigger(.success)
            exportItem = ExportItem(url: tempURL)
        } catch {
            // Show error to user
            exportErrorMessage = "Failed to export data: \(error.localizedDescription)"
            showingExportError = true
            HapticManager.shared.trigger(.error)
        }
    }

    private func handleImportFile(result: Result<[URL], Error>) {
        do {
            let fileURL = try result.get().first
            guard let fileURL = fileURL else {
                importErrorMessage = "No file selected"
                showingImportError = true
                return
            }

            // Start accessing security-scoped resource
            guard fileURL.startAccessingSecurityScopedResource() else {
                importErrorMessage = "Permission denied. Unable to access the file."
                showingImportError = true
                return
            }

            defer {
                fileURL.stopAccessingSecurityScopedResource()
            }

            // Read and decode JSON
            let data = try Data(contentsOf: fileURL)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let exportData = try decoder.decode(ExportData.self, from: data)

            // Store data and show confirmation
            importData = exportData
            showingImportConfirmation = true
        } catch {
            importErrorMessage = "Failed to read import file: \(error.localizedDescription)"
            showingImportError = true
            HapticManager.shared.trigger(.error)
        }
    }

    private func performImport() {
        guard let data = importData else { return }

        do {
            HapticManager.shared.trigger(.warning)

            // Step 1: Delete all existing data
            for workout in workouts {
                modelContext.delete(workout)
            }
            for routine in routines {
                modelContext.delete(routine)
            }
            for exercise in exercises {
                modelContext.delete(exercise)
            }

            // Step 2: Import exercises first (maintain UUIDs)
            var exerciseMap: [String: Exercise] = [:]
            for exportExercise in data.exercises {
                guard let uuid = UUID(uuidString: exportExercise.id) else { continue }

                let exercise = Exercise(
                    name: exportExercise.name,
                    muscleGroup: exportExercise.muscleGroup,
                    tags: exportExercise.tags,
                    exerciseDescription: exportExercise.description,
                    imageURL: exportExercise.imageURL
                )
                exercise.id = uuid
                exercise.isArchived = exportExercise.isArchived
                exercise.createdAt = exportExercise.createdAt
                exercise.updatedAt = exportExercise.updatedAt

                modelContext.insert(exercise)
                exerciseMap[exportExercise.id] = exercise
            }

            // Step 3: Import routines (link to exercises)
            var routineMap: [String: WorkoutRoutine] = [:]
            for exportRoutine in data.routines {
                guard let uuid = UUID(uuidString: exportRoutine.id) else { continue }

                // Link to exercises
                let linkedExercises = exportRoutine.exerciseIDs.compactMap { exerciseMap[$0] }

                let routine = WorkoutRoutine(
                    name: exportRoutine.name,
                    routineDescription: exportRoutine.description,
                    emoji: exportRoutine.emoji,
                    exercises: linkedExercises
                )
                routine.id = uuid
                routine.createdAt = exportRoutine.createdAt
                routine.updatedAt = exportRoutine.updatedAt

                modelContext.insert(routine)
                routineMap[exportRoutine.id] = routine
            }

            // Step 4: Import workouts
            for exportWorkout in data.workouts {
                guard let uuid = UUID(uuidString: exportWorkout.id) else { continue }

                // Convert exercises data
                let exercisesData = exportWorkout.exercises.map { exportExercise -> WorkoutExerciseData in
                    guard let exerciseUUID = UUID(uuidString: exportExercise.exerciseID) else {
                        fatalError("Invalid exercise ID")
                    }

                    let sets = exportExercise.sets.map { exportSet -> WorkoutSet in
                        let weightsAndReps = exportSet.weightsAndReps.map { exportWR in
                            WeightRep(weight: exportWR.weight, reps: exportWR.reps)
                        }
                        return WorkoutSet(setNumber: exportSet.setNumber, weightsAndReps: weightsAndReps)
                    }

                    return WorkoutExerciseData(
                        exerciseID: exerciseUUID,
                        exerciseName: exportExercise.name,
                        isUnilateral: exportExercise.isUnilateral,
                        sets: sets,
                        notes: exportExercise.notes
                    )
                }

                // Link to routine if applicable
                let routine = exportWorkout.routineID.flatMap { routineMap[$0] }

                let workout = WorkoutEntry(
                    name: exportWorkout.name,
                    date: exportWorkout.date,
                    routine: routine,
                    exercisesData: exercisesData,
                    notes: exportWorkout.notes
                )
                workout.id = uuid
                workout.createdAt = exportWorkout.createdAt

                modelContext.insert(workout)
            }

            // Step 5: Import user settings
            userName = data.userSettings.userName
            weeklyWorkoutGoal = data.userSettings.weeklyWorkoutGoal

            // Step 6: Save everything
            try modelContext.save()

            // Step 7: Reload widgets
            WidgetCenter.shared.reloadAllTimelines()

            // Success!
            HapticManager.shared.trigger(.success)
            showingImportSuccess = true
        } catch {
            importErrorMessage = "Import failed: \(error.localizedDescription)"
            showingImportError = true
            HapticManager.shared.trigger(.error)
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
        weeklyWorkoutGoal = 3
        hasCompletedOnboarding = false

        // Trigger success haptic
        HapticManager.shared.trigger(.success)
    }
}

// MARK: - Export Data Models

struct ExportData: Codable, Sendable {
    let version: String
    let userSettings: ExportUserSettings
    let metadata: ExportMetadata
    let workouts: [ExportWorkout]
    let exercises: [ExportExerciseDefinition]
    let routines: [ExportRoutine]
    let exportDate: Date
}

struct ExportUserSettings: Codable, Sendable {
    let userName: String
    let weeklyWorkoutGoal: Int
}

struct ExportMetadata: Codable, Sendable {
    let exportDate: Date
    let appVersion: String
    let totalWorkouts: Int
    let totalExercises: Int
    let totalRoutines: Int
    let dateRange: ExportDateRange?
}

struct ExportDateRange: Codable, Sendable {
    let earliest: Date
    let latest: Date
}

struct ExportWorkout: Codable, Sendable {
    let id: String
    let routineID: String?
    let name: String
    let date: Date
    let notes: String?
    let createdAt: Date
    let exercises: [ExportExercise]
}

struct ExportExercise: Codable, Sendable {
    let exerciseID: String
    let name: String
    let muscleGroup: String?
    let isUnilateral: Bool
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
    let imageURL: String?
    let isArchived: Bool
    let createdAt: Date
    let updatedAt: Date
}

struct ExportRoutine: Codable, Sendable {
    let id: String
    let name: String
    let description: String?
    let emoji: String?
    let exerciseIDs: [String]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Share Sheet

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    @Environment(\.colorScheme) var colorScheme

    func makeUIViewController(context: Context) -> UIActivityViewController {
        let controller = UIActivityViewController(activityItems: items, applicationActivities: nil)

        // Sync SwiftUI colorScheme with UIKit interface style
        controller.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light

        return controller
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: Context) {
        // Update interface style when color scheme changes
        uiViewController.overrideUserInterfaceStyle = colorScheme == .dark ? .dark : .light
    }
}

// MARK: - Export Item

struct ExportItem: Identifiable {
    let id = UUID()
    let url: URL
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}