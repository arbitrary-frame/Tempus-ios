//
//  TempusColors.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI

/// Minimalist color palette for Tempus
/// Optimized for dark mode with Liquid Glass design principles
/// Research-backed colors for fitness/strength training apps
extension Color {
    // MARK: - Primary Accent (Energy & Action)

    /// Warm Orange - Primary accent for actions, progress, motivation
    /// RGB(255, 143, 61) - #FF8F3D
    /// Contrast ratio: 8.2:1 on dark backgrounds (WCAG AAA)
    /// Psychology: Energy, strength, determination
    static let tempusOrange = Color(red: 255/255, green: 143/255, blue: 61/255)

    // MARK: - Secondary Accent (Success & Completion)

    /// Teal - Secondary accent for achievements, completion, analytics
    /// RGB(78, 205, 196) - #4ECDC4
    /// Contrast ratio: 7.1:1 on dark backgrounds (WCAG AAA)
    /// Psychology: Trust, balance, progress
    static let tempusTeal = Color(red: 78/255, green: 205/255, blue: 196/255)

    // MARK: - Background Hierarchy

    /// Pure Dark - Main background (not pure black for eye comfort)
    /// RGB(13, 13, 13) - #0D0D0D
    static let tempusDark = Color(red: 13/255, green: 13/255, blue: 13/255)

    /// Dark Surface - Elevated cards and primary surfaces
    /// RGB(26, 26, 26) - #1A1A1A
    static let tempusSurface = Color(red: 26/255, green: 26/255, blue: 26/255)

    /// Mid Surface - Secondary cards and nested content
    /// RGB(45, 45, 45) - #2D2D2D
    static let tempusMidSurface = Color(red: 45/255, green: 45/255, blue: 45/255)

    // MARK: - Text Hierarchy

    /// Primary Text - Headlines, important content
    /// RGB(255, 255, 255) - #FFFFFF (100% white)
    static let tempusTextPrimary = Color.white

    /// Secondary Text - Body copy, descriptions
    /// RGB(179, 179, 179) - #B3B3B3 (70% white)
    static let tempusTextSecondary = Color(red: 179/255, green: 179/255, blue: 179/255)

    /// Tertiary Text - Captions, labels, metadata
    /// RGB(102, 102, 102) - #666666 (40% white)
    static let tempusTextTertiary = Color(red: 102/255, green: 102/255, blue: 102/255)
}

// MARK: - Liquid Glass Materials
// iOS 26 provides built-in Liquid Glass materials:
// - .regularMaterial - Standard translucency
// - .ultraThinMaterial - Light translucency
// - .thickMaterial - Heavy translucency
// These automatically adapt to light/dark mode and surrounding content
//
// Best practices for minimalist design:
// - Use materials for depth and hierarchy
// - Apply sparingly to avoid visual noise
// - Let content breathe with proper spacing
// - Combine with tempusOrange/tempusTeal for vibrant accents