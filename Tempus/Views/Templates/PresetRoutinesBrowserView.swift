//
//  PresetRoutinesBrowserView.swift
//  Tempus
//
//  Browser for selecting and importing preset routines.
//  Intelligently creates exercises only if they don't already exist.
//

import SwiftUI
import SwiftData

struct PresetRoutinesBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @State private var selectedRoutines: Set<UUID> = []

    private var selectedCount: Int {
        selectedRoutines.count
    }

    private var allSelected: Bool {
        selectedRoutines.count == PresetRoutines.all.count
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(PresetRoutines.all) { preset in
                    PresetRoutineRow(
                        preset: preset,
                        isSelected: selectedRoutines.contains(preset.id),
                        onToggle: { toggleSelection(preset) }
                    )
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Preset Routines")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .primaryAction) {
                    Button(allSelected ? "Deselect All" : "Select All") {
                        toggleSelectAll()
                    }
                }
            }
            .safeAreaInset(edge: .bottom) {
                if selectedCount > 0 {
                    RoutineImportButton(
                        selectedCount: selectedCount,
                        onImport: { importSelectedRoutines() }
                    )
                    .padding()
                    .background(.regularMaterial)
                }
            }
        }
    }

    private func toggleSelection(_ preset: PresetRoutine) {
        if selectedRoutines.contains(preset.id) {
            selectedRoutines.remove(preset.id)
        } else {
            selectedRoutines.insert(preset.id)
        }
        HapticManager.shared.trigger(.selection)
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedRoutines.removeAll()
        } else {
            selectedRoutines = Set(PresetRoutines.all.map { $0.id })
        }
        HapticManager.shared.trigger(.light)
    }

    private func importSelectedRoutines() {
        let presetsToImport = PresetRoutines.all.filter { selectedRoutines.contains($0.id) }

        for preset in presetsToImport {
            importRoutine(preset)
        }

        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
            dismiss()
        } catch {
            print("❌ Failed to import preset routines: \(error)")
        }
    }

    /// Import a single routine, creating exercises only if they don't exist
    private func importRoutine(_ preset: PresetRoutine) {
        var routineExercises: [Exercise] = []

        for exerciseName in preset.exerciseNames {
            // Check if exercise already exists (case-insensitive)
            if let existingExercise = allExercises.first(where: {
                $0.name.lowercased() == exerciseName.lowercased()
            }) {
                // Use existing exercise
                routineExercises.append(existingExercise)
            } else {
                // Find preset exercise template and create it
                if let presetExercise = PresetExercises.all.first(where: {
                    $0.name.lowercased() == exerciseName.lowercased()
                }) {
                    let newExercise = Exercise(
                        name: presetExercise.name,
                        muscleGroup: presetExercise.muscleGroup,
                        tags: presetExercise.tags,
                        exerciseDescription: presetExercise.description
                    )
                    modelContext.insert(newExercise)
                    routineExercises.append(newExercise)
                }
            }
        }

        // Create routine with linked exercises
        let routine = WorkoutRoutine(
            name: preset.name,
            routineDescription: preset.description,
            emoji: preset.emoji,
            exercises: routineExercises
        )
        modelContext.insert(routine)
    }
}

// MARK: - Preset Routine Row
struct PresetRoutineRow: View {
    let preset: PresetRoutine
    let isSelected: Bool
    let onToggle: () -> Void

    var body: some View {
        Button {
            onToggle()
        } label: {
            HStack(alignment: .top, spacing: 12) {
                // Checkbox
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.title3)
                    .foregroundStyle(isSelected ? .accent : .secondary)
                    .symbolRenderingMode(.hierarchical)

                // Routine emoji icon
                Text(preset.emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))

                // Routine details
                VStack(alignment: .leading, spacing: 6) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Exercise count badge
                    HStack(spacing: 4) {
                        Image(systemName: "list.bullet.clipboard")
                            .font(.caption2)
                        Text("\(preset.exerciseNames.count) exercises")
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(.vertical, 4)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

// MARK: - Import Button
struct RoutineImportButton: View {
    let selectedCount: Int
    let onImport: () -> Void

    var body: some View {
        Button {
            onImport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .symbolRenderingMode(.hierarchical)
                Text("Import \(selectedCount) Routine\(selectedCount == 1 ? "" : "s")")
            }
            .font(.headline)
            .frame(maxWidth: .infinity)
            .padding()
            .background(Color.accentColor)
            .foregroundStyle(.white)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .buttonStyle(.plain)
    }
}

#Preview {
    PresetRoutinesBrowserView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
