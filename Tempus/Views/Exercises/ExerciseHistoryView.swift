//
//  ExerciseHistoryView.swift
//  Tempus
//
//  Created by Ronak Pattani on 17/10/2026.
//

import SwiftUI
import SwiftData
import Charts

/// One logged session of a single exercise, derived from a WorkoutEntry
struct ExerciseHistorySession: Identifiable {
    let id: UUID
    let date: Date
    let routineName: String?
    let sets: [WorkoutSet]
    let topSet: WeightRep
    let volume: Double
    let totalReps: Int
    let bestOneRM: Double
    var topWeightChange: Double?

    /// Builds sessions for an exercise, newest first. Sets with no weight or reps are ignored.
    static func sessions(for exerciseID: UUID, in workouts: [WorkoutEntry], excluding excludedWorkoutID: UUID? = nil) -> [ExerciseHistorySession] {
        var sessions: [ExerciseHistorySession] = []

        for workout in workouts.sorted(by: { $0.workoutDate > $1.workoutDate }) {
            guard workout.id != excludedWorkoutID else { continue }

            for data in workout.exercisesData where data.exerciseID == exerciseID {
                let sets = data.sets
                    .map { set in
                        WorkoutSet(setNumber: set.setNumber, weightsAndReps: set.weightsAndReps.filter { $0.weight > 0 || $0.reps > 0 })
                    }
                    .filter { !$0.weightsAndReps.isEmpty }

                let allReps = sets.flatMap(\.weightsAndReps)
                guard let topSet = allReps.max(by: { ($0.weight, $0.reps) < ($1.weight, $1.reps) }) else { continue }

                let multiplier = data.isUnilateral ? 2.0 : 1.0
                let volume = allReps.reduce(0) { $0 + $1.weight * Double($1.reps) * multiplier }

                sessions.append(ExerciseHistorySession(
                    id: data.id,
                    date: workout.workoutDate,
                    routineName: workout.routine?.name,
                    sets: sets,
                    topSet: topSet,
                    volume: volume,
                    totalReps: allReps.reduce(0) { $0 + $1.reps },
                    bestOneRM: allReps.map { AnalyticsService.estimate1RM(weight: $0.weight, reps: $0.reps) }.max() ?? 0
                ))
            }
        }

        // Compare each session's top weight with the session before it
        for index in sessions.indices.dropLast() {
            sessions[index].topWeightChange = sessions[index].topSet.weight - sessions[index + 1].topSet.weight
        }

        return sessions
    }
}

/// What the history chart plots
enum HistoryChartMetric: String, CaseIterable, Identifiable {
    case weight = "Weight"
    case reps = "Reps"
    case oneRM = "Est. 1RM"

    var id: String { rawValue }

    func value(for session: ExerciseHistorySession) -> Double {
        switch self {
        case .weight: session.topSet.weight
        case .reps: Double(session.totalReps)
        case .oneRM: session.bestOneRM
        }
    }

    func axisLabel(_ value: Double) -> String {
        switch self {
        case .reps: "\(Int(value))"
        case .weight, .oneRM: "\(ExerciseHistoryView.formatWeight(value))kg"
        }
    }

    func selectionLabel(for session: ExerciseHistorySession) -> String {
        switch self {
        case .weight: session.topSet.displayText
        case .reps: "\(session.totalReps) reps · \(session.sets.count) sets"
        case .oneRM: "\(ExerciseHistoryView.formatWeight(session.bestOneRM))kg est."
        }
    }
}

