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
    @Binding var selectedTab: Int
    @Binding var postOnboardingAction: PostOnboardingAction
    @State private var showPresetBrowser = false
    @State private var showWorkoutLogger = false

    var body: some View {
        TabView(selection: $selectedTab) {
            WorkoutsListView(showWorkoutLoggerFromOnboarding: $showWorkoutLogger)
                .tabItem {
                    Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                }
                .tag(0)

            WorkoutRoutinesListView()
                .tabItem {
                    Label("Routines", systemImage: "arrow.triangle.2.circlepath")
                }
                .tag(1)

            ExercisesListView(showPresetBrowserFromOnboarding: $showPresetBrowser)
                .tabItem {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                }
                .tag(2)

            AnalyticsView()
                .tabItem {
                    Label("Analytics", systemImage: "chart.line.uptrend.xyaxis")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label("Settings", systemImage: "gearshape")
                }
                .tag(4)
        }
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            handlePostOnboardingAction()
        }
    }

    private func handlePostOnboardingAction() {
        switch postOnboardingAction {
        case .browsePresets:
            selectedTab = 2 // Exercises tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showPresetBrowser = true
                postOnboardingAction = .none
            }
        case .createWorkout:
            selectedTab = 0 // Workouts tab
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                showWorkoutLogger = true
                postOnboardingAction = .none
            }
        case .none:
            break
        }
    }
}

#Preview {
    ContentView(selectedTab: .constant(0), postOnboardingAction: .constant(.none))
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}