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
                    ScrollView {
                        LazyVStack(spacing: 16) {
                            // Statistics Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.ultraThinMaterial)
                                    .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)

                                VStack(spacing: 16) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text("Total Workouts")
                                                .font(.caption)
                                                .foregroundStyle(Color.tempusTextSecondary)
                                            Text("\(workouts.count)")
                                                .font(.system(size: 48, weight: .bold))
                                                .foregroundStyle(Color.tempusTeal)
                                        }

                                        Spacer()

                                        Image(systemName: "figure.strengthtraining.traditional")
                                            .font(.system(size: 48))
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(Color.tempusTeal)
                                    }
                                }
                                .padding(24)
                            }
                            .padding(.horizontal)

                            // Coming Soon Card
                            ZStack {
                                RoundedRectangle(cornerRadius: 20)
                                    .fill(.regularMaterial)
                                    .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)

                                VStack(spacing: 12) {
                                    Image(systemName: "chart.xyaxis.line")
                                        .font(.system(size: 36))
                                        .foregroundStyle(.secondary)

                                    Text("Coming Soon")
                                        .font(.headline)

                                    Text("Charts and progress tracking")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .padding(32)
                            }
                            .padding(.horizontal)
                        }
                        .padding(.top)
                    }
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