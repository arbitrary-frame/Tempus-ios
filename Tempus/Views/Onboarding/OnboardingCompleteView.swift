//
//  OnboardingCompleteView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import SwiftData

struct OnboardingCompleteView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var onboardingState: OnboardingState

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // Success Icon
            Image(systemName: "checkmark.circle.fill")
                .font(.system(size: 80))
                .foregroundStyle(.green)
                .symbolRenderingMode(.hierarchical)

            // Completion message
            VStack(spacing: 12) {
                Text("You're All Set, \(onboardingState.userName)!")
                    .font(.largeTitle.bold())
                    .multilineTextAlignment(.center)

                Text("Ready to start tracking your workouts?")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .padding(.horizontal, 32)

            Spacer()

            // Options
            VStack(spacing: 16) {
                // Start fresh button
                Button {
                    startFresh()
                } label: {
                    VStack(spacing: 8) {
                        Text("Start Fresh")
                            .font(.headline)
                        Text("Clear demo data and begin")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .foregroundStyle(.white)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                // Continue with demo button
                Button {
                    continueWithDemo()
                } label: {
                    VStack(spacing: 8) {
                        Text("Keep Exploring")
                            .font(.headline)
                        Text("Continue with demo data")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.ultraThinMaterial)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 32)

            Spacer()
        }
        .padding()
        .preferredColorScheme(themeManager.colorScheme)
    }

    private func startFresh() {
        HapticManager.shared.trigger(.success)

        // Clear demo data
        DemoDataGenerator.clearDemoData(in: modelContext)

        // Complete onboarding
        onboardingState.completeOnboarding()
    }

    private func continueWithDemo() {
        HapticManager.shared.trigger(.light)

        // Keep demo data, just complete onboarding
        onboardingState.completeOnboarding()
    }
}

#Preview {
    OnboardingCompleteView(onboardingState: OnboardingState())
        .environmentObject(ThemeManager())
        .modelContainer(for: [Exercise.self, WorkoutRoutine.self, WorkoutEntry.self])
}