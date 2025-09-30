//
//  WelcomeView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

struct WelcomeView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var onboardingState: OnboardingState
    @State private var name: String = ""
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            // App Logo/Icon
            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            // Welcome Text
            VStack(spacing: 12) {
                Text("Welcome to Tempus")
                    .font(.largeTitle.bold())

                Text("Your intelligent workout tracker")
                    .font(.title3)
                    .foregroundStyle(.secondary)
            }

            Spacer()

            // Name Input
            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                TextField("Enter your name", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .focused($isNameFieldFocused)
                    .submitLabel(.done)
                    .onSubmit {
                        if isValidName {
                            continueOnboarding()
                        }
                    }
            }
            .padding(.horizontal, 32)

            // Continue Button
            Button {
                continueOnboarding()
            } label: {
                Text("Let's Get Started")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 32)
            .disabled(!isValidName)
            .opacity(isValidName ? 1.0 : 0.5)

            Spacer()
        }
        .padding()
        .preferredColorScheme(themeManager.colorScheme)
        .onAppear {
            // Focus the name field when view appears
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                isNameFieldFocused = true
            }
        }
    }

    private var isValidName: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty
    }

    private func continueOnboarding() {
        HapticManager.shared.trigger(.light)
        onboardingState.userName = name.trimmingCharacters(in: .whitespaces)
        onboardingState.nextStep()
    }
}

#Preview {
    WelcomeView(onboardingState: OnboardingState())
        .environmentObject(ThemeManager())
}