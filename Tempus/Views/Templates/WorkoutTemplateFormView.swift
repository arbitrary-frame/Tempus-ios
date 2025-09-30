//
//  WorkoutTemplateFormView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutTemplateFormView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]

    @State private var name: String
    @State private var templateDescription: String
    @State private var emoji: String
    @State private var selectedExercises: [Exercise]
    @State private var showingExercisePicker = false

    let isEditing: Bool
    let templateToEdit: WorkoutTemplate?

    init(template: WorkoutTemplate? = nil) {
        self.isEditing = template != nil
        self.templateToEdit = template

        if let template = template {
            _name = State(initialValue: template.name)
            _templateDescription = State(initialValue: template.templateDescription ?? "")
            _emoji = State(initialValue: template.emoji ?? "")
            _selectedExercises = State(initialValue: template.exercises)
        } else {
            _name = State(initialValue: "")
            _templateDescription = State(initialValue: "")
            _emoji = State(initialValue: "")
            _selectedExercises = State(initialValue: [])
        }
    }

    var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && !selectedExercises.isEmpty
    }

    var body: some View {
        NavigationStack {
            List {
                Section("Template Details") {
                    HStack(spacing: 12) {
                        EmojiIconPicker(selectedEmoji: Binding(
                            get: { emoji.isEmpty ? nil : emoji },
                            set: { emoji = $0 ?? "" }
                        ))

                        TextField("Template Name", text: $name)
                            .autocorrectionDisabled()
                    }

                    TextField("Description (optional)", text: $templateDescription, axis: .vertical)
                        .lineLimit(3...6)
                }

                Section {
                    if selectedExercises.isEmpty {
                        Text("No exercises added")
                            .foregroundStyle(.secondary)
                            .font(.caption)
                    } else {
                        ForEach(selectedExercises) { exercise in
                            HStack {
                                if let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                                    Image(systemName: group.icon)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Text(exercise.name)
                                Spacer()
                                Button(role: .destructive) {
                                    removeExercise(exercise)
                                } label: {
                                    Image(systemName: "minus.circle.fill")
                                        .foregroundStyle(.red)
                                }
                                .buttonStyle(.borderless)
                            }
                        }
                    }

                    Button {
                        showingExercisePicker = true
                    } label: {
                        Label("Add Exercises", systemImage: "plus.circle.fill")
                    }
                } header: {
                    Text("Exercises")
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(isEditing ? "Edit Template" : "New Template")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        print("DEBUG: Template form cancelled")
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(isEditing ? "Save" : "Create") {
                        saveTemplate()
                    }
                    .disabled(!isValid)
                }
            }
            .sheet(isPresented: $showingExercisePicker) {
                TemplateExercisePickerView(selectedExercises: $selectedExercises)
            }
        }
    }

    private func removeExercise(_ exercise: Exercise) {
        selectedExercises.removeAll { $0.id == exercise.id }
        print("DEBUG: Removed exercise from template - \(exercise.name)")
    }

    private func saveTemplate() {
        let trimmedName = name.trimmingCharacters(in: .whitespaces)
        let trimmedEmoji = emoji.trimmingCharacters(in: .whitespaces)

        if isEditing, let template = templateToEdit {
            // Update existing template
            template.name = trimmedName
            template.templateDescription = templateDescription.isEmpty ? nil : templateDescription
            template.emoji = trimmedEmoji.isEmpty ? nil : trimmedEmoji
            template.exercises = selectedExercises
            template.updatedAt = Date()
            print("DEBUG: Template updated - \(trimmedName)")
        } else {
            // Create new template
            let newTemplate = WorkoutTemplate(
                name: trimmedName,
                templateDescription: templateDescription.isEmpty ? nil : templateDescription,
                emoji: trimmedEmoji.isEmpty ? nil : trimmedEmoji,
                exercises: selectedExercises
            )
            modelContext.insert(newTemplate)
            print("DEBUG: Template created - \(trimmedName)")
        }

        dismiss()
    }
}

// Exercise picker for templates
struct TemplateExercisePickerView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Exercise.name) private var allExercises: [Exercise]
    @Binding var selectedExercises: [Exercise]
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
                                toggleExercise(exercise)
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
        selectedExercises.contains { $0.id == exercise.id }
    }

    private func toggleExercise(_ exercise: Exercise) {
        if isSelected(exercise) {
            selectedExercises.removeAll { $0.id == exercise.id }
            print("DEBUG: Removed \(exercise.name) from template")
        } else {
            selectedExercises.append(exercise)
            print("DEBUG: Added \(exercise.name) to template")
        }
    }
}

#Preview {
    WorkoutTemplateFormView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}