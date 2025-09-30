//
//  WorkoutLoggingView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]

    @State private var workoutName: String
    @State private var workoutDate: Date
    @State private var workoutExercises: [WorkoutExerciseEntry] = []
    @State private var showingExercisePicker = false
    @State private var workoutNotes: String = ""

    init(date: Date = Date()) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        _workoutName = State(initialValue: "Workout - \(formatter.string(from: date))")
        _workoutDate = State(initialValue: date)
    }

    var body: some View {
        NavigationStack {
            List {
                // Header Section - Workout Name and Date
                Section {
                    TextField("Workout Name", text: $workoutName)
                        .font(.title2.bold())

                    DatePicker("Date", selection: $workoutDate, displayedComponents: .date)
                        .environment(\.locale, Locale(identifier: "en_GB"))
                } header: {
                    Text("Workout Details")
                }

                // Exercises Section
                if !workoutExercises.isEmpty {
                    ForEach($workoutExercises) { $exerciseEntry in
                        Section {
                            ExerciseEntryView(exerciseEntry: $exerciseEntry)
                        } header: {
                            HStack {
                                Text(exerciseEntry.exerciseName)
                                    .font(.headline)
                                Spacer()
                                Button(role: .destructive) {
                                    removeExercise(exerciseEntry)
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }
                }

                // Add Exercise Button
                Section {
                    Button {
                        showingExercisePicker = true
                        print("DEBUG: Add exercise button tapped")
                    } label: {
                        Label("Add Exercise", systemImage: "plus.circle.fill")
                    }
                }

                // Notes Section
                Section {
                    TextField("Workout notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Text("Notes")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Log Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("DEBUG: Workout logging cancelled")
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWorkout()
                    }
                    .disabled(workoutExercises.isEmpty || workoutName.isEmpty)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                ExercisePickerView(selectedExercises: $workoutExercises)
            }
        }
    }

    private func removeExercise(_ exercise: WorkoutExerciseEntry) {
        workoutExercises.removeAll { $0.id == exercise.id }
        print("DEBUG: Removed exercise - \(exercise.exerciseName)")
    }

    private func saveWorkout() {
        // Convert WorkoutExerciseEntry to WorkoutExerciseData
        let exercisesData = workoutExercises.map { entry in
            WorkoutExerciseData(
                exerciseID: entry.exerciseID,
                exerciseName: entry.exerciseName,
                sets: entry.sets,
                notes: entry.notes
            )
        }

        let workout = WorkoutEntry(
            name: workoutName,
            date: workoutDate,
            exercisesData: exercisesData,
            notes: workoutNotes.isEmpty ? nil : workoutNotes
        )

        modelContext.insert(workout)
        print("DEBUG: Workout saved - \(workoutName) with \(exercisesData.count) exercises")
        dismiss()
    }
}

// Temporary model for UI state (before saving to WorkoutEntry)
struct WorkoutExerciseEntry: Identifiable {
    let id = UUID()
    let exerciseID: UUID
    let exerciseName: String
    var sets: [WorkoutSet]
    var notes: String?

    init(exerciseID: UUID, exerciseName: String) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        // Initialize with one empty set (no default weight/reps)
        self.sets = [WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 0, reps: 0)])]
        self.notes = nil
    }
}

// Exercise entry view with sets
struct ExerciseEntryView: View {
    @Binding var exerciseEntry: WorkoutExerciseEntry

    var body: some View {
        VStack(spacing: 12) {
            // Sets
            ForEach($exerciseEntry.sets) { $set in
                SetEntryRow(set: $set)
            }

            // Add Set Button
            Button {
                addSet()
            } label: {
                Label("Add Set", systemImage: "plus.circle")
            }
            .buttonStyle(.borderless)

            // Exercise Notes
            TextField("Exercise notes (optional)", text: Binding(
                get: { exerciseEntry.notes ?? "" },
                set: { exerciseEntry.notes = $0.isEmpty ? nil : $0 }
            ), axis: .vertical)
            .lineLimit(2...4)
            .font(.caption)
        }
    }

    private func addSet() {
        let newSetNumber = exerciseEntry.sets.count + 1
        exerciseEntry.sets.append(WorkoutSet(setNumber: newSetNumber, weightsAndReps: [WeightRep(weight: 0, reps: 0)]))
        print("DEBUG: Added set \(newSetNumber) to \(exerciseEntry.exerciseName)")
    }
}

// Individual set entry row
struct SetEntryRow: View {
    @Binding var set: WorkoutSet

    var body: some View {
        HStack(spacing: 12) {
            Text("Set \(set.setNumber)")
                .font(.subheadline)
                .frame(width: 50, alignment: .leading)

            // Weight/Rep pairs (for drop sets)
            ForEach($set.weightsAndReps) { $wr in
                HStack(spacing: 4) {
                    TextField("kg", text: Binding(
                        get: { wr.weight == 0 ? "" : "\(wr.weight)" },
                        set: { wr.weight = Double($0) ?? 0 }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)

                    Text("×")
                        .foregroundStyle(.secondary)

                    TextField("reps", text: Binding(
                        get: { wr.reps == 0 ? "" : "\(wr.reps)" },
                        set: { wr.reps = Int($0) ?? 0 }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)

                    if set.weightsAndReps.count > 1 {
                        Button {
                            removeWeightRep(wr)
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
            }

            // Add Drop Set Button
            Button {
                addDropSet()
            } label: {
                Image(systemName: "plus.circle")
            }
            .buttonStyle(.borderless)
        }
    }

    private func addDropSet() {
        set.weightsAndReps.append(WeightRep())
        print("DEBUG: Added drop set to set \(set.setNumber)")
    }

    private func removeWeightRep(_ wr: WeightRep) {
        set.weightsAndReps.removeAll { $0.id == wr.id }
        print("DEBUG: Removed drop set from set \(set.setNumber)")
    }
}

// Exercise picker sheet
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selectedExercises: [WorkoutExerciseEntry]
    @State private var searchText = ""

    var filteredExercises: [Exercise] {
        let available = allExercises.filter { !$0.isArchived }
        if searchText.isEmpty {
            return available
        } else {
            return available.filter { $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.muscleGroup }
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
                    Section {
                        ForEach(groupedExercises[muscleGroup]!) { exercise in
                            Button {
                                addExercise(exercise)
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    if isSelected(exercise) {
                                        Image(systemName: "checkmark")
                                            .foregroundStyle(.accent)
                                    }
                                }
                            }
                        }
                    } header: {
                        if let group = MuscleGroup(rawValue: muscleGroup) {
                            Label(muscleGroup, systemImage: group.icon)
                        } else {
                            Text(muscleGroup)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Add Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.exerciseID == exercise.id }
    }

    private func addExercise(_ exercise: Exercise) {
        if isSelected(exercise) {
            // Remove if already selected
            selectedExercises.removeAll { $0.exerciseID == exercise.id }
            print("DEBUG: Removed \(exercise.name) from workout")
        } else {
            // Add new exercise
            let entry = WorkoutExerciseEntry(
                exerciseID: exercise.id,
                exerciseName: exercise.name
            )
            selectedExercises.append(entry)
            print("DEBUG: Added \(exercise.name) to workout")
        }
    }
}

#Preview {
    WorkoutLoggingView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}