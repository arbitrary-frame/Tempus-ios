//
//  WorkoutTemplatesListView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutTemplatesListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutTemplate.name) private var templates: [WorkoutTemplate]
    @State private var showingCreateForm = false
    @State private var selectedTemplate: WorkoutTemplate?
    @State private var templateToStart: WorkoutTemplate?

    var body: some View {
        NavigationStack {
            Group {
                if templates.isEmpty {
                    ContentUnavailableView {
                        Label("No Templates Yet", systemImage: "doc.text")
                    } description: {
                        Text("Create templates from your workouts to quickly start familiar routines")
                    }
                } else {
                    List {
                        ForEach(templates) { template in
                            Button {
                                selectedTemplate = template
                                print("DEBUG: Template tapped - \(template.name)")
                            } label: {
                                TemplateRowView(template: template)
                            }
                            .buttonStyle(.plain)
                            .listRowBackground(
                                RoundedRectangle(cornerRadius: 10)
                                    .fill(.ultraThinMaterial)
                                    .padding(.vertical, 2)
                            )
                            .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                                Button(role: .destructive) {
                                    deleteTemplate(template)
                                } label: {
                                    Label("Delete", systemImage: "trash")
                                }

                                Button {
                                    templateToStart = template
                                    print("DEBUG: Starting workout from template - \(template.name)")
                                } label: {
                                    Label("Start", systemImage: "play.fill")
                                }
                                .tint(.accent)
                            }
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Templates")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingCreateForm = true
                        print("DEBUG: Add template button tapped")
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingCreateForm) {
                WorkoutTemplateFormView()
            }
            .sheet(item: $selectedTemplate) { template in
                WorkoutTemplateFormView(template: template)
            }
            .fullScreenCover(item: $templateToStart) { template in
                WorkoutLoggingView(template: template)
            }
        }
    }

    private func deleteTemplate(_ template: WorkoutTemplate) {
        withAnimation {
            modelContext.delete(template)
            print("DEBUG: Template deleted - \(template.name)")
        }
    }
}

struct TemplateRowView: View {
    let template: WorkoutTemplate

    var body: some View {
        HStack(spacing: 12) {
            // Show emoji icon or default icon
            if let emoji = template.emoji, !emoji.isEmpty {
                Text(emoji)
                    .font(.title2)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            } else {
                Image(systemName: "doc.text")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .frame(width: 44, height: 44)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(template.name)
                    .font(.headline)

                HStack {
                    Image(systemName: "figure.mixed.cardio")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                    Text("\(template.exercises.count) exercises")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }

                if let description = template.templateDescription, !description.isEmpty {
                    Text(description)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .lineLimit(2)
                }
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    WorkoutTemplatesListView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}