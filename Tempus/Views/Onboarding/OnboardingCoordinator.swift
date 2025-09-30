//
//  OnboardingCoordinator.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct OnboardingCoordinator: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var onboardingState = OnboardingState()

    var body: some View {
        ZStack {
            switch onboardingState.currentStep {
            case 0:
                WelcomeView(onboardingState: onboardingState)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 1...5:
                OnboardingTourView(onboardingState: onboardingState)
                    .environmentObject(themeManager)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            case 6:
                OnboardingCompleteView(onboardingState: onboardingState)
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))

            default:
                EmptyView()
            }
        }
        .animation(.easeInOut(duration: 0.3), value: onboardingState.currentStep)
        .onAppear {
            // Generate demo data when onboarding starts
            if onboardingState.currentStep == 0 {
                DemoDataGenerator.generateAllDemoData(in: modelContext)
            }
        }
    }
}

#Preview {
    OnboardingCoordinator()
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}