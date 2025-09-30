//
//  OnboardingState.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import Combine

/// Manages onboarding state and user preferences
class OnboardingState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""

    @Published var currentStep: Int = 0

    let totalSteps = 5

    func nextStep() {
        if currentStep < totalSteps {
            currentStep += 1
        }
    }

    func previousStep() {
        if currentStep > 0 {
            currentStep -= 1
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userName = ""
        currentStep = 0
    }
}