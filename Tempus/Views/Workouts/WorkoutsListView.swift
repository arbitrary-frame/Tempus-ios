//
//  WorkoutsListView.swift
//  Tempus
//
//  REBUILT from scratch with working week navigation pattern
//

import SwiftUI
import SwiftData
import WidgetKit

struct WorkoutsListView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var workouts: [WorkoutEntry]
    @Query(sort: \WorkoutRoutine.name) private var routines: [WorkoutRoutine]

    @State private var showingWorkoutLogging = false
    @State private var selectedWorkout: WorkoutEntry?
    @State private var showingRoutinePicker = false
    @State private var routineToStart: WorkoutRoutine?
    @State private var showingCalendar = false
    @AppStorage("userName") private var userName: String = ""
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3
    @State private var currentGreeting: String = "Workouts"

    // Week navigation state - THIS IS THE KEY
    @State private var weekOffset: Int = 0  // 0 = current week, -1 = last week, +1 = next week

    // Computed week boundaries
    private var currentWeekStart: Date {
        let calendar = Calendar.current
        let now = Date()
        guard let thisWeekStart = calendar.date(from: calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: now)) else {
            return now
        }
        guard let offsetWeek = calendar.date(byAdding: .weekOfYear, value: weekOffset, to: thisWeekStart) else {
            return thisWeekStart
        }
        return offsetWeek
    }

    private var currentWeekEnd: Date {
        Calendar.current.date(byAdding: .day, value: 7, to: currentWeekStart)!
    }

    // Filtered workouts for displayed week
    private var workoutsThisWeek: [WorkoutEntry] {
        workouts.filter { $0.workoutDate >= currentWeekStart && $0.workoutDate < currentWeekEnd }
    }

    // Week label
    private var weekLabel: String {
        if weekOffset == 0 {
            return "This Week"
        } else if weekOffset == -1 {
            return "Last Week"
        } else {
            let formatter = DateFormatter()
            formatter.locale = Locale(identifier: "en_GB")
            formatter.dateFormat = "d MMM"
            return formatter.string(from: currentWeekStart)
        }
    }

    // Stats for displayed week
    private var workoutCount: Int {
        workoutsThisWeek.count
    }

    private var exerciseCount: Int {
        workoutsThisWeek.reduce(0) { $0 + $1.exercisesData.count }
    }

    private var totalWeight: Double {
        workoutsThisWeek.reduce(0.0) { $0 + $1.totalVolume }
    }

    var body: some View {
        NavigationStack {
            Group {
                if workouts.isEmpty {
                    ContentUnavailableView {
                        Label("No Workouts Yet", systemImage: "figure.strengthtraining.traditional")
                    } description: {
                        Text("Tap + to log your first workout")
                    }
                } else {
                    VStack(spacing: 0) {
                        // Week Navigation - OUTSIDE the List!
                        HStack {
                            Button {
                                HapticManager.shared.trigger(.light)
                                weekOffset -= 1
                            } label: {
                                Image(systemName: "chevron.left.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            // Tappable label to return to this week
                            Button {
                                if weekOffset != 0 {
                                    HapticManager.shared.trigger(.light)
                                    weekOffset = 0
                                }
                            } label: {
                                Text(weekLabel)
                                    .font(.subheadline.bold())
                                    .foregroundStyle(.primary)
                            }

                            Spacer()

                            Button {
                                HapticManager.shared.trigger(.light)
                                weekOffset += 1
                            } label: {
                                Image(systemName: "chevron.right.circle.fill")
                                    .font(.title3)
                                    .symbolRenderingMode(.hierarchical)
                                    .foregroundStyle(.primary)
                            }
                            .disabled(weekOffset >= 0)  // Can't go to future weeks
                            .opacity(weekOffset >= 0 ? 0.3 : 1.0)
                        }
                        .padding()
                        .background(Color(uiColor: .systemGroupedBackground))

                        List {
                            // Statistics
                        Section {
                            SimpleStatsCard(
                                workoutCount: workoutCount,
                                exerciseCount: exerciseCount,
                                totalWeight: totalWeight,
                                weeklyGoal: weeklyWorkoutGoal
                            )
                        }
                        .listRowBackground(Color.clear)
                        .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
                        .listRowSeparator(.hidden)

                        // Workouts for this week
                        ForEach(workoutsThisWeek) { workout in
                            WorkoutCardView(workout: workout)
                                .onTapGesture {
                                    selectedWorkout = workout
                                }
                                .listRowBackground(Color.clear)
                                .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        deleteWorkout(workout)
                                    } label: {
                                        Label("Delete", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .id(weekOffset)  // Force rebuild when week changes
                    }  // Close VStack
                }
            }
            .navigationTitle(currentGreeting)
            .onAppear {
                updateGreeting()
            }
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    Button {
                        showingCalendar = true
                    } label: {
                        Image(systemName: "calendar")
                    }

                    Menu {
                        Button {
                            showingWorkoutLogging = true
                        } label: {
                            Label("Quick Log", systemImage: "plus.circle")
                        }

                        if !routines.isEmpty {
                            Divider()

                            Menu {
                                ForEach(routines) { routine in
                                    Button {
                                        routineToStart = routine
                                    } label: {
                                        Text(routine.name)
                                    }
                                }
                            } label: {
                                Label("Start from Routine", systemImage: "arrow.triangle.2.circlepath")
                            }
                        }
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .fullScreenCover(isPresented: $showingWorkoutLogging) {
                WorkoutLoggingView()
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .fullScreenCover(item: $selectedWorkout) { workout in
                WorkoutEditView(workout: workout)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .fullScreenCover(item: $routineToStart) { routine in
                WorkoutLoggingView(routine: routine)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
            .sheet(isPresented: $showingCalendar) {
                WorkoutCalendarView()
            }
        }
    }

    private func deleteWorkout(_ workout: WorkoutEntry) {
        HapticManager.shared.trigger(.warning)
        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
            modelContext.delete(workout)
        }

        do {
            try modelContext.save()
        } catch {
            print("❌ Failed to save after deletion: \(error)")
        }

        WidgetCenter.shared.reloadAllTimelines()
    }

    private func updateGreeting() {
        guard !userName.isEmpty else {
            currentGreeting = "Workouts"
            return
        }

        let hour = Calendar.current.component(.hour, from: Date())
        let messages: [String] = switch hour {
        case 5..<12:
            ["Morning \(userName)", "Let's go \(userName)", "Ready \(userName)?", "Time to train \(userName)"]
        case 12..<17:
            ["Hey \(userName)", "Let's work \(userName)", "Ready \(userName)?", "Time to move \(userName)"]
        case 17..<22:
            ["Evening \(userName)", "Let's go \(userName)", "Ready \(userName)?", "Time to push \(userName)"]
        default:
            ["Hey \(userName)", "Can't sleep \(userName)?", "Night owl \(userName)?", "Late session \(userName)?"]
        }

        currentGreeting = messages.randomElement() ?? messages[0]
    }
}

// Simplified stats card for rebuilt view
struct SimpleStatsCard: View {
    let workoutCount: Int
    let exerciseCount: Int
    let totalWeight: Double
    let weeklyGoal: Int

    private var formattedWeight: String {
        let kg = Int(totalWeight)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Text("Week Summary")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 8) {
                StatBubble(
                    value: "\(workoutCount)/\(weeklyGoal)",
                    label: "Workouts",
                    icon: "figure.strengthtraining.traditional"
                )
                .frame(maxWidth: .infinity)

                StatBubble(
                    value: "\(exerciseCount)",
                    label: "Exercises",
                    icon: "list.bullet.clipboard"
                )
                .frame(maxWidth: .infinity)

                StatBubble(
                    value: formattedWeight,
                    label: "kg",
                    icon: "dumbbell.fill",
                    accentColor: .orange
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}
struct WorkoutCardView: View {
    let workout: WorkoutEntry
    @State private var isPressed = false

    private static let calendar = Calendar.current
    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var formattedDate: String {
        let now = Date()
        let interval = now.timeIntervalSince(workout.workoutDate)

        if interval < 3600 {
            let minutes = Int(interval / 60)
            return minutes <= 1 ? "1 min ago" : "\(minutes) mins ago"
        }

        if interval < 86400 {
            let hours = Int(interval / 3600)
            return hours == 1 ? "1 hour ago" : "\(hours) hours ago"
        }

        if Self.calendar.isDateInYesterday(workout.workoutDate) {
            return "Yesterday"
        }

        return Self.dateFormatter.string(from: workout.workoutDate)
    }

    var body: some View {
        ZStack {
            // Liquid Glass background with depth
            RoundedRectangle(cornerRadius: 20)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.1), radius: isPressed ? 2 : 8, x: 0, y: isPressed ? 1 : 4)

            VStack(alignment: .leading, spacing: 12) {
                HStack {
                    // Show routine emoji if workout created from routine, otherwise default icon
                    if let emoji = workout.routine?.emoji, !emoji.isEmpty {
                        Text(emoji)
                            .font(.largeTitle)
                    } else {
                        Image(systemName: "figure.strengthtraining.traditional")
                            .font(.title)
                            .symbolRenderingMode(.multicolor)
                    }

                    Spacer()

                    // Exercise count badge
                    HStack(spacing: 4) {
                        Image(systemName: "figure.mixed.cardio")
                            .font(.caption)
                        Text("\(workout.exercisesData.count)")
                            .font(.caption.bold())
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(.regularMaterial, in: Capsule())
                }

                VStack(alignment: .leading, spacing: 4) {
                    Text(workout.workoutName)
                        .font(.title3.bold())
                        .foregroundStyle(.primary)

                    HStack {
                        Image(systemName: "clock")
                            .font(.caption)
                            .symbolRenderingMode(.hierarchical)
                        Text(formattedDate)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .padding(20)
        }
        .scaleEffect(isPressed ? 0.98 : 1.0)
        .animation(.spring(response: 0.3, dampingFraction: 0.6), value: isPressed)
        .onLongPressGesture(minimumDuration: .infinity, maximumDistance: .infinity, pressing: { pressing in
            isPressed = pressing
        }, perform: {})
    }
}

// Workout Statistics Card
struct WorkoutStatsCard: View {
    let workoutsThisWeek: Int
    let totalExercises: Int
    let totalWeight: Double
    let exercisesAbsoluteChange: Int?
    let weightChangePercentage: Double?
    @AppGroupStorage("weeklyWorkoutGoal") private var weeklyWorkoutGoal: Int = 3

    var formattedWeight: String {
        let kg = Int(totalWeight)
        if kg >= 1000 {
            return String(format: "%.1fk", Double(kg) / 1000.0)
        }
        return "\(kg)"
    }

    var progress: Double {
        guard weeklyWorkoutGoal > 0 else { return 0 }
        return min(Double(workoutsThisWeek) / Double(weeklyWorkoutGoal), 1.0)
    }

    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 4) {
                Image(systemName: "chart.bar.fill")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
                Text("This Week")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                Spacer()
            }

            HStack(spacing: 8) {
                // Circular Progress Ring
                WeeklyGoalRing(
                    workoutsCompleted: workoutsThisWeek,
                    weeklyGoal: weeklyWorkoutGoal,
                    progress: progress
                )
                .frame(maxWidth: .infinity)

                // Exercises count
                StatBubble(
                    value: "\(totalExercises)",
                    label: "Exercises",
                    icon: "list.bullet.clipboard",
                    absoluteChange: exercisesAbsoluteChange
                )
                .frame(maxWidth: .infinity)

                // Weight stat
                StatBubble(
                    value: formattedWeight,
                    label: "kg",
                    icon: "dumbbell.fill",
                    accentColor: .orange,
                    changePercentage: weightChangePercentage
                )
                .frame(maxWidth: .infinity)
            }
        }
    }
}

// Weekly Goal Progress Ring
struct WeeklyGoalRing: View {
    let workoutsCompleted: Int
    let weeklyGoal: Int
    let progress: Double
    @State private var animatedProgress: Double = 0
    @State private var showCelebration = false
    @State private var hasReachedGoal = false

    var body: some View {
        VStack(spacing: 6) {
            // Ring as icon replacement
            ZStack {
                // Background ring
                Circle()
                    .stroke(
                        Color.secondary.opacity(0.2),
                        lineWidth: 4
                    )

                // Progress ring
                Circle()
                    .trim(from: 0, to: animatedProgress)
                    .stroke(
                        workoutsCompleted >= weeklyGoal ? Color.green : Color.accentColor,
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .rotationEffect(.degrees(-90))
                    .animation(.spring(response: 0.6, dampingFraction: 0.8), value: animatedProgress)

                // Celebration confetti
                if showCelebration {
                    ForEach(0..<12, id: \.self) { index in
                        Circle()
                            .fill(Color.accentColor)
                            .frame(width: 4, height: 4)
                            .modifier(ParticleModifier(index: index))
                    }
                }
            }
            .frame(height: 50)
            .aspectRatio(1, contentMode: .fit)

            // Value below ring (like other stat bubbles)
            Text("\(workoutsCompleted)/\(weeklyGoal)")
                .font(.title2.bold())
                .foregroundStyle(.primary)
                .lineLimit(1)
                .minimumScaleFactor(0.8)
                .contentTransition(.numericText())

            // Label
            Text("Workouts")
                .font(.caption)
                .foregroundStyle(.secondary)
                .frame(height: 14)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 8)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
        .onAppear {
            animatedProgress = progress
            checkForGoalReached()
        }
        .onChange(of: progress) { oldValue, newValue in
            animatedProgress = newValue
            checkForGoalReached()
        }
    }

    private func checkForGoalReached() {
        let goalReached = workoutsCompleted >= weeklyGoal
        if goalReached && !hasReachedGoal {
            // First time reaching goal this week
            hasReachedGoal = true
            triggerCelebration()
        } else if !goalReached {
            hasReachedGoal = false
        }
    }

    private func triggerCelebration() {
        HapticManager.shared.trigger(.success)
        withAnimation(.spring(response: 0.5, dampingFraction: 0.6)) {
            showCelebration = true
        }

        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            withAnimation {
                showCelebration = false
            }
        }
    }
}

// Particle animation for celebration
struct ParticleModifier: ViewModifier {
    let index: Int
    @State private var isActive = false

    func body(content: Content) -> some View {
        content
            .offset(
                x: isActive ? cos(Double(index) * .pi / 6) * 50 : 0,
                y: isActive ? sin(Double(index) * .pi / 6) * 50 : 0
            )
            .opacity(isActive ? 0 : 1)
            .scaleEffect(isActive ? 1.5 : 0.5)
            .onAppear {
                withAnimation(.easeOut(duration: 1.0)) {
                    isActive = true
                }
            }
    }
}

// Individual Stat Bubble
struct StatBubble: View {
    let value: String
    let label: String
    let icon: String
    var accentColor: Color = .accentColor
    var changePercentage: Double? = nil
    var absoluteChange: Int? = nil

    var body: some View {
        ZStack(alignment: .topLeading) {
            VStack(spacing: 6) {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundStyle(accentColor)
                    .symbolRenderingMode(.hierarchical)
                    .frame(height: 50)

                Text(value)
                    .font(.title2.bold())
                    .foregroundStyle(.primary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.8)

                Text(label)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .frame(height: 14)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 12)
            .padding(.horizontal, 8)

            // Change badge (top-left corner)
            if let percentage = changePercentage {
                HStack(spacing: 2) {
                    Image(systemName: percentage >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(String(format: "%.1f%%", abs(percentage)))
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(percentage >= 0 ? .green : .secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    (percentage >= 0 ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1)),
                    in: Capsule()
                )
                .padding(6)
            } else if let absolute = absoluteChange {
                HStack(spacing: 2) {
                    Image(systemName: absolute >= 0 ? "arrow.up" : "arrow.down")
                        .font(.system(size: 8, weight: .bold))
                    Text(absolute >= 0 ? "+\(absolute)" : "\(absolute)")
                        .font(.system(size: 9, weight: .semibold))
                }
                .foregroundStyle(absolute >= 0 ? .green : .secondary)
                .padding(.horizontal, 4)
                .padding(.vertical, 2)
                .background(
                    (absolute >= 0 ? Color.green.opacity(0.15) : Color.secondary.opacity(0.1)),
                    in: Capsule()
                )
                .padding(6)
            }
        }
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

#Preview {
    WorkoutsListView()
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
