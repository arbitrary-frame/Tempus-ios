//
//  OnboardingView.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

struct OnboardingView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var onboardingState = OnboardingState()
    @State private var currentPage = 0
    @State private var userName = ""

    var body: some View {
        ZStack {
            TabView(selection: $currentPage) {
                // Screen 1: Welcome + Name
                WelcomeScreen(userName: $userName)
                    .tag(0)

                // Screen 2: Log Workouts
                FeatureScreen(
                    icon: "figure.strengthtraining.traditional",
                    title: "Log Your Workouts",
                    description: "Track sets, reps, and weights with an intuitive interface"
                )
                .tag(1)

                // Screen 3: Create Routines
                FeatureScreen(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Create Workout Routines",
                    description: "Build templates for your favorite workouts"
                )
                .tag(2)

                // Screen 4: Track Progress
                FinalScreen(userName: userName, onComplete: {
                    completeOnboarding()
                })
                .tag(3)
            }
            .tabViewStyle(.page(indexDisplayMode: .always))
            .indexViewStyle(.page(backgroundDisplayMode: .always))

            // Skip button (hide on last screen)
            if currentPage < 3 {
                VStack {
                    HStack {
                        Spacer()
                        Button {
                            completeOnboarding()
                        } label: {
                            Text("Skip")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                                .padding()
                        }
                    }
                    Spacer()
                }
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    private func completeOnboarding() {
        HapticManager.shared.trigger(.success)
        onboardingState.userName = userName.trimmingCharacters(in: .whitespaces)
        onboardingState.completeOnboarding()
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @Binding var userName: String
    @FocusState private var isNameFieldFocused: Bool

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 12) {
                Text("Welcome to Tempus")
                    .font(.largeTitle.bold())

                Text("Your intelligent workout tracker")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 8) {
                Text("What's your name?")
                    .font(.headline)
                    .foregroundStyle(.secondary)

                TextField("Enter your name", text: $userName)
                    .textFieldStyle(.roundedBorder)
                    .font(.title3)
                    .autocorrectionDisabled()
                    .textInputAutocapitalization(.words)
                    .focused($isNameFieldFocused)
            }
            .padding(.horizontal, 40)

            Text("Swipe to continue →")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Feature Screen
struct FeatureScreen: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: icon)
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(title)
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Text("Swipe to continue →")
                .font(.caption)
                .foregroundStyle(.secondary)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Final Screen
struct FinalScreen: View {
    let userName: String
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Track Your Progress")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("See your previous performance and beat your records")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }

            Spacer()

            Button {
                onComplete()
            } label: {
                Text(userName.isEmpty ? "Start Tracking" : "Let's Go, \(userName)!")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
}