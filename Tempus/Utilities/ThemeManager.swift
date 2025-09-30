//
//  ThemeManager.swift
//  Tempus
//
//  Created by Ronak Pattani on 30/09/2025.
//

import SwiftUI
import Combine

/// Manages app-wide theme preferences
@MainActor
class ThemeManager: ObservableObject {
    @Published var isDarkMode: Bool {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }

    init() {
        self.isDarkMode = UserDefaults.standard.object(forKey: "isDarkMode") as? Bool ?? true
    }

    var colorScheme: ColorScheme {
        isDarkMode ? .dark : .light
    }
}