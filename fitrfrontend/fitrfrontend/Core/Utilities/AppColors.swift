//
//  AppColors.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/16/26.
//

import SwiftUI

/// Semantic color definitions for the Fitr app
/// Based on the design system from Visily mockups
struct AppColors {
    
    // MARK: - Primary Colors
    
    /// Primary brand color - Teal/Cyan
    /// Hex: #1FD5F9
    /// RGB: (31, 213, 249)
    /// Usage: Primary buttons, highlights, selected states, active elements
    static let primaryTeal = Color(red: 31/255, green: 213/255, blue: 249/255)
    
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
    
    /// Light background color - Off-white/Light gray
    /// Hex: #F9FAFB
    /// RGB: (249, 250, 251)
    /// Usage: App backgrounds, card backgrounds, screen backgrounds
    static let backgroundLight = Color(red: 249/255, green: 250/255, blue: 251/255)
    
    /// Card/Panel background - Pure white
    /// Hex: #FFFFFF
    /// RGB: (255, 255, 255)
    /// Usage: Card/panel backgrounds, elevated surfaces
    static let cardWhite = Color.white
    
    // MARK: - Text Colors
    
    /// Primary text color - Dark gray
    /// Hex: #1F2937
    /// RGB: (31, 41, 55)
    /// Usage: Primary text, headings, body text
    static let textPrimary = Color(red: 31/255, green: 41/255, blue: 55/255)
    
    /// Secondary text color - Medium gray
    /// Hex: #6B7280
    /// RGB: (107, 114, 128)
    /// Usage: Secondary text, captions, placeholder text, descriptions
    static let textSecondary = Color(red: 107/255, green: 114/255, blue: 128/255)
    
    // MARK: - Border & Divider Colors
    
    /// Border/Divider color - Light gray
    /// Hex: #E5E7EB
    /// RGB: (229, 231, 235)
    /// Usage: Borders, dividers, separators, input field borders
    static let borderGray = Color(red: 229/255, green: 231/255, blue: 235/255)
    
    // MARK: - Convenience Extensions
    
    /// Semantic color for primary actions (same as primaryTeal)
    static let accent = primaryTeal
    
    /// Background for the entire app
    static let background = backgroundLight
    
    /// Standard card/surface color
    static let surface = cardWhite
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
