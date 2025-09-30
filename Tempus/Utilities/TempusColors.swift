//
//  TempusColors.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Brand colours for Tempus, following iOS 26 Liquid Glass design principles
/// Uses semantic colours where possible for automatic dark mode support
extension Color {
    // MARK: - Brand Primary Colours

    /// Deep Forest Green - Primary brand colour
    static let tempusPrimary = Color(red: 0/255, green: 66/255, blue: 37/255) // #004225

    /// Lighter Forest Green for hover/active states
    static let tempusPrimaryLight = Color(red: 27/255, green: 94/255, blue: 58/255) // #1B5E3A

    /// Darker Forest Green for pressed states
    static let tempusPrimaryDark = Color(red: 0/255, green: 40/255, blue: 21/255) // #002815

    // MARK: - Brand Secondary Colours

    /// Gold accent colour (adapts for dark mode)
    static let tempusSecondary = Color(red: 212/255, green: 175/255, blue: 55/255) // #D4AF37 (Light)

    /// Bright Gold for dark mode
    static let tempusSecondaryBright = Color(red: 255/255, green: 215/255, blue: 0/255) // #FFD700 (Dark)

    /// Adaptive gold that switches based on colour scheme
    static func tempusGold(for colorScheme: ColorScheme) -> Color {
        colorScheme == .dark ? .tempusSecondaryBright : .tempusSecondary
    }
}

// MARK: - Liquid Glass Materials
// iOS 26 provides built-in Liquid Glass materials:
// - .regularMaterial - Standard translucency
// - .ultraThinMaterial - Light translucency
// - .thickMaterial - Heavy translucency
// These automatically adapt to light/dark mode and surrounding content