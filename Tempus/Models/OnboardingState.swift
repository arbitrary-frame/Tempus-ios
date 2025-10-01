//
//  OnboardingState.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import Combine

/// Simple onboarding state management
class OnboardingState: ObservableObject {
    @AppStorage("hasCompletedOnboarding") var hasCompletedOnboarding: Bool = false
    @AppStorage("userName") var userName: String = ""

    @Published var weeklyWorkoutGoal: Int = UserDefaults.shared.integer(forKey: "weeklyWorkoutGoal") != 0 ? UserDefaults.shared.integer(forKey: "weeklyWorkoutGoal") : 3 {
        didSet {
            UserDefaults.shared.set(weeklyWorkoutGoal, forKey: "weeklyWorkoutGoal")
        }
    }

    func completeOnboarding() {
        hasCompletedOnboarding = true
    }

    func resetOnboarding() {
        hasCompletedOnboarding = false
        userName = ""
        weeklyWorkoutGoal = 3
        UserDefaults.shared.set(3, forKey: "weeklyWorkoutGoal")
    }
}