struct ExerciseHistoryView: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \WorkoutEntry.workoutDate, order: .reverse) private var allWorkouts: [WorkoutEntry]
    @State private var chartMetric: HistoryChartMetric?
    @State private var selectedChartDate: Date?

    let exercise: Exercise
    /// Workout to leave out of the history (e.g. the one currently being edited)
    var excludingWorkoutID: UUID? = nil
    /// When provided, an Edit button is shown in the toolbar
    var onEdit: (() -> Void)? = nil

    private static let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_GB")
        formatter.dateFormat = "EEE d MMM yyyy"
        return formatter
    }()

    var body: some View {
        let sessions = ExerciseHistorySession.sessions(for: exercise.id, in: allWorkouts, excluding: excludingWorkoutID)

        NavigationStack {
            List {
                if sessions.isEmpty {
                    Section {
                        ContentUnavailableView {
                            Label("No History Yet", systemImage: "clock.arrow.circlepath")
                        } description: {
                            Text("Log this exercise in a workout and your lifts will appear here.")
                        }
                    }
                    .listRowBackground(Color.clear)
                } else {
                    Section {
                        summary(for: sessions)
                            .listRowInsets(EdgeInsets())
                            .listRowBackground(Color.clear)
                    }

                    if sessions.count >= 2 {
                        Section {
                            trendChart(for: sessions)
                                .padding(.vertical, 8)
                        } header: {
                            Label("Progress", systemImage: "chart.line.uptrend.xyaxis")
                                .symbolRenderingMode(.hierarchical)
                        }
                    }

                    Section {
                        ForEach(sessions) { session in
                            sessionRow(session)
                        }
                    } header: {
                        Label("Sessions", systemImage: "clock.arrow.circlepath")
                            .symbolRenderingMode(.hierarchical)
                    }
                }

                aboutSection
            }
            .listStyle(.insetGrouped)
            .navigationTitle(exercise.name)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                if let onEdit {
                    ToolbarItem(placement: .cancellationAction) {
                        Button("Edit") {
                            onEdit()
                        }
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") {
                        dismiss()
                    }
                }
            }
        }
    }

    // MARK: - Summary

    private func summary(for sessions: [ExerciseHistorySession]) -> some View {
        let best = sessions.max { ($0.topSet.weight, $0.topSet.reps) < ($1.topSet.weight, $1.topSet.reps) }!
        let bestOneRM = sessions.map(\.bestOneRM).max() ?? 0

        return HStack(spacing: 12) {
            HistoryStatTile(title: "Best Set", value: best.topSet.displayText, icon: "trophy.fill")
            HistoryStatTile(title: "Est. 1RM", value: "\(Self.formatWeight(bestOneRM))kg", icon: "bolt.fill")
            HistoryStatTile(title: "Sessions", value: "\(sessions.count)", icon: "calendar")
        }
    }

    // MARK: - Chart

    private func trendChart(for sessions: [ExerciseHistorySession]) -> some View {
        // Bodyweight exercises have no weight to chart, so default to reps
        let metric = chartMetric ?? (sessions.contains { $0.topSet.weight > 0 } ? .weight : .reps)
        let chronological = Array(sessions.reversed())
        let selected = selectedChartDate.flatMap { date in
            sessions.min { abs($0.date.timeIntervalSince(date)) < abs($1.date.timeIntervalSince(date)) }
        }

        return VStack(alignment: .leading, spacing: 12) {
            Picker("Metric", selection: Binding(
                get: { metric },
                set: { newValue in
                    HapticManager.shared.trigger(.selection)
                    withAnimation(.spring(response: 0.3)) { chartMetric = newValue }
                }
            )) {
                ForEach(HistoryChartMetric.allCases) { metric in
                    Text(metric.rawValue).tag(metric)
                }
            }
            .pickerStyle(.segmented)

            Chart {
                ForEach(chronological) { session in
                    if metric == .reps {
                        BarMark(
                            x: .value("Date", session.date, unit: .day),
                            y: .value(metric.rawValue, metric.value(for: session))
                        )
                        .foregroundStyle(Color.accentColor.opacity(selected == nil || selected?.id == session.id ? 1 : 0.4))
                        .cornerRadius(4)
                    } else {
                        LineMark(
                            x: .value("Date", session.date, unit: .day),
                            y: .value(metric.rawValue, metric.value(for: session))
                        )
                        .interpolationMethod(.monotone)
                        .foregroundStyle(Color.accentColor)

                        PointMark(
                            x: .value("Date", session.date, unit: .day),
                            y: .value(metric.rawValue, metric.value(for: session))
                        )
                        .foregroundStyle(Color.accentColor)
                        .symbolSize(selected?.id == session.id ? 80 : 30)
                    }
                }

                if let selected {
                    RuleMark(x: .value("Selected", selected.date, unit: .day))
                        .foregroundStyle(.secondary.opacity(0.4))
                        .lineStyle(StrokeStyle(lineWidth: 1, dash: [3, 3]))
                        .annotation(position: .top, spacing: 4, overflowResolution: .init(x: .fit(to: .chart), y: .fit(to: .chart))) {
                            VStack(spacing: 2) {
                                Text(selected.date, format: .dateTime.day().month(.abbreviated))
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                Text(metric.selectionLabel(for: selected))
                                    .font(.caption.bold())
                            }
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 8))
                        }
                }
            }
            .chartXSelection(value: $selectedChartDate)
            .chartYAxis {
                AxisMarks(position: .leading) { value in
                    AxisGridLine()
                    AxisValueLabel {
                        if let number = value.as(Double.self) {
                            Text(metric.axisLabel(number))
                        }
                    }
                }
            }
            .chartXAxis {
                AxisMarks(values: .automatic(desiredCount: 4)) { _ in
                    AxisGridLine()
                    AxisValueLabel(format: .dateTime.day().month(.abbreviated), centered: false)
                }
            }
            .chartXScale(range: .plotDimension(padding: 20))
            .environment(\.locale, Locale(identifier: "en_GB"))
            .frame(height: 180)
            .onChange(of: selected?.id) { _, newValue in
                if newValue != nil {
                    HapticManager.shared.trigger(.selection)
                }
            }

            Text("Drag across the chart to see each session")
                .font(.caption2)
                .foregroundStyle(.tertiary)
        }
    }

    // MARK: - Session Row

    private func sessionRow(_ session: ExerciseHistorySession) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .firstTextBaseline) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(Self.dateFormatter.string(from: session.date))
                        .font(.subheadline.bold())

                    if let routineName = session.routineName {
                        Text(routineName)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Spacer()

                if let change = session.topWeightChange {
                    changeBadge(change)
                }
            }

            FlowLayout(spacing: 6) {
                ForEach(session.sets) { set in
                    Text(set.displayText)
                        .font(.caption)
                        .padding(.horizontal, 8)
                        .padding(.vertical, 4)
                        .background(.ultraThinMaterial, in: Capsule())
                }
            }

            if session.volume > 0 {
                Text("Volume \(session.volume.formatted(.number.precision(.fractionLength(0)).locale(Locale(identifier: "en_GB"))))kg")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 4)
    }

    private func changeBadge(_ change: Double) -> some View {
        let (icon, color): (String, Color) = {
            if change > 0 { return ("arrow.up", .green) }
            if change < 0 { return ("arrow.down", .orange) }
            return ("equal", .secondary)
        }()

        return HStack(spacing: 2) {
            Image(systemName: icon)
            if change != 0 {
                Text("\(Self.formatWeight(abs(change)))kg")
            }
        }
        .font(.caption.bold())
        .foregroundStyle(color)
        .padding(.horizontal, 8)
        .padding(.vertical, 4)
        .background(color.opacity(0.15), in: Capsule())
    }

    // MARK: - About

    @ViewBuilder
    private var aboutSection: some View {
        Section {
            if let description = exercise.exerciseDescription, !description.isEmpty {
                Text(description)
                    .font(.body)
            }

            if let group = MuscleGroup(rawValue: exercise.muscleGroup) {
                Label(exercise.muscleGroup, systemImage: group.icon)
            } else {
                Text(exercise.muscleGroup)
            }

            if !exercise.tags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(exercise.tags, id: \.self) { tag in
                        Text(tag)
                            .font(.caption)
                            .padding(.horizontal, 10)
                            .padding(.vertical, 6)
                            .background(.regularMaterial, in: Capsule())
                    }
                }
                .padding(.vertical, 4)
            }
        } header: {
            Label("About", systemImage: "info.circle")
                .symbolRenderingMode(.hierarchical)
        }
    }

    // MARK: - Formatting

    static func formatWeight(_ weight: Double) -> String {
        weight.truncatingRemainder(dividingBy: 1) == 0
            ? String(format: "%.0f", weight)
            : String(format: "%.1f", weight)
    }
}

private struct HistoryStatTile: View {
    let title: String
    let value: String
    let icon: String

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.subheadline)
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            Text(value)
                .font(.subheadline.bold())
                .lineLimit(1)
                .minimumScaleFactor(0.7)

            Text(title)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 6)
        .background(.regularMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Set Formatting

extension WeightRep {
    /// e.g. "60kg × 8", or "—" when empty
    var displayText: String {
        if weight == 0 && reps == 0 {
            return "—"
        }
        return "\(ExerciseHistoryView.formatWeight(weight))kg × \(reps)"
    }
}

extension WorkoutSet {
    /// e.g. "60kg × 8 → 50kg × 6" for drop sets
    var displayText: String {
        weightsAndReps.map(\.displayText).joined(separator: " → ")
    }
}

#Preview {
    ExerciseHistoryView(exercise: Exercise(name: "Bench Press", muscleGroup: "Chest"))
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}
