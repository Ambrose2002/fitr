//
//  AppColors.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/16/26.
//

import SwiftUI
import UIKit

/// Semantic color definitions for the Fitr app
/// Based on the design system from Visily mockups
struct AppColors {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - Teal/Cyan
    /// Hex: #1FD5F9
    /// RGB: (31, 213, 249)
    /// Usage: Primary buttons, highlights, selected states, active elements
    static let primaryTeal = Color(red: 31/255, green: 213/255, blue: 249/255)

    /// Stronger teal used for selected states over the standard accent.
    static let primaryTealStrong = Color(red: 0/255, green: 173/255, blue: 214/255)
    
    // MARK: - Semantic State Colors
    
    /// Info/Informational color - Blue
    /// Hex: #3B82F6
    /// RGB: (59, 130, 246)
    /// Usage: Information messages, links, informational badges
    static let infoBlue = Color(red: 59/255, green: 130/255, blue: 246/255)
    
    /// Success state color - Green
    /// Hex: #10B981
    /// RGB: (16, 185, 129)
    /// Usage: Success messages, completed states, checkmarks
    static let successGreen = Color(red: 16/255, green: 185/255, blue: 129/255)
    
    /// Error state color - Red
    /// Hex: #EF4444
    /// RGB: (239, 68, 68)
    /// Usage: Error messages, delete actions, validation errors
    static let errorRed = Color(red: 239/255, green: 68/255, blue: 68/255)
    
    /// Warning state color - Yellow
    /// Hex: #F59E0B
    /// RGB: (245, 158, 11)
    /// Usage: Warnings, attention states, caution indicators
    static let warningYellow = Color(red: 245/255, green: 158/255, blue: 11/255)
    
    // MARK: - Background Colors
    
    /// Light/Dark aware app background
    static let backgroundLight = dynamicColor(
        light: (249.0 / 255.0, 250.0 / 255.0, 251.0 / 255.0),
        dark: (10.0 / 255.0, 14.0 / 255.0, 22.0 / 255.0)
    )
    
    /// Light/Dark aware surface color
    static let cardWhite = dynamicColor(
        light: (1.0, 1.0, 1.0),
        dark: (21.0 / 255.0, 27.0 / 255.0, 38.0 / 255.0)
    )
    
    // MARK: - Text Colors
    
    /// Primary text color (light/dark aware)
    static let textPrimary = Color(uiColor: .label)
    
    /// Secondary text color (light/dark aware)
    static let textSecondary = Color(uiColor: .secondaryLabel)

    /// Text color intended for filled primary actions (accent backgrounds)
    static let textOnAccent = Color.white
    
    // MARK: - Border & Divider Colors
    
    /// Border/Divider color (light/dark aware)
    static let borderGray = dynamicColor(
        light: (229.0 / 255.0, 231.0 / 255.0, 235.0 / 255.0),
        dark: (54.0 / 255.0, 64.0 / 255.0, 80.0 / 255.0)
    )
    
    // MARK: - Convenience Extensions
    
    /// Semantic color for primary actions (same as primaryTeal)
    static let accent = primaryTeal

    /// Stronger semantic accent for emphasized selections
    static let accentStrong = primaryTealStrong
    
    /// Background for the entire app
    static let background = backgroundLight
    
    /// Standard card/surface color
    static let surface = cardWhite

    private static func dynamicColor(
        light: (Double, Double, Double),
        dark: (Double, Double, Double)
    ) -> Color {
        Color(
            UIColor { traitCollection in
                let components = traitCollection.userInterfaceStyle == .dark ? dark : light
                return UIColor(
                    red: components.0,
                    green: components.1,
                    blue: components.2,
                    alpha: 1.0
                )
            }
        )
    }
}

// MARK: - Color Extension for Hex Support

extension Color {
    /// Initialize Color from hex string
    /// - Parameter hex: Hex color string (e.g., "#1FD5F9" or "1FD5F9")
    init(hex: String) {
        let hex = hex.trimmingCharacters(in: CharacterSet.alphanumerics.inverted)
        var int: UInt64 = 0
        Scanner(string: hex).scanHexInt64(&int)
        let a, r, g, b: UInt64
        switch hex.count {
        case 3: // RGB (12-bit)
            (a, r, g, b) = (255, (int >> 8) * 17, (int >> 4 & 0xF) * 17, (int & 0xF) * 17)
        case 6: // RGB (24-bit)
            (a, r, g, b) = (255, int >> 16, int >> 8 & 0xFF, int & 0xFF)
        case 8: // ARGB (32-bit)
            (a, r, g, b) = (int >> 24, int >> 16 & 0xFF, int >> 8 & 0xFF, int & 0xFF)
        default:
            (a, r, g, b) = (255, 0, 0, 0)
        }
        self.init(
            .sRGB,
            red: Double(r) / 255,
            green: Double(g) / 255,
            blue: Double(b) / 255,
            opacity: Double(a) / 255
        )
    }
}
