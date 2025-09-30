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
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]

    @State private var workoutName: String
    @State private var workoutDate: Date
    @State private var workoutExercises: [WorkoutExerciseEntry] = []
    @State private var showingExercisePicker = false
    @State private var workoutNotes: String = ""

    // Track if name was from routine to auto-update it
    private let routineName: String?
    private let isFromRoutine: Bool
    private let sourceRoutine: WorkoutRoutine?

    // Cached previous workout data lookup - prevents N+1 query pattern
    private var previousWorkoutDataCache: [UUID: WorkoutExerciseData] {
        var cache: [UUID: WorkoutExerciseData] = [:]
        for workout in allWorkouts {
            for exerciseData in workout.exercisesData {
                // Only keep the most recent (first occurrence due to reverse sort)
                if cache[exerciseData.exerciseID] == nil {
                    cache[exerciseData.exerciseID] = exerciseData
                }
            }
        }
        return cache
    }

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        return formatter
    }()

    init(date: Date = Date(), routine: WorkoutRoutine? = nil) {
        self.sourceRoutine = routine

        if let routine = routine {
            self.routineName = routine.name
            self.isFromRoutine = true
            _workoutName = State(initialValue: "\(routine.name) - \(Self.dateFormatter.string(from: date))")
            _workoutDate = State(initialValue: date)

            // Pre-populate exercises from routine
            let entries = routine.exercises.map { exercise in
                return WorkoutExerciseEntry(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name
                )
            }
            _workoutExercises = State(initialValue: entries)
        } else {
            self.routineName = nil
            self.isFromRoutine = false
            _workoutName = State(initialValue: "Workout - \(Self.dateFormatter.string(from: date))")
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
                        .onChange(of: workoutDate) { oldValue, newValue in
                            updateWorkoutNameIfNeeded(for: newValue)
                        }
                } header: {
                    Label("Workout Details", systemImage: "figure.strengthtraining.traditional")
                        .symbolRenderingMode(.hierarchical)
                        .foregroundStyle(.accent)
                }

                // Exercises Section
                if !workoutExercises.isEmpty {
                    ForEach($workoutExercises) { $exerciseEntry in
                        Section {
                            ExerciseEntryView(
                                exerciseEntry: $exerciseEntry,
                                previousData: previousWorkoutDataCache[exerciseEntry.exerciseID]
                            )
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
        HapticManager.shared.trigger(.light)
        workoutExercises.removeAll { $0.id == exercise.id }
    }

    private func updateWorkoutNameIfNeeded(for date: Date) {
        // Only auto-update if workout is from routine
        guard isFromRoutine, let routineName = routineName else { return }

        workoutName = "\(routineName) - \(Self.dateFormatter.string(from: date))"
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
            routine: sourceRoutine,
            exercisesData: exercisesData,
            notes: workoutNotes.isEmpty ? nil : workoutNotes
        )

        modelContext.insert(workout)
        HapticManager.shared.trigger(.success)
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
    let previousData: WorkoutExerciseData?
    @FocusState private var focusedField: Int?

    // Calculate total field count for keyboard navigation
    private var totalFieldCount: Int {
        exerciseEntry.sets.reduce(0) { total, set in
            total + (set.weightsAndReps.count * 2) // 2 fields per weight/rep pair
        }
    }

    var body: some View {
        VStack(spacing: 12) {
            // Previous workout preview
            if let previous = previousData {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Last Session")
                        .font(.caption.bold())
                        .foregroundStyle(.secondary)

                    HStack(spacing: 4) {
                        ForEach(previous.sets.prefix(3), id: \.id) { set in
                            Text(formatSet(set))
                                .font(.caption)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial)
                                .clipShape(Capsule())
                        }
                        if previous.sets.count > 3 {
                            Text("+\(previous.sets.count - 3)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.vertical, 4)
            }

            // Sets
            ForEach(exerciseEntry.sets.indices, id: \.self) { index in
                let baseFieldIndex = exerciseEntry.sets[..<index].reduce(0) { total, set in
                    total + (set.weightsAndReps.count * 2)
                }

                HStack {
                    SetEntryRow(
                        set: $exerciseEntry.sets[index],
                        focusedField: $focusedField,
                        baseFieldIndex: baseFieldIndex,
                        totalFieldCount: totalFieldCount
                    )

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

            // Exercise Notes (only show if notes exist)
            if let notes = exerciseEntry.notes, !notes.isEmpty {
                TextField("Exercise notes", text: Binding(
                    get: { exerciseEntry.notes ?? "" },
                    set: { exerciseEntry.notes = $0.isEmpty ? nil : $0 }
                ), axis: .vertical)
                .lineLimit(2...4)
                .font(.caption)
            }
        }
    }

    private func addSet() {
        let newSetNumber = exerciseEntry.sets.count + 1
        HapticManager.shared.trigger(.light)
        exerciseEntry.sets.append(WorkoutSet(setNumber: newSetNumber, weightsAndReps: [WeightRep(weight: 0, reps: 0)]))
    }

    private func deleteSet(_ set: WorkoutSet) {
        HapticManager.shared.trigger(.light)
        exerciseEntry.sets.removeAll { $0.id == set.id }
        // Renumber remaining sets
        for (index, _) in exerciseEntry.sets.enumerated() {
            exerciseEntry.sets[index] = WorkoutSet(
                setNumber: index + 1,
                weightsAndReps: exerciseEntry.sets[index].weightsAndReps
            )
        }
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weightReps = set.weightsAndReps.map { wr in
            if wr.weight == 0 && wr.reps == 0 {
                return "—"
            }
            return "\(Int(wr.weight))kg × \(wr.reps)"
        }.joined(separator: " → ")
        return weightReps
    }
}

// Individual set entry row with horizontal scroll
struct SetEntryRow: View {
    @Binding var set: WorkoutSet
    @FocusState.Binding var focusedField: Int?
    let baseFieldIndex: Int
    let totalFieldCount: Int

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                Text("Set \(set.setNumber)")
                    .font(.subheadline.bold())
                    .foregroundStyle(.accent)
                    .frame(width: 50, alignment: .leading)

                // Weight/Rep pairs (for drop sets)
                ForEach(set.weightsAndReps.indices, id: \.self) { wrIndex in
                    let weightFieldIndex = baseFieldIndex + (wrIndex * 2)
                    let repsFieldIndex = baseFieldIndex + (wrIndex * 2) + 1

                    HStack(spacing: 4) {
                        TextField("kg", text: Binding(
                            get: { set.weightsAndReps[wrIndex].weight == 0 ? "" : "\(set.weightsAndReps[wrIndex].weight)" },
                            set: { set.weightsAndReps[wrIndex].weight = Double($0) ?? 0 }
                        ))
                        .keyboardType(.decimalPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 60)
                        .keyboardToolbar(
                            focusedField: $focusedField,
                            currentField: weightFieldIndex,
                            fieldCount: totalFieldCount
                        )

                        Image(systemName: "xmark")
                            .font(.caption2)
                            .foregroundStyle(.secondary)

                        TextField("reps", text: Binding(
                            get: { set.weightsAndReps[wrIndex].reps == 0 ? "" : "\(set.weightsAndReps[wrIndex].reps)" },
                            set: { set.weightsAndReps[wrIndex].reps = Int($0) ?? 0 }
                        ))
                        .keyboardType(.numberPad)
                        .textFieldStyle(.roundedBorder)
                        .frame(width: 50)
                        .keyboardToolbar(
                            focusedField: $focusedField,
                            currentField: repsFieldIndex,
                            fieldCount: totalFieldCount
                        )

                        if set.weightsAndReps.count > 1 {
                            Button {
                                withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                    removeWeightRep(at: wrIndex)
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
        HapticManager.shared.trigger(.light)
        set.weightsAndReps.append(WeightRep())
    }

    private func removeWeightRep(at index: Int) {
        HapticManager.shared.trigger(.light)
        set.weightsAndReps.remove(at: index)
    }
}

// Exercise picker sheet
struct ExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selectedExercises: [WorkoutExerciseEntry]
    @State private var searchText = ""
    @State private var showingExerciseForm = false

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
                ToolbarItem(placement: .cancellationAction) {
                    Button {
                        showingExerciseForm = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
            .sheet(isPresented: $showingExerciseForm) {
                ExerciseFormView()
            }
        }
    }

    private func isSelected(_ exercise: Exercise) -> Bool {
        selectedExercises.contains { $0.exerciseID == exercise.id }
    }

    private func addExercise(_ exercise: Exercise) {
        HapticManager.shared.trigger(.selection)
        if isSelected(exercise) {
            // Remove if already selected
            selectedExercises.removeAll { $0.exerciseID == exercise.id }
        } else {
            // Add new exercise
            let entry = WorkoutExerciseEntry(
                exerciseID: exercise.id,
                exerciseName: exercise.name
            )
            selectedExercises.append(entry)
        }
    }
}

#Preview {
    WorkoutLoggingView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}