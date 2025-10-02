//
//  ChartDataModels.swift
//  Tempus
//
//  Created by Ronak Pattani on 02/10/2025.
//

import Foundation

/// Represents a single data point for volume over time charts
struct WorkoutVolumePoint: Identifiable {
    let id: UUID
    let date: Date
    let volume: Double
    let workoutName: String

    init(date: Date, volume: Double, workoutName: String) {
        self.id = UUID()
        self.date = date
        self.volume = volume
        self.workoutName = workoutName
    }

    /// Create from WorkoutEntry
    init(from workout: WorkoutEntry) {
        self.id = UUID()
        self.date = workout.workoutDate
        self.volume = workout.totalVolume
        self.workoutName = workout.workoutName
    }
}
