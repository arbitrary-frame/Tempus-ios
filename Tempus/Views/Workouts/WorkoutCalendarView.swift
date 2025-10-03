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
    @Query(sort: \WorkoutRoutine.name) private var routines: [WorkoutRoutine]
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3

    @State private var selectedMonth: Date = Date()
    @State private var selectedWeek: Date = Date() // Start of selected week
    @State private var selectedWorkout: WorkoutEntry?
    @State private var workoutsForSelectedDay: [WorkoutEntry] = []
    @State private var showingWorkoutPicker = false
    @State private var selectedDate: Date?  // Date user tapped to log workout
    @State private var dateToLog: Date?  // Date confirmed for logging
    @State private var showingLogWorkout = false
    @State private var routineToStart: WorkoutRoutine?  // Routine to start from calendar

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

    // Get week start for initialization
    private var currentWeekStart: Date {
        calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: selectedWeek)) ?? selectedWeek
    }

    // Workouts for selected week
    private var workoutsForSelectedWeek: [WorkoutEntry] {
        guard let weekEnd = calendar.date(byAdding: .day, value: 7, to: currentWeekStart) else {
            return []
        }
        return workouts.filter { $0.workoutDate >= currentWeekStart && $0.workoutDate < weekEnd }
            .sorted { $0.workoutDate > $1.workoutDate }
    }

    // Weekly statistics
    private var weeklyWorkoutCount: Int {
        workoutsForSelectedWeek.count
    }

    private var weeklyExerciseCount: Int {
        workoutsForSelectedWeek.reduce(0) { $0 + $1.exercisesData.count }
    }

    private var weeklyTotalWeight: Double {
        var totalWeight: Double = 0
        for workout in workoutsForSelectedWeek {
            for exercise in workout.exercisesData {
                for set in exercise.sets {
                    for weightRep in set.weightsAndReps {
                        totalWeight += weightRep.weight * Double(weightRep.reps)
                    }
                }
            }
        }
        return totalWeight
    }

    private var weeklyProgress: Double {
        guard weeklyWorkoutGoal > 0 else { return 0 }
        return min(Double(weeklyWorkoutCount) / Double(weeklyWorkoutGoal), 1.0)
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

                    // Calendar grid and weekly content
                    ScrollView(showsIndicators: false) {
                        VStack(spacing: 20) {
                            // Calendar grid
                            LazyVGrid(columns: columns, spacing: 6) {
                                ForEach(daysInMonth, id: \.self) { date in
                                    DayCell(
                                        date: date,
                                        workouts: workoutsByDate[date] ?? [],
                                        isInCurrentMonth: calendar.isDate(date, equalTo: selectedMonth, toGranularity: .month),
                                        isToday: calendar.isDateInToday(date),
                                        isInSelectedWeek: isDateInSelectedWeek(date)
                                    )
                                    .onTapGesture {
                                        handleDayTap(date: date)
                                    }
                                }
                            }
                            .padding(.horizontal, 20)

                            // Weekly statistics summary with navigation
                            VStack(spacing: 0) {
                                // Week navigation header
                                HStack {
                                    Button {
                                        HapticManager.shared.trigger(.light)
                                        changeWeek(by: -1)
                                    } label: {
                                        Image(systemName: "chevron.left.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.primary)
                                    }

                                    Spacer()

                                    Text(weekRangeString)
                                        .font(.subheadline.bold())
                                        .foregroundStyle(.primary)

                                    Spacer()

                                    Button {
                                        HapticManager.shared.trigger(.light)
                                        changeWeek(by: 1)
                                    } label: {
                                        Image(systemName: "chevron.right.circle.fill")
                                            .font(.title3)
                                            .symbolRenderingMode(.hierarchical)
                                            .foregroundStyle(.primary)
                                    }
                                }
                                .padding(.horizontal, 20)
                                .padding(.bottom, 12)

                                WeeklyStatsSummary(
                                    workoutCount: weeklyWorkoutCount,
                                    exerciseCount: weeklyExerciseCount,
                                    totalWeight: weeklyTotalWeight,
                                    weeklyGoal: weeklyWorkoutGoal,
                                    progress: weeklyProgress
                                )
                                .padding(.horizontal, 20)
                            }

                            // Workouts for selected week
                            if !workoutsForSelectedWeek.isEmpty {
                                VStack(alignment: .leading, spacing: 12) {
                                    Text("Workouts")
                                        .font(.headline)
                                        .foregroundStyle(.secondary)
                                        .padding(.horizontal, 20)

                                    ForEach(workoutsForSelectedWeek) { workout in
                                        WorkoutCardView(workout: workout)
                                            .padding(.horizontal, 20)
                                            .onTapGesture {
                                                selectedWorkout = workout
                                            }
                                    }
                                }
                            }
                        }
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
            .confirmationDialog("", isPresented: Binding(
                get: { selectedDate != nil },
                set: { if !$0 { selectedDate = nil } }
            ), titleVisibility: .hidden) {
                Button("Quick Log") {
                    dateToLog = selectedDate
                    selectedDate = nil
                    showingLogWorkout = true
                }

                if !routines.isEmpty {
                    ForEach(routines) { routine in
                        Button(routine.name) {
                            dateToLog = selectedDate
                            selectedDate = nil
                            routineToStart = routine
                        }
                    }
                }

                Button("Cancel", role: .cancel) {
                    selectedDate = nil
                }
            }
            .fullScreenCover(isPresented: $showingLogWorkout, onDismiss: {
                dateToLog = nil
            }) {
                if let date = dateToLog {
                    WorkoutLoggingView(date: date)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
            .fullScreenCover(item: $routineToStart, onDismiss: {
                dateToLog = nil
            }) { routine in
                if let date = dateToLog {
                    WorkoutLoggingView(date: date, routine: routine)
                        .transition(.move(edge: .bottom).combined(with: .opacity))
                }
            }
        }
    }

    private var selectedDateString: String {
        guard let date = selectedDate else { return "" }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        return formatter.string(from: date)
    }

    private var monthYearString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "MMMM yyyy"
        return formatter.string(from: selectedMonth)
    }

    private var weekRangeString: String {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "d MMM"

        guard let weekEnd = calendar.date(byAdding: .day, value: 6, to: currentWeekStart) else {
            return ""
        }

        let startString = formatter.string(from: currentWeekStart)
        let endString = formatter.string(from: weekEnd)
        return "Week: \(startString) - \(endString)"
    }

    private func changeMonth(by value: Int) {
        if let newMonth = calendar.date(byAdding: .month, value: value, to: selectedMonth) {
            selectedMonth = newMonth
        }
    }

    private func changeWeek(by value: Int) {
        if let newWeek = calendar.date(byAdding: .weekOfYear, value: value, to: selectedWeek) {
            selectedWeek = newWeek

            // Update selected month if week is in a different month
            if !calendar.isDate(newWeek, equalTo: selectedMonth, toGranularity: .month) {
                selectedMonth = newWeek
            }
        }
    }

    private func handleDayTap(date: Date) {
        HapticManager.shared.trigger(.light)

        // Update selected week to the week containing this date
        if let weekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) {
            selectedWeek = weekStart
        }

        // Store selected date and show log workout prompt
        selectedDate = date
    }

    private func isDateInSelectedWeek(_ date: Date) -> Bool {
        guard let dateWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)) else {
            return false
        }
        return dateWeekStart == currentWeekStart
    }
}

