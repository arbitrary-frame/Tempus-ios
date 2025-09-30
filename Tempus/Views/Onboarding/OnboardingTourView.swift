//
//  OnboardingTourView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

/// Main tour view that shows the app with overlay explanations
struct OnboardingTourView: View {
    @ObservedObject var onboardingState: OnboardingState
    @EnvironmentObject var themeManager: ThemeManager
    @State private var selectedTab = 0

    var body: some View {
        ZStack {
            // Show the actual app in the background
            TabView(selection: $selectedTab) {
                WorkoutsListView()
                    .tabItem {
                        Label("Workouts", systemImage: "figure.strengthtraining.traditional")
                    }
                    .tag(0)

                WorkoutRoutinesListView()
                    .tabItem {
                        Label("Routines", systemImage: "arrow.triangle.2.circlepath")
                    }
                    .tag(1)

                ExercisesListView()
                    .tabItem {
                        Label("Exercises", systemImage: "list.bullet.clipboard")
                    }
                    .tag(2)
            }
            .disabled(true) // Disable interaction during tour

            // Overlay with current step explanation
            VStack {
                Spacer()

                // Explanation card
                VStack(spacing: 16) {
                    // Progress indicator
                    HStack(spacing: 8) {
                        ForEach(1...onboardingState.totalSteps, id: \.self) { step in
                            Capsule()
                                .fill(step <= (onboardingState.currentStep - 1) ? Color.accentColor : Color.secondary.opacity(0.3))
                                .frame(height: 4)
                        }
                    }

                    // Step content
                    VStack(spacing: 12) {
                        Text(currentStepTitle)
                            .font(.title3.bold())

                        Text(currentStepDescription)
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }

                    // Next button
                    Button {
                        HapticManager.shared.trigger(.light)
                        if hasNextStep {
                            onboardingState.nextStep()
                        }
                    } label: {
                        Text(hasNextStep ? "Next" : "Finish Tour")
                            .font(.headline)
                            .foregroundStyle(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(.accent)
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }
                .padding(24)
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 20))
                .shadow(color: .black.opacity(0.2), radius: 20, x: 0, y: 10)
                .padding(.horizontal, 20)
                .padding(.bottom, 32)
            }
        }
        .onChange(of: onboardingState.currentStep) { _, newStep in
            updateTabSelection(for: newStep)
        }
        .onAppear {
            updateTabSelection(for: onboardingState.currentStep)
        }
    }

    private var currentStepTitle: String {
        switch onboardingState.currentStep {
        case 1:
            return "Welcome to Workouts"
        case 2:
            return "Explore Your Exercises"
        case 3:
            return "Create Workout Routines"
        case 4:
            return "Track Your Progress"
        case 5:
            return "You're All Set!"
        default:
            return ""
        }
    }

    private var currentStepDescription: String {
        switch onboardingState.currentStep {
        case 1:
            return "This is where all your workout history lives. You can log new workouts, edit past ones, and track your progress over time. Try tapping 'Start Workout' to begin!"
        case 2:
            return "Your exercise library contains all the movements you'll use in your workouts. Each exercise shows its muscle group and you can search or filter to find what you need quickly."
        case 3:
            return "Routines are pre-built workout templates with your favorite exercises. Create routines like 'Push Day' or 'Leg Day' to quickly start workouts without selecting exercises each time."
        case 4:
            return "Notice how each exercise shows your previous workout data? This helps you track progress and know what weights to aim for in your next session."
        case 5:
            return "You've completed the tour! We've set up some demo data so you can explore. When you're ready, tap 'Start Fresh' to begin your real workout journey."
        default:
            return ""
        }
    }

    private var hasNextStep: Bool {
        onboardingState.currentStep < onboardingState.totalSteps
    }

    private func updateTabSelection(for step: Int) {
        withAnimation {
            switch step {
            case 1:
                selectedTab = 0 // Workouts
            case 2:
                selectedTab = 2 // Exercises
            case 3:
                selectedTab = 1 // Routines
            case 4, 5:
                selectedTab = 0 // Workouts
            default:
                selectedTab = 0
            }
        }
    }
}

#Preview {
    OnboardingTourView(onboardingState: OnboardingState())
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}