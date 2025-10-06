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
    @State private var selectedTab: Int = 0

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            Exercise.self,
            WorkoutRoutine.self,
            WorkoutEntry.self
        ])

        // Conditional database path based on build configuration
        #if DEVELOPMENT
        let databaseName = "dev-database.store"
        print("🧪 [DEVELOPMENT] Using dev database: \(databaseName)")
        #else
        let databaseName = "production-database.store"
        print("✅ [PRODUCTION] Using production database: \(databaseName)")
        #endif

        let appSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let databaseURL = appSupportURL.appendingPathComponent(databaseName)

        let modelConfiguration = ModelConfiguration(
            url: databaseURL
        )

        do {
            let container = try ModelContainer(for: schema, configurations: [modelConfiguration])
            print("📦 Database location: \(databaseURL.path)")
            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(selectedTab: $selectedTab)
                    .environmentObject(themeManager)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView()
                    .environmentObject(themeManager)
            }
        }
        .modelContainer(sharedModelContainer)
    }

    private func handleDeepLink(_ url: URL) {
        guard url.scheme == "tempus" else { return }

        // All widget taps go to workouts tab (index 0)
        if url.host == "workouts" {
            selectedTab = 0
        }
    }
}