// Weekly Statistics Summary Card
struct WeeklyStatsSummary: View {
    let workoutCount: Int
    let exerciseCount: Int
    let totalWeight: Double
    let weeklyGoal: Int
    let progress: Double

    private var formattedWeight: String {
        let kg = Int(totalWeight)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }

    var body: some View {
        VStack(spacing: 12) {
            // Stats grid (reusing same design as workout list)
            HStack(spacing: 8) {
                // Progress Ring
                StatBubble(
                    value: "\(workoutCount)/\(weeklyGoal)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional"
                )
                .frame(maxWidth: .infinity)

                // Exercises
                StatBubble(
                    value: "\(exerciseCount)",
                    label: "Exercises",
                    icon: "list.bullet.clipboard"
                )
                .frame(maxWidth: .infinity)

                // Weight
                StatBubble(
                    value: formattedWeight,
                    label: "kg",
                    icon: "dumbbell.fill",
                    accentColor: .orange
                )
                .frame(maxWidth: .infinity)
            }
        }
        .padding()
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
        .shadow(color: .black.opacity(0.08), radius: 6, x: 0, y: 3)
    }
}

// Individual day cell
struct DayCell: View {
    let date: Date
    let workouts: [WorkoutEntry]
    let isInCurrentMonth: Bool
    let isToday: Bool
    let isInSelectedWeek: Bool

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
                // Selected week background
                if isInSelectedWeek && isInCurrentMonth {
                    RoundedRectangle(cornerRadius: 10)
                        .fill(Color.accentColor.opacity(0.1))
                }

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