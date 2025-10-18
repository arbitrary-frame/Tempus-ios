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
    @Binding var postOnboardingAction: PostOnboardingAction
    @State private var currentPage = 0
    @State private var userName = ""
    @State private var weeklyGoal = 3

    var body: some View {
        ZStack {
            // Content for current page - wrapped with ID for synchronized animation
            Group {
                switch currentPage {
                case 0:
                    WelcomeScreen(userName: $userName, weeklyGoal: $weeklyGoal, onNext: {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentPage += 1
                        }
                    })
                case 1:
                    ValuePropositionScreen(onNext: {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentPage += 1
                        }
                    })
                case 2:
                    PresetLibraryIntroScreen(onNext: {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentPage += 1
                        }
                    })
                case 3:
                    SmartLoggingScreen(onNext: {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentPage += 1
                        }
                    })
                case 4:
                    ProgressTrackingScreen(onNext: {
                        withAnimation(.smooth(duration: 0.4)) {
                            currentPage += 1
                        }
                    })
                case 5:
                    FinalScreen(
                        userName: userName,
                        weeklyGoal: weeklyGoal,
                        onBrowsePresets: {
                            postOnboardingAction = .browsePresets
                            completeOnboarding()
                        },
                        onCreateWorkout: {
                            postOnboardingAction = .createWorkout
                            completeOnboarding()
                        }
                    )
                default:
                    EmptyView()
                }
            }
            .id(currentPage) // Force complete view replacement for synchronized animation
            .transition(.asymmetric(
                insertion: .move(edge: .trailing).combined(with: .opacity),
                removal: .move(edge: .leading).combined(with: .opacity)
            ))
            .animation(.smooth(duration: 0.4), value: currentPage)
        }
        .overlay(alignment: .topTrailing) {
            // Skip button (hide on first and last screen)
            if currentPage > 0 && currentPage < 5 {
                Button {
                    completeOnboarding()
                } label: {
                    Text("Skip")
                        .font(.subheadline)
                        .foregroundStyle(.secondary)
                }
                .frame(minWidth: 44, minHeight: 44)
                .padding(.trailing, 20)
                .padding(.top, 20)
            }
        }
        .overlay(alignment: .bottom) {
            // Page indicator (hide on first and last screen)
            if currentPage > 0 && currentPage < 5 {
                HStack(spacing: 8) {
                    ForEach(0..<6) { index in
                        Circle()
                            .fill(index == currentPage ? Color.accentColor : Color.secondary.opacity(0.3))
                            .frame(width: 8, height: 8)
                    }
                }
                .padding(.bottom, 50)
                .transition(.opacity)
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
                    .fixedSize(horizontal: false, vertical: true)

                Text("Track your strength journey with intelligent progress tracking")
                    .font(.title3)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
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
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.strengthtraining.traditional")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Your Workout Journey, Simplified")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

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
                        icon: "arrow.triangle.2.circlepath",
                        title: "Smart Templates",
                        description: "Create reusable workout routines for faster logging"
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
                .font(.system(size: 32))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 4) {
                Text(title)
                    .font(.subheadline.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(2)

                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .lineLimit(3)
            }
        }
        .frame(maxWidth: .infinity, minHeight: 160)
        .padding(14)
        .background(.regularMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

// MARK: - Preset Library Intro Screen
struct PresetLibraryIntroScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "tray.and.arrow.down.fill")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 14) {
                Text("Start Logging in Seconds")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                VStack(alignment: .leading, spacing: 12) {
                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 20))
                        Text("30+ preset exercises across 8 muscle groups")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 20))
                        Text("7 curated workout routines (Push, Pull, Legs, and more)")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }

                    HStack(spacing: 12) {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundStyle(.accent)
                            .font(.system(size: 20))
                        Text("Or create your own exercises from scratch")
                            .font(.body)
                            .fixedSize(horizontal: false, vertical: true)
                    }
                }
                .padding(.horizontal, 28)

                Text("You'll see the preset library after onboarding")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.top, 8)
                    .padding(.horizontal, 20)
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
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "brain.head.profile")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text("Logging That Learns From You")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

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
                .padding(.horizontal, 28)
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
                .font(.system(size: 26))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)
                .frame(width: 36)

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.bold())
                    .fixedSize(horizontal: false, vertical: true)
                Text(description)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}

// MARK: - Progress Tracking Screen
struct ProgressTrackingScreen: View {
    let onNext: () -> Void

    var body: some View {
        VStack(spacing: 28) {
            Spacer()

            Image(systemName: "chart.line.uptrend.xyaxis")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 14) {
                Text("See Your Progress")
                    .font(.title2.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                Text("Comprehensive analytics to track your strength journey")
                    .font(.body)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 28)

                // 2x3 Grid of analytics features
                LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                    AnalyticsFeatureCard(icon: "trophy.fill", label: "Personal Records")
                    AnalyticsFeatureCard(icon: "chart.bar.fill", label: "Weekly Consistency")
                    AnalyticsFeatureCard(icon: "flame.fill", label: "Streak Tracking")
                    AnalyticsFeatureCard(icon: "chart.xyaxis.line", label: "Volume Progression")
                    AnalyticsFeatureCard(icon: "app.badge.fill", label: "Home Widgets")
                    AnalyticsFeatureCard(icon: "calendar", label: "Workout Calendar")
                }
                .padding(.horizontal, 28)
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
                .font(.system(size: 30))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            Text(label)
                .font(.caption.bold())
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
                .lineLimit(2)
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
    let onBrowsePresets: () -> Void
    let onCreateWorkout: () -> Void

    var body: some View {
        VStack(spacing: 32) {
            Spacer()

            Image(systemName: "figure.arms.open")
                .font(.system(size: 80))
                .foregroundStyle(.accent)
                .symbolRenderingMode(.hierarchical)

            VStack(spacing: 16) {
                Text(userName.isEmpty ? "You're Ready to Start!" : "\(userName), You're Ready to Start!")
                    .font(.title.bold())
                    .multilineTextAlignment(.center)
                    .fixedSize(horizontal: false, vertical: true)
                    .padding(.horizontal, 20)

                VStack(spacing: 8) {
                    Text("Your weekly goal: \(weeklyGoal) workout\(weeklyGoal == 1 ? "" : "s")")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)

                    Text("We've prepared 30+ exercises and 7 routines to get you started")
                        .font(.body)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)
                        .padding(.horizontal, 20)
                }
            }

            Spacer()

            // Dual CTAs
            VStack(spacing: 12) {
                Button {
                    HapticManager.shared.trigger(.success)
                    onBrowsePresets()
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
                    onCreateWorkout()
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
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 8)

            Spacer()
        }
        .padding()
    }
}

#Preview {
    OnboardingView(postOnboardingAction: .constant(.none))
        .environmentObject(ThemeManager())
}
