//
//  TempusApp.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

@main
struct TempusApp: App {
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @AppStorage("isTestMode") private var isTestMode: Bool = false
    @State private var selectedTab: Int = 0
    @State private var modelContainer: ModelContainer

    init() {
        // Initialize model container based on test mode
        let isTest = UserDefaults.standard.bool(forKey: "isTestMode")
        _modelContainer = State(initialValue: Self.createModelContainer(isTest: isTest))
    }

    static func createModelContainer(isTest: Bool) -> ModelContainer {
        let schema = Schema([
            Exercise.self,
            WorkoutRoutine.self,
            WorkoutEntry.self
        ])

        // Create custom URL for the database file
        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let databaseName = isTest ? "test-database.store" : "production-database.store"
        let containerURL = appSupportURL.appendingPathComponent(databaseName)

        // Create directory if it doesn't exist
        try? FileManager.default.createDirectory(at: appSupportURL, withIntermediateDirectories: true)

        let modelConfiguration = ModelConfiguration(
            url: containerURL
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("📦 [\(isTest ? "TEST" : "PROD")] ModelContainer created at: \(containerURL.path)")

            // Print current workout count for debugging
            let context = container.mainContext
            let descriptor = FetchDescriptor<WorkoutEntry>()
            if let count = try? context.fetchCount(descriptor) {
                print("📊 [\(isTest ? "TEST" : "PROD")] Current workouts in database: \(count)")
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(selectedTab: $selectedTab)
                    .environmentObject(themeManager)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
                    .onChange(of: isTestMode) { oldValue, newValue in
                        // Recreate container when mode changes
                        modelContainer = Self.createModelContainer(isTest: newValue)
                    }
                    .id(isTestMode) // Force view rebuild when switching modes
            } else {
                OnboardingView()
                    .environmentObject(themeManager)
            }
        }
        .modelContainer(modelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tempus" else { return }

        // All widget taps go to workouts tab (index 0)
        if url.host == "workouts" {
            selectedTab = 0
        }
    }
}
