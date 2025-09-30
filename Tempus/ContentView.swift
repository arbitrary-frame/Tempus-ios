//
//  ContentView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        TabView {
            WorkoutsListView()
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }

            WorkoutRoutinesListView()
                .tabItem {
                    Label("Routines", systemImage: "arrow.triangle.2.circlepath")
                }

            ExercisesListView()
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                }

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}