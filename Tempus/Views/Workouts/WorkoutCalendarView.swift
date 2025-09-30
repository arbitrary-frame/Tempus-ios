//
//  WorkoutCalendarView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct WorkoutCalendarView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]

    @State private var selectedMonth: Date = Date()
    @State private var selectedWorkout: WorkoutEntry?
    @State private var workoutsForSelectedDay: [WorkoutEntry] = []
    @State private var showingWorkoutPicker = false

    private let calendar = Calendar.current
    private let columns = Array(repeating: GridItem(.flexible(), spacing: 4), count: 7)

    // Group workouts by calendar day
    private var workoutsByDate: [Date: [WorkoutEntry]] {
        var grouped: [Date: [WorkoutEntry]] = [:]
        for workout in workouts {
            let day = calendar.startOfDay(for: workout.workoutDate)
            grouped[day, default: []].append(workout)
        }
        return grouped
    }

    // Get days to display for current month
    private var daysInMonth: [Date] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: selectedMonth),
              let monthFirstWeek = calendar.dateInterval(of: .weekOfMonth, for: monthInterval.start) else {
            return []
        }

        var days: [Date] = []
        var date = monthFirstWeek.start

        // Generate 6 weeks of days (42 days) to cover all cases
        for _ in 0..<42 {
            days.append(date)
            date = calendar.date(byAdding: .day, value: 1, to: date)!
        }

        return days
    }

    var body: some View {
        NavigationStack {
            ZStack {
                // Liquid Glass background
                Color(uiColor: .systemGroupedBackground)
                    .ignoresSafeArea()

                VStack(spacing: 0) {
                    // Month navigation header
                    HStack {
                        Button {
                            HapticManager.shared.trigger(.light)
                            changeMonth(by: -1)
                        } label: {
                            Image(systemName: "chevron.left.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }

                        Spacer()

                        Text(monthYearString)
                            .font(.title2.bold())
                            .foregroundStyle(.primary)

                        Spacer()

                        Button {
                            HapticManager.shared.trigger(.light)
                            changeMonth(by: 1)
                        } label: {
                            Image(systemName: "chevron.right.circle.fill")
                                .font(.title2)
                                .symbolRenderingMode(.hierarchical)
                                .foregroundStyle(.primary)
                        }
                    }
                    .padding()

                    // Day of week headers
                    LazyVGrid(columns: columns, spacing: 4) {
                        ForEach(["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"], id: \.self) { day in
                            Text(day)
                                .font(.caption2.bold())
                                .foregroundStyle(.secondary)
                                .frame(maxWidth: .infinity)
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)

                    // Calendar grid
                    ScrollView(showsIndicators: false) {
                        LazyVGrid(columns: columns, spacing: 6) {
                            ForEach(daysInMonth, id: \.self) { date in
                                DayCell(
                                    date: date,
                                    workouts: workoutsByDate[date] ?? [],
                                    isInCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                                    isToday: calendar.isDateInToday(date)
                                )
                                .onTapGesture {
                                    handleDayTap(date: date)
                                }
                            }
                        }
                        .padding(.horizontal, 20)
                        .padding(.bottom, 20)
                    }
                }
            }
            .navigationTitle("Workout Calendar")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    Button("Today") {
                        HapticManager.shared.trigger(.light)
                        selectedMonth = Date()
                    }
                    .font(.body)
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        dismiss()
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .symbolRenderingMode(.hierarchical)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .sheet(item: $selectedWorkout) { workout in
                WorkoutEditView(workout: workout)
            }
            .sheet(isPresented: $showingWorkoutPicker) {
                WorkoutPickerSheet(workouts: workoutsForSelectedDay, selectedWorkout: $selectedWorkout)
            }
        }
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func handleDayTap(date: Date) {
        let dayWorkouts = workoutsByDate[date] ?? []
        guard !dayWorkouts.isEmpty else { return }

        HapticManager.shared.trigger(.light)

        if dayWorkouts.count == 1 {
            selectedWorkout = dayWorkouts[0]
        } else {
            workoutsForSelectedDay = dayWorkouts
            showingWorkoutPicker = true
        }
    }
}

// Individual day cell
struct DayCell: View {
    let date: Date
    let workouts: [WorkoutEntry]
    let isInCurrentMonth: Bool
    let isToday: Bool

    private let calendar = Calendar.current

    private var dayNumber: String {
        let day = calendar.component(.day, from: date)
        return "\(day)"
    }

    private var workoutEmojis: [String] {
        workouts.compactMap { workout in
            if let emoji = workout.routine?.emoji, !emoji.isEmpty {
                return emoji
            }
            return "🏋️"  // Default emoji for workouts without routine
        }
    }

    var body: some View {
        VStack(spacing: 6) {
            Text(dayNumber)
                .font(.caption)
                .fontWeight(isToday ? .bold : .regular)
                .foregroundStyle(isInCurrentMonth ? .primary : .tertiary)

            if !workouts.isEmpty {
                HStack(spacing: 2) {
                    ForEach(0..<min(workoutEmojis.count, 3), id: \.self) { index in
                        Text(workoutEmojis[index])
                            .font(.system(size: 14))
                    }

                    if workoutEmojis.count > 3 {
                        Text("+\(workoutEmojis.count - 3)")
                            .font(.system(size: 9).bold())
                            .foregroundStyle(.orange)
                    }
                }
            } else {
                Spacer()
                    .frame(height: 18)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 54)
        .background(
            ZStack {
                if !workouts.isEmpty {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.08), radius: 4, x: 0, y: 2)
                }

                if isToday {
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(Color.orange, lineWidth: 2.5)
                }
            }
        )
    }
}

// Workout picker sheet for multiple workouts on same day
struct WorkoutPickerSheet: View {
    @Environment(\.dismiss) private var dismiss
    let workouts: [WorkoutEntry]
    @Binding var selectedWorkout: WorkoutEntry?

    var body: some View {
        NavigationStack {
            List(workouts) { workout in
                Button {
                    selectedWorkout = workout
                    dismiss()
                } label: {
                    VStack(alignment: .leading, spacing: 4) {
                        HStack {
                            if let emoji = workout.routine?.emoji, !emoji.isEmpty {
                                Text(emoji)
                                    .font(.title2)
                            } else {
                                Image(systemName: "figure.strengthtraining.traditional")
                                    .font(.title3)
                                    .foregroundStyle(.accent)
                            }

                            Text(workout.workoutName)
                                .font(.headline)

                            Spacer()
                        }

                        Text("\(workout.exercisesData.count) exercises")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.vertical, 4)
                }
                .buttonStyle(.plain)
            }
            .navigationTitle("Select Workout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

#Preview {
    WorkoutCalendarView()
        .modelContainer(for: [WorkoutEntry.self, Exercise.self, WorkoutRoutine.self])
}