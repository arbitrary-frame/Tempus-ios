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
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = true

    @State private var exportData: Data?
    @State private var exportFilename: String?
    @State private var showingShareSheet = false
    @State private var showingResetConfirmation = false
    @State private var showingExportError = false
    @State private var exportErrorMessage = ""
    @State private var showingSampleDataLoaded = false
    @State private var showingDataCleared = false

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
            .background(
                EmptyView()
                    .fullScreenCover(isPresented: $showingShareSheet) {
                        if let data = exportData, let filename = exportFilename {
                            ActivityViewController(
                                activityItems: [JSONActivityItemSource(data: data, filename: filename)]
                            )
                        }
                    }
            )
            .alert("Export Error", isPresented: $showingExportError) {
                Button("OK", role: .cancel) { }
            } message: {
                Text(exportErrorMessage)
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

        let exportModel = ExportData(
            version: "1.0.0",
            metadata: metadata,
            workouts: workouts.map { workout in
                ExportWorkout(
                    id: workout.id.uuidString,
                    name: workout.workoutName,
                    date: workout.workoutDate,
                    notes: workout.notes,
                    exercises: workout.exercisesData.map { exerciseData in
                        // Look up muscle group from Exercise database using exerciseID
                        let muscleGroup = exercises.first(where: { $0.id == exerciseData.exerciseID })?.muscleGroup

                        return ExportExercise(
                            name: exerciseData.exerciseName,
                            muscleGroup: muscleGroup,
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
                    tags: exercise.tags
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

            // Store data and filename for sharing
            exportData = data
            exportFilename = filename

            // Trigger success haptic and show share sheet
            HapticManager.shared.trigger(.success)

            // Small delay to ensure state is set
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                showingShareSheet = true
            }

            print("✅ Export ready: \(filename)")
            print("   File size: \(data.count) bytes")
        } catch {
            // Show error to user
            exportErrorMessage = "Failed to export data: \(error.localizedDescription)"
            showingExportError = true
            HapticManager.shared.trigger(.error)
            print("❌ Export failed: \(error)")
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
    let metadata: ExportMetadata
    let workouts: [ExportWorkout]
    let exercises: [ExportExerciseDefinition]
    let routines: [ExportRoutine]
    let exportDate: Date
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
    let name: String
    let date: Date
    let notes: String?
    let exercises: [ExportExercise]
}

struct ExportExercise: Codable, Sendable {
    let name: String
    let muscleGroup: String?
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

struct ExportRoutine: Codable, Sendable {
    let id: String
    let name: String
    let description: String?
    let emoji: String?
    let exerciseIDs: [String]
    let createdAt: Date
    let updatedAt: Date
}

// MARK: - Activity View Controller

struct ActivityViewController: UIViewControllerRepresentable {
    let activityItems: [Any]
    let applicationActivities: [UIActivity]? = nil

    func makeUIViewController(context: UIViewControllerRepresentableContext<ActivityViewController>) -> UIActivityViewController {
        return UIActivityViewController(
            activityItems: activityItems,
            applicationActivities: applicationActivities
        )
    }

    func updateUIViewController(_ uiViewController: UIActivityViewController, context: UIViewControllerRepresentableContext<ActivityViewController>) {}
}

// MARK: - JSON Activity Item Source

import UniformTypeIdentifiers
import LinkPresentation

class JSONActivityItemSource: NSObject, UIActivityItemSource {
    private let data: Data
    private let filename: String

    init(data: Data, filename: String) {
        self.data = data
        self.filename = filename
        super.init()
    }

    func activityViewControllerPlaceholderItem(_ activityViewController: UIActivityViewController) -> Any {
        return data
    }

    func activityViewController(_ activityViewController: UIActivityViewController, itemForActivityType activityType: UIActivity.ActivityType?) -> Any? {
        return data
    }

    func activityViewController(_ activityViewController: UIActivityViewController, dataTypeIdentifierForActivityType activityType: UIActivity.ActivityType?) -> String {
        return UTType.json.identifier
    }

    func activityViewController(_ activityViewController: UIActivityViewController, subjectForActivityType activityType: UIActivity.ActivityType?) -> String {
        return "Tempus Workout Data"
    }

    func activityViewControllerLinkMetadata(_ activityViewController: UIActivityViewController) -> LPLinkMetadata? {
        let metadata = LPLinkMetadata()
        metadata.title = filename
        return metadata
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}