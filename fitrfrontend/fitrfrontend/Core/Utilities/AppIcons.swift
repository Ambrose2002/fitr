//
//  AppIcons.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/16/26.
//

import SwiftUI

/// Centralized icon definitions using SF Symbols
/// All icons are based on the design system and API functionality
struct AppIcons {
    
    // MARK: - User & Profile Icons
    
    static let appIcon = Image(systemName: "bolt.fill")
    
    /// User profile icon
    /// Usage: Profile screen, user avatar, account settings
    static let userProfile = Image(systemName: "person.circle.fill")
    
    /// User profile outline (unfilled)
    static let userProfileOutline = Image(systemName: "person.circle")
    
    static let loginIcon = Image(systemName: "arrow.right.square")
    
    static let signupIcon = Image(systemName: "person.badge.plus")
    
    // MARK: - Authentication Icons
    
    /// Email/envelope icon
    /// Usage: Email input fields, login screen
    static let email = Image(systemName: "envelope.fill")
    
    /// Lock/password icon
    /// Usage: Password input fields, security settings
    static let lock = Image(systemName: "lock.fill")
    
    /// Eye icon (show password)
    /// Usage: Password visibility toggle
    static let eyeShow = Image(systemName: "eye.fill")
    
    /// Eye slash icon (hide password)
    /// Usage: Password visibility toggle
    static let eyeHide = Image(systemName: "eye.slash.fill")
    
    // MARK: - Workout Type Icons
    
    /// Strength training icon
    /// Usage: Strength workouts, weight training
    static let strength = Image(systemName: "dumbbell.fill")
    
    /// Running/cardio icon
    /// Usage: Cardio exercises, running activities
    static let running = Image(systemName: "figure.run")
    
    /// Cycling icon
    /// Usage: Cycling exercises
    static let cycling = Image(systemName: "bicycle")
    
    /// Walking icon
    /// Usage: Walking activities
    static let walking = Image(systemName: "figure.walk")
    
    // MARK: - Measurement Icons
    
    /// Weight/scale icon
    /// Usage: Weight logging, body metrics
    static let weight = Image(systemName: "scalemass.fill")
    
    /// Height/ruler icon
    /// Usage: Height input, measurements
    static let height = Image(systemName: "ruler.fill")
    
    // MARK: - Progress & Analytics Icons
    
    /// Statistics/chart icon
    /// Usage: Statistics, insights, charts
    static let statistics = Image(systemName: "chart.bar.fill")
    
    /// Line chart icon
    /// Usage: Progress tracking, trends
    static let lineChart = Image(systemName: "chart.line.uptrend.xyaxis")
    
    // MARK: - Action Icons
    
    /// Add/plus icon
    /// Usage: Add workout, add exercise, create actions
    static let add = Image(systemName: "plus.circle.fill")
    
    /// Plus icon (outline)
    static let addOutline = Image(systemName: "plus.circle")
    
    /// Edit icon
    /// Usage: Edit profile, edit workout
    static let edit = Image(systemName: "pencil.circle.fill")
    
    /// Delete/trash icon
    /// Usage: Delete actions
    static let delete = Image(systemName: "trash.fill")
    
    /// Checkmark icon
    /// Usage: Success states, completed items
    static let checkmark = Image(systemName: "checkmark.circle.fill")
    
    // MARK: - Settings & Configuration Icons
    
    /// Settings/gear icon
    /// Usage: Settings screen, preferences, configuration
    static let settings = Image(systemName: "gearshape.fill")
    
    // MARK: - Time & Calendar Icons
    
    /// Calendar icon
    /// Usage: Workout scheduling, plan days
    static let calendar = Image(systemName: "calendar.badge.clock")
    
    /// Timer/stopwatch icon
    /// Usage: Workout timer, duration tracking
    static let timer = Image(systemName: "timer")
    
    /// Clock icon
    /// Usage: Time display, duration
    static let clock = Image(systemName: "clock.fill")
    
    // MARK: - Activity Tracking Icons
    
    /// Heart rate icon
    /// Usage: Activity tracking, heart rate
    static let heartRate = Image(systemName: "waveform.path.ecg")
    
    /// Flame/calories icon
    /// Usage: Calorie tracking
    static let calories = Image(systemName: "flame.fill")
    
    // MARK: - Notes & Documentation Icons
    
    /// Note/document icon
    /// Usage: Workout notes, comments
    static let note = Image(systemName: "note.text")
    
    /// List icon
    /// Usage: Workout lists, exercise lists
    static let list = Image(systemName: "list.bullet")
    
    // MARK: - Navigation Icons
    
    /// Home icon
    /// Usage: Home tab, dashboard
    static let home = Image(systemName: "house.fill")
    
    /// Plans icon
    /// Usage: Workout plans tab
    static let plans = Image(systemName: "calendar")
    
    /// Workouts icon
    /// Usage: Workouts tab, active sessions
    static let workouts = Image(systemName: "figure.strengthtraining.traditional")
    
    /// Location/map icon
    /// Usage: Workout locations
    static let location = Image(systemName: "mappin.circle.fill")
    
    // MARK: - Goal-Specific Icons (Based on API Goal Enum)
    
    /// Strength goal icon
    /// Usage: STRENGTH goal type
    static let goalStrength = Image(systemName: "dumbbell.fill")
    
    /// Hypertrophy/muscle icon
    /// Usage: HYPERTROPHY goal type
    static let goalHypertrophy = Image(systemName: "figure.strengthtraining.traditional")
    
    /// Fat loss icon
    /// Usage: FATLOSS goal type
    static let goalFatLoss = Image(systemName: "flame.fill")
    
    /// General fitness icon
    /// Usage: GENERAL goal type
    static let goalGeneral = Image(systemName: "figure.walk")
    
    // MARK: - Experience Level Icons (Based on API ExperienceLevel Enum)
    
    /// Beginner level
    static let levelBeginner = Image(systemName: "star")
    
    /// Intermediate level
    static let levelIntermediate = Image(systemName: "star.leadinghalf.filled")
    
    /// Advanced level
    static let levelAdvanced = Image(systemName: "star.fill")
}

// MARK: - Icon Helper Extensions

extension Image {
    /// Apply standard icon styling
    /// - Parameters:
    ///   - size: Font size for the icon
    ///   - color: Color of the icon
    /// - Returns: Styled image view
    func iconStyle(size: CGFloat = 20, color: Color = AppColors.textPrimary) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: size, height: size)
            .foregroundColor(color)
    }
    
    /// Create a circular icon button
    /// - Parameters:
    ///   - size: Size of the icon
    ///   - backgroundColor: Background color of the circle
    ///   - foregroundColor: Icon color
    /// - Returns: Circular icon view
    func circularIcon(size: CGFloat = 40, backgroundColor: Color = AppColors.primaryTeal, foregroundColor: Color = .white) -> some View {
        self
            .resizable()
            .scaledToFit()
            .frame(width: size * 0.5, height: size * 0.5)
            .foregroundColor(foregroundColor)
            .frame(width: size, height: size)
            .background(
                Circle()
                    .fill(backgroundColor)
            )
    }
}
