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

    private init() {}

    /// Trigger haptic feedback for different interaction types
    /// - Parameter type: The type of haptic feedback to trigger
    func trigger(_ type: HapticType) {
        switch type {
        case .light:
            let generator = UIImpactFeedbackGenerator(style: .light)
            generator.impactOccurred()
        case .medium:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.impactOccurred()
        case .heavy:
            let generator = UIImpactFeedbackGenerator(style: .heavy)
            generator.impactOccurred()
        case .success:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.success)
        case .warning:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.warning)
        case .error:
            let generator = UINotificationFeedbackGenerator()
            generator.notificationOccurred(.error)
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.selectionChanged()
        }
    }

    /// Prepare haptic engine for upcoming feedback (reduces latency)
    /// - Parameter type: The type of haptic to prepare
    func prepare(_ type: HapticType) {
        switch type {
        case .light, .medium, .heavy:
            let generator = UIImpactFeedbackGenerator(style: .medium)
            generator.prepare()
        case .success, .warning, .error:
            let generator = UINotificationFeedbackGenerator()
            generator.prepare()
        case .selection:
            let generator = UISelectionFeedbackGenerator()
            generator.prepare()
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