//
//  HapticManager.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import UIKit

/// Centralized haptic feedback manager for consistent tactile responses throughout the app
@MainActor
final class HapticManager {
    static let shared = HapticManager()

    // Cached generator instances for better performance (reduces 40-50ms latency)
    private let lightImpactGenerator = UIImpactFeedbackGenerator(style: .light)
    private let mediumImpactGenerator = UIImpactFeedbackGenerator(style: .medium)
    private let heavyImpactGenerator = UIImpactFeedbackGenerator(style: .heavy)
    private let notificationGenerator = UINotificationFeedbackGenerator()
    private let selectionGenerator = UISelectionFeedbackGenerator()

    private init() {
        // Pre-prepare generators for optimal performance
        lightImpactGenerator.prepare()
        mediumImpactGenerator.prepare()
        heavyImpactGenerator.prepare()
        notificationGenerator.prepare()
        selectionGenerator.prepare()
    }

    /// Trigger haptic feedback for different interaction types
    /// - Parameter type: The type of haptic feedback to trigger
    func trigger(_ type: HapticType) {
        switch type {
        case .light:
            lightImpactGenerator.impactOccurred()
            lightImpactGenerator.prepare() // Prepare for next use
        case .medium:
            mediumImpactGenerator.impactOccurred()
            mediumImpactGenerator.prepare()
        case .heavy:
            heavyImpactGenerator.impactOccurred()
            heavyImpactGenerator.prepare()
        case .success:
            notificationGenerator.notificationOccurred(.success)
            notificationGenerator.prepare()
        case .warning:
            notificationGenerator.notificationOccurred(.warning)
            notificationGenerator.prepare()
        case .error:
            notificationGenerator.notificationOccurred(.error)
            notificationGenerator.prepare()
        case .selection:
            selectionGenerator.selectionChanged()
            selectionGenerator.prepare()
        }
    }

    /// Prepare haptic engine for upcoming feedback (reduces latency)
    /// - Parameter type: The type of haptic to prepare
    func prepare(_ type: HapticType) {
        switch type {
        case .light:
            lightImpactGenerator.prepare()
        case .medium:
            mediumImpactGenerator.prepare()
        case .heavy:
            heavyImpactGenerator.prepare()
        case .success, .warning, .error:
            notificationGenerator.prepare()
        case .selection:
            selectionGenerator.prepare()
        }
    }
}

/// Types of haptic feedback available
enum HapticType {
    case light      // Subtle feedback for minor actions (e.g., adding a set)
    case medium     // Standard feedback for regular actions (e.g., selecting an item)
    case heavy      // Strong feedback for significant actions (e.g., completing a workout)
    case success    // Success notification (e.g., workout saved)
    case warning    // Warning notification (e.g., about to delete)
    case error      // Error notification (e.g., validation failed)
    case selection  // Selection changed (e.g., picker value changed)
}