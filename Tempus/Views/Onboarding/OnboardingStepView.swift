//
//  OnboardingStepView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Reusable onboarding step view with consistent layout
struct OnboardingStepView<Content: View>: View {
    @ObservedObject var onboardingState: OnboardingState
    let stepNumber: Int
    let title: String
    let description: String
    let content: Content

    init(
        onboardingState: OnboardingState,
        stepNumber: Int,
        title: String,
        description: String,
        @ViewBuilder content: () -> Content
    ) {
        self.onboardingState = onboardingState
        self.stepNumber = stepNumber
        self.title = title
        self.description = description
        self.content = content()
    }

    var body: some View {
        VStack(spacing: 0) {
            // Header with progress
            VStack(spacing: 16) {
                // Progress indicator
                HStack(spacing: 8) {
                    ForEach(1...onboardingState.totalSteps, id: \.self) { step in
                        Capsule()
                            .fill(step <= stepNumber ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(height: 4)
                    }
                }
                .padding(.horizontal, 32)
                .padding(.top, 16)

                // Title and description
                VStack(spacing: 8) {
                    Text(title)
                        .font(.title2.bold())
                    Text(description)
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }
            .padding(.bottom, 24)

            // Content area
            content
                .frame(maxWidth: .infinity, maxHeight: .infinity)

            // Next button
            Button {
                HapticManager.shared.trigger(.light)
                onboardingState.nextStep()
            } label: {
                Text("Next")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .padding(.vertical, 16)
        }
    }
}

#Preview {
    OnboardingStepView(
        onboardingState: OnboardingState(),
        stepNumber: 1,
        title: "Example Step",
        description: "This is how the step looks"
    ) {
        Text("Content goes here")
    }
}