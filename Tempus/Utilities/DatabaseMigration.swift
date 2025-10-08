//
//  DatabaseMigration.swift
//  Tempus
//
//  Emergency migration utility to move database from Application Support to App Group
//

import Foundation
import SwiftData

enum DatabaseMigration {

    /// Migrates database files from old Application Support location to new App Group container
    /// This is a ONE-TIME migration after the App Group container fix
    /// Set forceOverwrite to true to replace existing App Group database with old data
    static func migrateToAppGroupIfNeeded(forceOverwrite: Bool = false) {
        #if DEVELOPMENT
        let databaseName = "dev-database.store"
        print("🔄 Checking for dev database migration...")
        #else
        let databaseName = "production-database.store"
        print("🔄 Checking for production database migration...")
        #endif

        // Old location (Application Support)
        guard let oldAppSupportURL = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask).first else {
            print("⚠️ Could not find Application Support directory")
            return
        }
        let oldDatabaseURL = oldAppSupportURL.appendingPathComponent(databaseName)

        // New location (App Group container)
        guard let appGroupURL = FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: "group.tempus-ios.Tempus") else {
            print("❌ App Group container not found!")
            return
        }
        let newDatabaseURL = appGroupURL.appendingPathComponent(databaseName)

        // Check if migration is needed
        let oldExists = FileManager.default.fileExists(atPath: oldDatabaseURL.path)
        let newExists = FileManager.default.fileExists(atPath: newDatabaseURL.path)

        print("📂 Old database exists at \(oldDatabaseURL.path): \(oldExists)")
        print("📂 New database exists at \(newDatabaseURL.path): \(newExists)")

        // Check file sizes to help debug
        if oldExists {
            if let oldSize = try? FileManager.default.attributesOfItem(atPath: oldDatabaseURL.path)[.size] as? Int {
                print("📊 Old database size: \(oldSize) bytes")
            }
        }
        if newExists {
            if let newSize = try? FileManager.default.attributesOfItem(atPath: newDatabaseURL.path)[.size] as? Int {
                print("📊 New database size: \(newSize) bytes")
            }
        }

        // Migrate if old exists and (new doesn't exist OR forceOverwrite is true)
        if oldExists && (!newExists || forceOverwrite) {
            do {
                if forceOverwrite {
                    print("🚚 FORCE OVERWRITE: Replacing App Group database with old data...")
                } else {
                    print("🚚 Migrating database from Application Support to App Group...")
                }

                // Ensure App Group directory exists
                try FileManager.default.createDirectory(at: appGroupURL, withIntermediateDirectories: true)

                // If new database exists and we're forcing, remove it first
                if newExists && forceOverwrite {
                    try FileManager.default.removeItem(at: newDatabaseURL)
                    // Also remove associated files
                    let newShmURL = appGroupURL.appendingPathComponent("\(databaseName)-shm")
                    let newWalURL = appGroupURL.appendingPathComponent("\(databaseName)-wal")
                    try? FileManager.default.removeItem(at: newShmURL)
                    try? FileManager.default.removeItem(at: newWalURL)
                    print("🗑️ Removed empty App Group database")
                }

                // Copy the database file
                try FileManager.default.copyItem(at: oldDatabaseURL, to: newDatabaseURL)

                // Also copy any associated files (-shm, -wal)
                let oldShmURL = oldAppSupportURL.appendingPathComponent("\(databaseName)-shm")
                let newShmURL = appGroupURL.appendingPathComponent("\(databaseName)-shm")
                if FileManager.default.fileExists(atPath: oldShmURL.path) {
                    try? FileManager.default.copyItem(at: oldShmURL, to: newShmURL)
                }

                let oldWalURL = oldAppSupportURL.appendingPathComponent("\(databaseName)-wal")
                let newWalURL = appGroupURL.appendingPathComponent("\(databaseName)-wal")
                if FileManager.default.fileExists(atPath: oldWalURL.path) {
                    try? FileManager.default.copyItem(at: oldWalURL, to: newWalURL)
                }

                print("✅ Database migration successful!")
                print("📦 New location: \(newDatabaseURL.path)")

            } catch {
                print("❌ Migration failed: \(error)")
                print("⚠️ Please report this error to the developer")
            }
        } else if !oldExists && !newExists {
            print("ℹ️ No database found in either location - fresh install")
        } else if newExists {
            print("✅ Database already in App Group location - no migration needed")
        }
    }
}
