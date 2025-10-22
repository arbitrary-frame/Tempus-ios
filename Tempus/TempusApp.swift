//
//  TempusApp.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

enum PostOnboardingAction {
    case none
    case browsePresets
    case createWorkout
}

class AppDelegate: NSObject, UIApplicationDelegate {
    static var orientationLock = UIInterfaceOrientationMask.all

    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return AppDelegate.orientationLock
    }
}

@main
struct TempusApp: App {
    @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @StateObject private var themeManager = ThemeManager()
    @AppStorage("hasCompletedOnboarding") private var hasCompletedOnboarding: Bool = false
    @State private var selectedTab: Int = 0
    @State private var postOnboardingAction: PostOnboardingAction = .none

    var sharedModelContainer: ModelContainer = {
        // CRITICAL: Migrate database from old location to App Group FIRST
        DatabaseMigration.migrateToAppGroupIfNeeded()

        let schema = Schema([
            Exercise.self,
            WorkoutRoutine.self,
            WorkoutEntry.self
        ])

        // Conditional database path AND App Group based on build configuration
        #if DEVELOPMENT
        let databaseName = "dev-database.store"
        let appGroupIdentifier = "group.tempus.dev"
        print("🧪 [DEVELOPMENT] Using dev database: \(databaseName)")
        print("🧪 [DEVELOPMENT] Using dev App Group: \(appGroupIdentifier)")
        #else
        let databaseName = "production-database.store"
        let appGroupIdentifier = "group.tempus.prod"
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

            // Migrate existing routines to use exerciseIDs for order preservation
            Task { @MainActor in
                await migrateRoutineExercises(container: container)
            }

            return container
        } catch {
            fatalError("Could not create ModelContainer: \(error)")
        }
    }()

    var body: some Scene {
        WindowGroup {
            if hasCompletedOnboarding {
                ContentView(selectedTab: $selectedTab, postOnboardingAction: $postOnboardingAction)
                    .environmentObject(themeManager)
                    .onOpenURL { url in
                        handleDeepLink(url)
                    }
            } else {
                OnboardingView(postOnboardingAction: $postOnboardingAction)
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

    /// One-time migration: Populate exerciseIDs from exercises relationship for existing routines
    /// This preserves exercise order going forward without breaking existing data
    @MainActor
    private static func migrateRoutineExercises(container: ModelContainer) async {
        let context = ModelContext(container)

        do {
            let routines = try context.fetch(FetchDescriptor<WorkoutRoutine>())

            var migratedCount = 0
            for routine in routines {
                // Only migrate if exerciseIDs is empty but exercises exist
                if routine.exerciseIDs.isEmpty && !routine.exercises.isEmpty {
                    routine.exerciseIDs = routine.exercises.map { $0.id }
                    migratedCount += 1
                }
            }

            if migratedCount > 0 {
                try context.save()
                print("✅ Migrated \(migratedCount) routine(s) to use exerciseIDs for order preservation")
            }
        } catch {
            print("⚠️ Routine migration error: \(error)")
        }
    }
}
