//
//  ExercisesListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct ExercisesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Exercise.name) private var exercises: [Exercise]
    @State private var searchText = ""
    @State private var showingCreateForm = false
    @State private var selectedExercise: Exercise?
    @State private var addButtonTapped = false

    var filteredExercises: [Exercise] {
        if searchText.isEmpty {
            return exercises.filter { !$0.isArchived }
        } else {
            return exercises.filter { !$0.isArchived && $0.name.localizedCaseInsensitiveContains(searchText) }
        }
    }

    var groupedExercises: [String: [Exercise]] {
        Dictionary(grouping: filteredExercises) { $0.muscleGroup }
    }

    var body: some View {
        NavigationStack {
            Group {
                if filteredExercises.isEmpty {
                    ContentUnavailableView {
                        Label("No Exercises Yet", systemImage: "list.bullet.clipboard")
                            .symbolRenderingMode(.multicolor)
                            .symbolEffect(.bounce, value: filteredExercises.isEmpty)
                    } description: {
                        Text("Tap + to create your first exercise")
                            .foregroundStyle(.secondary)
                    }
                } else {
                    ScrollView {
                        LazyVStack(spacing: 16, pinnedViews: [.sectionHeaders]) {
                            ForEach(groupedExercises.keys.sorted(), id: \.self) { muscleGroup in
                                Section {
                                    LazyVStack(spacing: 12) {
                                        ForEach(groupedExercises[muscleGroup]!) { exercise in
                                            ExerciseCardView(exercise: exercise)
                                                .onTapGesture {
                                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                                                        selectedExercise = exercise
                                                    }
                                                    print("DEBUG: Exercise tapped - \(exercise.name)")
                                                }
                                        }
                                    }
                                } header: {
                                    if let group = MuscleGroup(rawValue: muscleGroup) {
                                        HStack {
                                            Image(systemName: group.icon)
                                                .font(.title3)
                                                .symbolRenderingMode(.hierarchical)
                                                .foregroundStyle(.accent)

                                            Text(muscleGroup)
                                                .font(.title3.bold())
                                                .foregroundStyle(.primary)

                                            Spacer()
                                        }
                                        .padding(.horizontal)
                                        .padding(.vertical, 8)
                                        .background(.ultraThinMaterial)
                                    }
                                }
                            }
                        }
                        .padding(.top)
                    }
                }
            }
            .navigationTitle("Exercises")
            .searchable(text: $searchText, prompt: "Search exercises")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateForm = true
                        print("DEBUG: Add exercise button tapped")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                ExerciseFormView()
            }
            .sheet(item: $selectedExercise) { exercise in
                ExerciseFormView(exercise: exercise)
            }
        }
    }
}

// Liquid Glass Exercise Card
struct ExerciseCardView: View {
    let exercise: Exercise
    @State private var isPressed = false

    var body: some View {
        ZStack {
            // Liquid Glass background
            RoundedRectangle(cornerRadius: 16)
                .fill(.regularMaterial)
                .shadow(color: .black.opacity(0.08), radius: isPressed ? 2 : 6, x: 0, y: isPressed ? 1 : 3)

            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(exercise.name)
                        .font(.headline)
                        .foregroundStyle(.primary)

                    Spacer()

                    // Muscle group badge
                    if let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                        Image(systemName: group.icon)
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.accent)
                            .padding(6)
                            .background(.ultraThinMaterial, in: Circle())
                    }
                }

                if !exercise.tags.isEmpty {
                    HStack(spacing: 6) {
                        ForEach(exercise.tags.prefix(3), id: \.self) { tag in
                            Text(tag)
                                .font(.caption2)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(.ultraThinMaterial, in: Capsule())
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
            .padding(16)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
        .padding(.horizontal)
    }
}

#Preview {
    ExercisesListView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}