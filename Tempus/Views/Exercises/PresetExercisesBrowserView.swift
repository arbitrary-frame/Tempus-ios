//
//  PresetExercisesBrowserView.swift
//  Tempus
//
//  Browser for selecting and importing preset exercises.
//

import SwiftUI
import SwiftData

struct PresetExercisesBrowserView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @State private var selectedExercises: Set<UUID> = []

    private var selectedCount: Int {
        selectedExercises.count
    }

    private var allSelected: Bool {
        selectedExercises.count == PresetExercises.all.count
    }

    var body: some View {
        NavigationStack {
            List {
                ForEach(PresetExercises.grouped, id: \.muscleGroup) { group in
                    Section {
                        ForEach(group.exercises) { preset in
                            PresetExerciseRow(
                                preset: preset,
                                isSelected: selectedExercises.contains(preset.id),
                                onToggle: { toggleSelection(preset) }
                            )
                        }
                    } header: {
                        if let muscleGroup = MuscleGroup(rawValue: group.muscleGroup) {
                            Label(group.muscleGroup, systemImage: muscleGroup.icon)
                        } else {
                            Text(group.muscleGroup)
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Preset Exercises")
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
                    ImportButton(
                        selectedCount: selectedCount,
                        onImport: { importSelectedExercises() }
                    )
                    .padding()
                    .background(.regularMaterial)
                }
            }
        }
    }

    private func toggleSelection(_ preset: PresetExercise) {
        if selectedExercises.contains(preset.id) {
            selectedExercises.remove(preset.id)
        } else {
            selectedExercises.insert(preset.id)
        }
        HapticManager.shared.trigger(.selection)
    }

    private func toggleSelectAll() {
        if allSelected {
            selectedExercises.removeAll()
        } else {
            selectedExercises = Set(PresetExercises.all.map { $0.id })
        }
        HapticManager.shared.trigger(.light)
    }

    private func importSelectedExercises() {
        let presetsToImport = PresetExercises.all.filter { selectedExercises.contains($0.id) }

        for preset in presetsToImport {
            let exercise = Exercise(
                name: preset.name,
                muscleGroup: preset.muscleGroup,
                tags: preset.tags,
                exerciseDescription: preset.description
            )
            modelContext.insert(exercise)
        }

        do {
            try modelContext.save()
            HapticManager.shared.trigger(.success)
            dismiss()
        } catch {
            print("❌ Failed to import preset exercises: \(error)")
        }
    }
}

// MARK: - Preset Exercise Row
struct PresetExerciseRow: View {
    let preset: PresetExercise
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

                // Exercise details
                VStack(alignment: .leading, spacing: 6) {
                    Text(preset.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Text(preset.description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)

                    // Tags
                    if !preset.tags.isEmpty {
                        HStack(spacing: 6) {
                            ForEach(preset.tags, id: \.self) { tag in
                                Text(tag)
                                    .font(.caption2)
                                    .padding(.horizontal, 6)
                                    .padding(.vertical, 3)
                                    .background(Color.secondary.opacity(0.2))
                                    .clipShape(Capsule())
                            }
                        }
                    }
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
struct ImportButton: View {
    let selectedCount: Int
    let onImport: () -> Void

    var body: some View {
        Button {
            onImport()
        } label: {
            HStack {
                Image(systemName: "square.and.arrow.down")
                    .symbolRenderingMode(.hierarchical)
                Text("Import \(selectedCount) Exercise\(selectedCount == 1 ? "" : "s")")
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
    PresetExercisesBrowserView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
