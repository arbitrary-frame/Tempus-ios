//
//  WorkoutLoggingView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData
import WidgetKit

struct WorkoutLoggingView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query private var allExercises: [Exercise]
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]

    @State private var workoutName: String
    @State private var workoutDate: Date
    @State private var workoutExercises: [WorkoutExerciseEntry] = []
    @State private var showingExercisePicker = false
    @State private var showingReorderSheet = false
    @State private var workoutNotes: String = ""
    @State private var selectedExerciseForInfo: Exercise?

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

    init(date: Date = Date(), routine: WorkoutRoutine? = nil, allExercises: [Exercise] = []) {
        self.sourceRoutine = routine

        if let routine = routine {
            self.routineName = routine.name
            self.isFromRoutine = true
            _workoutName = State(initialValue: "\(routine.name) - \(Self.dateFormatter.string(from: date))")
            _workoutDate = State(initialValue: date)

            // Pre-populate exercises from routine using exerciseIDs for correct order
            let orderedExercises: [Exercise]
            if !routine.exerciseIDs.isEmpty {
                // Use exerciseIDs for order (preserves user's order)
                orderedExercises = routine.exerciseIDs.compactMap { id in
                    allExercises.first { $0.id == id }
                }
            } else {
                // Fallback to exercises relationship (backward compatibility)
                orderedExercises = routine.exercises
            }

            let entries = orderedExercises.map { exercise in
                return WorkoutExerciseEntry(
                    exerciseID: exercise.id,
                    exerciseName: exercise.name,
                    isUnilateral: exercise.tags.contains("unilateral")
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
                            HStack(spacing: 8) {
                                Text(exerciseEntry.exerciseName)
                                    .font(.headline)

                                // Info button
                                if let exercise = allExercises.first(where: { $0.id == exerciseEntry.exerciseID }) {
                                    Button {
                                        selectedExerciseForInfo = exercise
                                    } label: {
                                        Image(systemName: "info.circle")
                                            .font(.caption)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.secondary)
                                    }
                                    .buttonStyle(.borderless)
                                }

                                // Unilateral badge (if applicable)
                                if exerciseEntry.isUnilateral {
                                    Text("Unilateral")
                                        .font(.caption)
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 6)
                                        .background(.regularMaterial, in: Capsule())
                                }

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
            .navigationTitle("Log")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Menu {
                        Button {
                            showingReorderSheet = true
                        } label: {
                            Label("Reorder Exercises", systemImage: "line.3.horizontal")
                        }
                        .disabled(workoutExercises.count < 2)
                    } label: {
                        Image(systemName: "ellipsis.circle")
                    }
                }

                ToolbarItem(placement: .automatic) {
                    Button {
                        showingExercisePicker = true
                    } label: {
                        Image(systemName: "plus")
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
            .sheet(isPresented: $showingReorderSheet) {
                WorkoutExerciseReorderView(exercises: $workoutExercises)
            }
            .sheet(item: $selectedExerciseForInfo) { exercise in
                ExerciseInfoSheet(exercise: exercise)
            }
        }
    }

    private func removeExercise(_ exercise: WorkoutExerciseEntry) {
        HapticManager.shared.trigger(.light)
        workoutExercises.removeAll { $0.id == exercise.id }
    }

    private func updateWorkoutNameIfNeeded(for date: Date) {
        // Auto-update workout name when date changes
        if isFromRoutine, let routineName = routineName {
            // From routine: "Routine Name - Date"
            workoutName = "\(routineName) - \(Self.dateFormatter.string(from: date))"
        } else {
            // Quick log: "Workout - Date"
            workoutName = "Workout - \(Self.dateFormatter.string(from: date))"
        }
    }


    private func saveWorkout() {
        // Convert WorkoutExerciseEntry to WorkoutExerciseData
        let exercisesData = workoutExercises.map { entry in
            WorkoutExerciseData(
                exerciseID: entry.exerciseID,
                exerciseName: entry.exerciseName,
                isUnilateral: entry.isUnilateral,
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

        // Save to disk immediately so widgets can access the data
        do {
            try modelContext.save()
            print("✅ Workout saved to SwiftData")
        } catch {
            print("❌ Failed to save workout: \(error)")
        }

        HapticManager.shared.trigger(.success)

        // Refresh all widgets immediately and specifically
        print("🔄 Requesting widget refresh for all kinds...")
        WidgetCenter.shared.reloadAllTimelines()
        WidgetCenter.shared.reloadTimelines(ofKind: "GoalProgressWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "ExercisesWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "WeightWidget")
        WidgetCenter.shared.reloadTimelines(ofKind: "CombinedStatsWidget")

        dismiss()
    }
}

// Temporary model for UI state (before saving to WorkoutEntry)
struct WorkoutExerciseEntry: Identifiable {
    let id = UUID()
    let exerciseID: UUID
    let exerciseName: String
    let isUnilateral: Bool
    var sets: [WorkoutSet]
    var notes: String?

    // Init for new exercise (empty set)
    init(exerciseID: UUID, exerciseName: String, isUnilateral: Bool = false) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.isUnilateral = isUnilateral
        // Initialize with one empty set (no default weight/reps)
        self.sets = [WorkoutSet(setNumber: 1, weightsAndReps: [WeightRep(weight: 0, reps: 0)])]
        self.notes = nil
    }

    // Init for editing existing exercise
    init(exerciseID: UUID, exerciseName: String, isUnilateral: Bool = false, sets: [WorkoutSet], notes: String?) {
        self.exerciseID = exerciseID
        self.exerciseName = exerciseName
        self.isUnilateral = isUnilateral
        self.sets = sets
        self.notes = notes
    }

    // Init from existing workout data
    init(from data: WorkoutExerciseData) {
        self.exerciseID = data.exerciseID
        self.exerciseName = data.exerciseName
        self.isUnilateral = data.isUnilateral
        self.sets = data.sets
        self.notes = data.notes
    }
}

// Exercise entry view with sets
struct ExerciseEntryView: View {
    @Binding var exerciseEntry: WorkoutExerciseEntry
    let previousData: WorkoutExerciseData?

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
                            Button {
                                addSetFromPrevious(set)
                            } label: {
                                Text(formatSet(set))
                                    .font(.caption)
                                    .padding(.horizontal, 8)
                                    .padding(.vertical, 4)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                            }
                            .buttonStyle(.plain)
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

            // Add Set Buttons (Repeat and Blank)
            HStack(spacing: 12) {
                // Repeat Set (left, primary)
                Button {
                    repeatSet()
                } label: {
                    Label("Repeat Set", systemImage: "arrow.counterclockwise.circle.fill")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.borderedProminent)
                .disabled(exerciseEntry.sets.isEmpty)

                // Add Blank Set (right, secondary)
                Button {
                    addSet()
                } label: {
                    Label("Add Set", systemImage: "plus.circle")
                        .font(.subheadline)
                        .frame(maxWidth: .infinity)
                }
                .buttonStyle(.bordered)
            }
            .labelStyle(.titleOnly)

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

    private func repeatSet() {
        guard let lastSet = exerciseEntry.sets.last else { return }
        let newSetNumber = exerciseEntry.sets.count + 1
        HapticManager.shared.trigger(.light)

        // Copy all weight/rep pairs from the last set (including drop sets)
        let copiedWeightsAndReps = lastSet.weightsAndReps.map { wr in
            WeightRep(weight: wr.weight, reps: wr.reps)
        }

        exerciseEntry.sets.append(WorkoutSet(setNumber: newSetNumber, weightsAndReps: copiedWeightsAndReps))
    }

    private func addSetFromPrevious(_ previousSet: WorkoutSet) {
        let newSetNumber = exerciseEntry.sets.count + 1
        HapticManager.shared.trigger(.selection)

        // Copy all weight/rep pairs from the previous set (including drop sets)
        let copiedWeightsAndReps = previousSet.weightsAndReps.map { wr in
            WeightRep(weight: wr.weight, reps: wr.reps)
        }

        exerciseEntry.sets.append(WorkoutSet(setNumber: newSetNumber, weightsAndReps: copiedWeightsAndReps))
    }

    private func deleteSet(_ set: WorkoutSet) {
        HapticManager.shared.trigger(.light)
        exerciseEntry.sets.removeAll { $0.id == set.id }
        // Renumber remaining sets
        exerciseEntry.sets = exerciseEntry.sets.enumerated().map { index, existingSet in
            WorkoutSet(
                setNumber: index + 1,
                weightsAndReps: existingSet.weightsAndReps
            )
        }
    }

    private func formatSet(_ set: WorkoutSet) -> String {
        let weightReps = set.weightsAndReps.map { wr in
            if wr.weight == 0 && wr.reps == 0 {
                return "—"
            }
            // Preserve decimals if present, otherwise show as integer
            let weightString = wr.weight.truncatingRemainder(dividingBy: 1) == 0
                ? String(format: "%.0f", wr.weight)
                : String(format: "%.1f", wr.weight)
            return "\(weightString)kg × \(wr.reps)"
        }.joined(separator: " → ")
        return weightReps
    }
}

// Individual set entry row with vertical drop sets
struct SetEntryRow: View {
    @Binding var set: WorkoutSet

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            // Main set and drop sets
            ForEach(set.weightsAndReps.indices, id: \.self) { index in
                HStack(spacing: 8) {
                    // Set label - only show for first entry, indent for drops
                    if index == 0 {
                        Text("Set \(set.setNumber)")
                            .font(.subheadline.bold())
                            .foregroundStyle(.accent)
                            .frame(width: 50, alignment: .leading)
                    } else {
                        HStack(spacing: 4) {
                            Rectangle()
                                .fill(.accent.opacity(0.3))
                                .frame(width: 2, height: 20)
                            Image(systemName: "arrow.turn.down.right")
                                .font(.caption2)
                                .foregroundStyle(.accent.opacity(0.6))
                        }
                        .frame(width: 50, alignment: .leading)
                    }

                    // Weight field
                    TextField("kg", text: Binding(
                        get: { set.weightsAndReps[index].weight == 0 ? "" : "\(set.weightsAndReps[index].weight)" },
                        set: { newValue in
                            set.weightsAndReps[index].weight = Double(newValue) ?? 0
                        }
                    ))
                    .keyboardType(.decimalPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 60)

                    Image(systemName: "xmark")
                        .font(.caption2)
                        .foregroundStyle(.secondary)

                    // Reps field
                    TextField("reps", text: Binding(
                        get: { set.weightsAndReps[index].reps == 0 ? "" : "\(set.weightsAndReps[index].reps)" },
                        set: { newValue in
                            set.weightsAndReps[index].reps = Int(newValue) ?? 0
                        }
                    ))
                    .keyboardType(.numberPad)
                    .textFieldStyle(.roundedBorder)
                    .frame(width: 50)

                    // Delete drop set button (only for drops, not main set)
                    if set.weightsAndReps.count > 1 && index > 0 {
                        Button {
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                removeWeightRep(set.weightsAndReps[index])
                            }
                        } label: {
                            Image(systemName: "minus.circle.fill")
                                .foregroundStyle(.red)
                                .symbolRenderingMode(.hierarchical)
                        }
                        .buttonStyle(.borderless)
                    }

                    Spacer()
                }
            }

            // Add Drop Set Button
            Button {
                addDropSet()
            } label: {
                HStack(spacing: 4) {
                    Image(systemName: "plus.circle")
                        .symbolRenderingMode(.hierarchical)
                    Text("Add Drop")
                        .font(.caption)
                }
                .foregroundStyle(.accent)
            }
            .buttonStyle(.borderless)
            .padding(.leading, 50)
        }
    }

    private func addDropSet() {
        HapticManager.shared.trigger(.light)
        set.weightsAndReps.append(WeightRep())
    }

    private func removeWeightRep(_ wr: WeightRep) {
        // Don't allow deleting the last weight/rep entry
        guard set.weightsAndReps.count > 1 else { return }
        HapticManager.shared.trigger(.light)
        set.weightsAndReps.removeAll { $0.id == wr.id }
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
                ExerciseFormView(onExerciseCreated: { newExercise in
                    // Auto-select the newly created exercise
                    let entry = WorkoutExerciseEntry(
                        exerciseID: newExercise.id,
                        exerciseName: newExercise.name,
                        isUnilateral: newExercise.tags.contains("unilateral")
                    )
                    selectedExercises.append(entry)
                    HapticManager.shared.trigger(.success)
                })
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
                exerciseName: exercise.name,
                isUnilateral: exercise.tags.contains("unilateral")
            )
            selectedExercises.append(entry)
        }
    }
}

