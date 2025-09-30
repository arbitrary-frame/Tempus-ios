//
//  ContentView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @State private var selectedTab = 0

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutsListView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                        .symbolRenderingMode(.hierarchical)
                }
                .tag(0)

            ExercisesListView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                        .symbolRenderingMode(.hierarchical)
                }
                .tag(1)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                        .symbolRenderingMode(.hierarchical)
                }
                .tag(2)
        }
        .preferredColorScheme(.none) // Adapts to user's system setting for Liquid Glass
    }
}

#Preview {
    ContentView()
        .modelContainer(for: [Exercise.self, WorkoutTemplate.self, WorkoutEntry.self])
}