//
//  AnalyticsView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct AnalyticsView: View {
    @Environment(\.modelContext) private var modelContext
    @Query private var workouts: [WorkoutEntry]

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Analytics Yet", systemImage: "chart.line.uptrend.xyaxis")
                    } description: {
                        Text("Log your first workout to see progress")
                    }
                } else {
                    List {
                        Section("Overview") {
                            HStack {
                                VStack(alignment: .leading) {
                                    Text("Total Workouts")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text("\(workouts.count)")
                                        .font(.title2.bold())
                                }

                                Spacer()

                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title)
                                    .foregroundStyle(.secondary)
                            }
                            .padding(.vertical, 8)
                        }

                        Section("Coming Soon") {
                            Text("Charts and progress tracking")
                                .foregroundStyle(.secondary)
                        }
                    }
                    .listStyle(.insetGrouped)
                }
            }
            .navigationTitle("Analytics")
        }
    }
}

#Preview {
    AnalyticsView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}