// Exercise info sheet
struct ExerciseInfoSheet: View {
    let exercise: Exercise
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            List {
                // Description
                if let description = exercise.exerciseDescription, !description.isEmpty {
                    Section {
                        Text(description)
                            .font(.body)
                    } header: {
                        Label("Description", systemImage: "text.alignleft")
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                // Muscle Group
                Section {
                    HStack {
                        if let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                            Label(exercise.muscleGroup, systemImage: group.icon)
                        } else {
                            Text(exercise.muscleGroup)
                        }
                    }
                } header: {
                    Label("Muscle Group", systemImage: "figure.strengthtraining.traditional")
                        .symbolRenderingMode(.hierarchical)
                }

                // Tags
                if !exercise.tags.isEmpty {
                    Section {
                        FlowLayout(spacing: 8) {
                            ForEach(exercise.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption)
                                    .padding(.horizontal, 10)
                                    .padding(.vertical, 6)
                                    .background(.regularMaterial, in: Capsule())
                            }
                        }
                        .padding(.vertical, 4)
                    } header: {
                        Label("Tags", systemImage: "tag")
                            .symbolRenderingMode(.hierarchical)
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(exercise.name)
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

// Reorder modal for workout exercises
struct WorkoutExerciseReorderView: View {
    @Environment(\.dismiss) private var dismiss
    @Binding var exercises: [WorkoutExerciseEntry]
    @State private var workingCopy: [WorkoutExerciseEntry]

    init(exercises: Binding<[WorkoutExerciseEntry]>) {
        self._exercises = exercises
        self._workingCopy = State(initialValue: exercises.wrappedValue)
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(workingCopy) { exercise in
                    Text(exercise.exerciseName)
                }
                .onMove(perform: moveExercise)
            }
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Reorder Exercises")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        // Discard changes - don't update the binding
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        // Save changes - update the binding
                        exercises = workingCopy
                        dismiss()
                    }
                }
            }
        }
    }

    private func moveExercise(from source: IndexSet, to destination: Int) {
        workingCopy.move(fromOffsets: source, toOffset: destination)
        HapticManager.shared.trigger(.light)
    }
}

#Preview {
    WorkoutLoggingView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}