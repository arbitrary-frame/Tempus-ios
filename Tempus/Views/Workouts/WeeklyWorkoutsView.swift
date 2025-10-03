//
//  WeeklyWorkoutsView.swift
//  Tempus
//
//  Week-based workout view that actually works
//

import SwiftUI
import SwiftData

struct WeeklyWorkoutsView: View {
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]
    @State private var weekOffset: Int = 0  // 0 = current week, -1 = last week, etc.

    private var weekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        guard let currentWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return now
        }
        guard let offsetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: currentWeekStart) else {
            return currentWeekStart
        }
        return offsetWeek
    }

    private var weekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: weekStart)!
    }

    private var workoutsThisWeek: [WorkoutEntry] {
        allWorkouts.filter { $0.workoutDate >= weekStart && $0.workoutDate < weekEnd }
    }

    var body: some View {
        VStack {
            // Navigation
            HStack {
                Button {
                    weekOffset -= 1
                } label: {
                    Image(systemName: "chevron.left.circle.fill")
                        .font(.title2)
                }

                Spacer()

                Text(weekOffset == 0 ? "This Week" : "Week \(weekOffset)")
                    .font(.headline)

                Spacer()

                Button {
                    weekOffset += 1
                } label: {
                    Image(systemName: "chevron.right.circle.fill")
                        .font(.title2)
                }
            }
            .padding()

            // List
            List {
                ForEach(workoutsThisWeek) { workout in
                    Text(workout.workoutName)
                }
            }
            .id(weekOffset)  // Force rebuild on offset change
        }
        .navigationTitle("Workouts")
    }
}

#Preview {
    NavigationStack {
        WeeklyWorkoutsView()
            .modelContainer(for: [WorkoutEntry.self])
    }
}
