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

    init(date: Date = Date(), template: WorkoutTemplate? = nil) {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium

        if let template = template {
            print("DEBUG: WorkoutLoggingView init with template - \(template.name)")
            print("DEBUG: Template has \(template.exercises.count) exercises")

            _workoutName = State(initialValue: template.name)
            _workoutDate = State(initialValue: date)

            // Pre-populate exercises from template
            let entries = template.exercises.map { exercise in
                print("DEBUG: Adding exercise from template - \(exercise.name)")
                return WorkoutExerciseEntry(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name
                )
            }
            print("DEBUG: Created \(entries.count) workout entries from template")
            _workoutExercises = State(initialValue: entries)
        } else {
            print("DEBUG: WorkoutLoggingView init without template")
            _workoutName = State(initialValue: "Workout - \(formatter.string(from: date))")
            _workoutDate = State(initialValue: date)
        }
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
                    Label("Workout Details", systemImage: "figure.strengthtraining.traditional")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.accent)
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
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                        removeExercise(exerciseEntry)
                                    }
                                } label: {
                                    Image(systemName: "trash")
                                        .font(.caption)
                                        .symbolRenderingMode(.hierarchical)
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
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                // Notes Section
                Section {
                    TextField("Workout notes (optional)", text: $workoutNotes, axis: .vertical)
                        .lineLimit(3...6)
                } header: {
                    Label("Notes", systemImage: "note.text")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.secondary)
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

    // Init for new exercise (empty set)
    init(exerciseID: UUID, exerciseName: String) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        // Initialize with one empty set (no default weight/reps)
        self.sets = [WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 0, reps: 0)])]
        self.notes = nil
    }

    // Init for editing existing exercise
    init(exerciseID: UUID, exerciseName: String, sets: [WorkoutSet], notes: String?) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.sets = sets
        self.notes = notes
    }
}

// Exercise entry view with sets
struct ExerciseEntryView: View {
    @Binding var exerciseEntry: WorkoutExerciseEntry

    var body: some View {
        VStack(spacing: 12) {
            // Sets
            ForEach(exerciseEntry.sets.indices, id: \.self) { index in
                HStack {
                    SetEntryRow(set: $exerciseEntry.sets[index])

                    // Delete set button (only show if more than 1 set)
                    if exerciseEntry.sets.count > 1 {
                        Button(role: .destructive) {
                            deleteSet(exerciseEntry.sets[index])
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                        }
                        .buttonStyle(.borderless)
                    }
                }
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

    private func deleteSet(_ set: WorkoutSet) {
        exerciseEntry.sets.removeAll { $0.id == set.id }
        // Renumber remaining sets
        for (index, _) in exerciseEntry.sets.enumerated() {
            exerciseEntry.sets[index] = WorkoutSet(
                setNumber: index + 1,
                weightsAndReps: exerciseEntry.sets[index].weightsAndReps
            )
        }
        print("DEBUG: Deleted set from \(exerciseEntry.exerciseName), \(exerciseEntry.sets.count) sets remaining")
    }
}

// Individual set entry row with horizontal scroll
struct SetEntryRow: View {
    @Binding var set: WorkoutSet

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.accent)
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

                        Image(systemName: "xmark")
                            .font(.caption2)
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    removeWeightRep(wr)
                                }
                            } label: {
                                Image(systemName: "minus.circle.fill")
                                    .foregroundStyle(.red)
                                    .symbolRenderingMode(.hierarchical)
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
                        .symbolRenderingMode(.hierarchical)
                }
                .buttonStyle(.borderless)
            }
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
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    addExercise(exercise)
                                }
                            } label: {
                                HStack {
                                    Text(exercise.name)
                                    Spacer()
                                    if isSelected(exercise) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundStyle(.accent)
                                            .symbolRenderingMode(.hierarchical)
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