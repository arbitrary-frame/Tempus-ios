# Tempus Project Context

## Critical Platform Information

### iOS 26 - Apple's Latest Operating System
- **Release Date:** September 15, 2025
- **Naming Convention Change:** Apple switched from sequential numbering (iOS 18 → iOS 19) to year-based naming
- **Why "26"?** Represents the release season between September 2025 and September 2026
- **Compatibility:** iPhone 11 and newer (dropped support for iPhone XS, XS Max, XR with A12 Bionic)
- **Cross-Platform:** All Apple OSes now use year-based naming (iPadOS 26, macOS 26, watchOS 26, tvOS 26, visionOS 26)
- **Documentation:** https://www.apple.com/os/ios/ | https://www.macrumors.com/roundup/ios-26/

### Liquid Glass Design Language
- **Announced:** WWDC 2025 (June 9, 2025)
- **Description:** Apple's new unified visual design language across all platforms
- **Key Features:**
  - Translucent materials that reflect and refract surroundings
  - Dynamic depth effects responding to content and device movement
  - Realistic lighting and shaders that look like real glass
  - Adapts to light/dark appearance automatically
  - First major design change since iOS 7 in 2013
- **Apple's Vision:** Foundation for the next decade of iOS design
- **Materials in SwiftUI:**
  - `.regularMaterial` - Standard Liquid Glass effect
  - `.ultraThinMaterial` - Lighter translucency
  - `.thickMaterial` - Heavier translucency
  - Dynamic behaviour built into native SwiftUI components
- **Documentation:** https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/

### Technical Stack for Tempus
- **Language:** Swift 6 with strict concurrency
- **UI Framework:** SwiftUI with Liquid Glass design system
- **Minimum Deployment:** iOS 26.0+
- **IDE:** Xcode 26+
- **Simulator:** ⛔️ **ALWAYS use iPhone 17** (iOS 26 does NOT have iPhone 15/16)
- **Architecture:** MVVM with SwiftUI property wrappers
- **Data Persistence:** Swift Data (modern replacement for Core Data)
- **Charts:** Swift Charts with 3D support in iOS 26
- **Localisation:** UK English (en_GB), metric system only

### SF Symbols 7 - Iconography System
- **Version:** SF Symbols 7 (released September 9, 2025)
- **Library Size:** Over 6,900 symbols
- **Integration:** Seamlessly integrates with San Francisco system font
- **Key Features:**
  - Draw animations (Draw On/Draw Off) - calligraphic movement inspired animations
  - Variable Draw - convey strength or progress dynamically
  - Automatic gradients from single source color
  - Enhanced Magic Replace transitions between related symbols
  - Extensive localization support (Latin, Greek, Cyrillic, Hebrew, Arabic, CJK, etc.)
- **Compatibility:** iOS 26, iPadOS 26, macOS 26, watchOS 26, tvOS 26, visionOS 26
- **Documentation:**
  - https://developer.apple.com/sf-symbols/
  - WWDC25 Session: https://developer.apple.com/videos/play/wwdc2025/337/
- **Usage in Tempus:** All icons use SF Symbols 7 for consistent, scalable, and accessible iconography

### Design Principles
- Embrace Liquid Glass translucency throughout
- Use SF Symbols 7 for all iconography
- Support Dynamic Type and accessibility
- Implement haptic feedback for tactile responses
- Privacy-first: offline-only, no tracking, no analytics

## Project Overview
Tempus is a minimalist workout logging app for iOS 26 that allows users to record completed workouts with historical dates (NOT a live workout tracker). Focus on quick data entry and beautiful progress visualisation using Liquid Glass design language.

**Target Audience:** UK-based fitness enthusiasts who value privacy and want a no-nonsense workout tracker that feels native to iOS 26.

**Core Philosophy:** Simple, fast, private, beautiful.

## Key References
- iOS 26 Overview: https://www.macrumors.com/roundup/ios-26/
- Liquid Glass Design: https://www.apple.com/newsroom/2025/06/apple-introduces-a-delightful-and-elegant-new-software-design/
- Why iOS 26 naming: https://9to5mac.com/2025/09/16/why-is-it-called-ios-26-what-happened-to-ios-19-for-iphone/
- Liquid Glass in apps: https://9to5mac.com/2025/09/26/these-30-apps-feature-a-new-liquid-glass-design-for-ios-26/