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
    @State private var weeklyGoal = 3

    var body: some View {
        ZStack {
            // Content for current page
            Group {
                switch currentPage {
                case 0:
                    WelcomeScreen(userName: $userName, weeklyGoal: $weeklyGoal, onNext: {
                        withAnimation {
                            currentPage += 1
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 1:
                    ValuePropositionScreen(onNext: {
                        withAnimation {
                            currentPage += 1
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 2:
                    PresetLibraryIntroScreen(onNext: {
                        withAnimation {
                            currentPage += 1
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 3:
                    SmartLoggingScreen(onNext: {
                        withAnimation {
                            currentPage += 1
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 4:
                    ProgressTrackingScreen(onNext: {
                        withAnimation {
                            currentPage += 1
                        }
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                case 5:
                    FinalScreen(userName: userName, weeklyGoal: weeklyGoal, onComplete: {
                        completeOnboarding()
                    })
                    .transition(.asymmetric(insertion: .move(edge: .trailing), removal: .move(edge: .leading)))
                default:
                    EmptyView()
                }
            }

            // Skip button (hide on first and last screen)
            if currentPage > 0 && currentPage < 5 {
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

            // Page indicator
            VStack {
                Spacer()
                HStack(spacing: 8) {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 100)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
    }

    private func completeOnboarding() {
        HapticManager.shared.trigger(.success)
        onboardingState.userName = userName.trimmingCharacters(in: .whitespaces)
        onboardingState.weeklyWorkoutGoal = weeklyGoal
        onboardingState.completeOnboarding()
    }
}

// MARK: - Welcome Screen
struct WelcomeScreen: View {
    @Binding var userName: String
    @Binding var weeklyGoal: Int
    let onNext: () -> Void
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

                Text("Track your strength journey with intelligent progress tracking")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)
            }

            Spacer()

            VStack(alignment: .leading, spacing: 24) {
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
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()
                                Button("Done") {
                                    isNameFieldFocused = false
                                }
                            }
                        }
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Weekly Workout Goal")
                        .font(.headline)
                        .foregroundStyle(.secondary)

                    Picker("Weekly Goal", selection: $weeklyGoal) {
                        ForEach(1...7, id: \.self) { number in
                            Text("\(number) workout\(number == 1 ? "" : "s")")
                                .tag(number)
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(height: 100)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)

            Button {
                isNameFieldFocused = false
                HapticManager.shared.trigger(.light)
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    onNext()
                }
            } label: {
                Text("Continue")
                    .font(.headline)
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .padding()
                    .background(.accent)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .padding(.horizontal, 40)
            .padding(.top, 16)

            Spacer()
        }
        .padding()
    }
}

// MARK: - Value Proposition Screen
struct ValuePropositionScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 90))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Your Workout Journey, Simplified")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                // 2x2 Grid of value props
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    ValuePropCard(
                        icon: "figure.mixed.cardio",
                        title: "Progressive Overload",
                        description: "See previous performance for every exercise"
                    )

                    ValuePropCard(
                        icon: "chart.line.uptrend.xyaxis",
                        title: "Deep Analytics",
                        description: "Personal records, streaks, and volume tracking"
                    )

                    ValuePropCard(
                        icon: "lock.shield.fill",
                        title: "Private & Offline",
                        description: "Your data stays on your device, always"
                    )

                    ValuePropCard(
                        icon: "flag.fill",
                        title: "Built for the UK",
                        description: "DD/MM/YYYY, kg weights, British English"
                    )
                }
                .padding(.horizontal, 24)
            }

            Spacer()

            Button {
                HapticManager.shared.trigger(.light)
                onNext()
            } label: {
                Text("Continue")
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

struct ValuePropCard: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        VStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 36))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 140)
        .padding(16)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preset Library Intro Screen
struct PresetLibraryIntroScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Start Logging in Seconds")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                        Text("30+ preset exercises across 8 muscle groups")
                            .font(.body)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                        Text("7 curated workout routines (Push, Pull, Legs, and more)")
                            .font(.body)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                        Text("Or create your own exercises from scratch")
                            .font(.body)
                    }
                }
                .padding(.horizontal, 32)

                Text("You'll see the preset library after onboarding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .padding(.top, 8)
            }

            Spacer()

            Button {
                HapticManager.shared.trigger(.light)
                onNext()
            } label: {
                Text("Continue")
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

// MARK: - Smart Logging Screen
struct SmartLoggingScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Logging That Learns From You")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                VStack(alignment: .leading, spacing: 12) {
                    FeatureRow(
                        icon: "clock.arrow.circlepath",
                        title: "Previous Data Display",
                        description: "See your last performance for context"
                    )

                    FeatureRow(
                        icon: "hand.tap.fill",
                        title: "Tap to Populate",
                        description: "Copy previous sets with one tap"
                    )

                    FeatureRow(
                        icon: "arrow.down.circle.fill",
                        title: "Drop Sets",
                        description: "Multiple weight/rep pairs per set"
                    )

                    FeatureRow(
                        icon: "note.text",
                        title: "Notes",
                        description: "Track how you felt or exercise variations"
                    )
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                HapticManager.shared.trigger(.light)
                onNext()
            } label: {
                Text("Continue")
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

struct FeatureRow: View {
    let icon: String
    let title: String
    let description: String

    var body: some View {
        HStack(spacing: 16) {
            Image(systemName: icon)
                .font(.system(size: 28))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Progress Tracking Screen
struct ProgressTrackingScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("See Your Progress")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                Text("Comprehensive analytics to track your strength journey")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 32)

                // 2x3 Grid of analytics features
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AnalyticsFeatureCard(icon: "trophy.fill", label: "Personal Records")
                    AnalyticsFeatureCard(icon: "chart.bar.fill", label: "Weekly Consistency")
                    AnalyticsFeatureCard(icon: "flame.fill", label: "Streak Tracking")
                    AnalyticsFeatureCard(icon: "chart.xyaxis.line", label: "Volume Progression")
                    AnalyticsFeatureCard(icon: "app.badge.fill", label: "Home Widgets")
                    AnalyticsFeatureCard(icon: "calendar", label: "Workout Calendar")
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            Button {
                HapticManager.shared.trigger(.light)
                onNext()
            } label: {
                Text("Continue")
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

struct AnalyticsFeatureCard: View {
    let icon: String
    let label: String

    var body: some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 32))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            Text(label)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(maxWidth: .infinity, minHeight: 90)
        .padding(12)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Final Screen
struct FinalScreen: View {
    let userName: String
    let weeklyGoal: Int
    let onComplete: () -> Void

    var body: some View {
        VStack(spacing: 40) {
            Spacer()

            Image(systemName: "figure.arms.open")
                .font(.system(size: 100))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(userName.isEmpty ? "You're Ready to Start!" : "\(userName), You're Ready to Start!")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)

                VStack(spacing: 8) {
                    Text("Your weekly goal: \(weeklyGoal) workout\(weeklyGoal == 1 ? "" : "s")")
                        .font(.body)
                        .foregroundStyle(.secondary)

                    Text("We've prepared 30+ exercises and 7 routines to get you started")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                }
                .padding(.horizontal, 32)
            }

            Spacer()

            // Dual CTAs
            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.trigger(.success)
                    onComplete()
                } label: {
                    Label("Browse Preset Library", systemImage: "tray.and.arrow.down.fill")
                        .font(.headline)
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent)
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }

                Button {
                    HapticManager.shared.trigger(.success)
                    onComplete()
                } label: {
                    Label("Create My First Workout", systemImage: "plus.circle.fill")
                        .font(.headline)
                        .foregroundStyle(.accent)
                        .frame(maxWidth: .infinity)
                        .padding()
                        .background(.accent.opacity(0.1))
                        .overlay(
                            RoundedRectangle(cornerRadius: 12)
                                .stroke(.accent, lineWidth: 2)
                        )
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                }
            }
            .padding(.horizontal, 40)

            Text("You can change your goal anytime in Settings")
                .font(.caption)
                .foregroundStyle(.secondary)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView()
        .environmentObject(ThemeManager())
}
