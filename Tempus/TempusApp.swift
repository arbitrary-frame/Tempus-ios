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
        // CRITICAL: Migrate database from old location to App Group FIRST
        // forceOverwrite disabled now that data is recovered
        DatabaseMigration.migrateToAppGroupIfNeeded(forceOverwrite: false)

        let schema = Schema([
            Exercise.self,
            WorkoutRoutine.self,
            WorkoutEntry.self
        ])

        // Conditional database path AND App Group based on build configuration
        #if DEVELOPMENT
        let databaseName = "dev-database.store"
        let appGroupIdentifier = "group.tempus-ios.Tempus.dev"
        print("🧪 [DEVELOPMENT] Using dev database: \(databaseName)")
        print("🧪 [DEVELOPMENT] Using dev App Group: \(appGroupIdentifier)")
        #else
        let databaseName = "production-database.store"
        let appGroupIdentifier = "group.tempus-ios.Tempus"
        print("✅ [PRODUCTION] Using production database: \(databaseName)")
        print("✅ [PRODUCTION] Using production App Group: \(appGroupIdentifier)")
        #endif

        // CRITICAL: Use App Group container so widgets can access the same database
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupIdentifier) else {
            fatalError("App Group container '\(appGroupIdentifier)' not found. Check entitlements configuration.")
        }

        // Ensure App Group directory exists
        try? FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true)

        let databaseURL = appGroupURL.appendingPathComponent(databaseName)

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
