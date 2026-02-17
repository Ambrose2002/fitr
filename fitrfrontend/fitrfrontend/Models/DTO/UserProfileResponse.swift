//
//  UserProfileResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a response to a user profile request.
struct UserProfileResponse: Codable, Identifiable {
    /// The profile ID
    let id: Int64
    
    /// The user's ID
    let userId: Int64
    
    /// The user's first name
    let firstname: String
    
    /// The user's last name
    let lastname: String
    
    /// The user's email address
    let email: String
    
    /// The user's gender
    let gender: Gender
    
    /// The user's height
    let height: Float
    
    /// The user's weight
    let weight: Float
    
    /// The user's experience level
    let experience: ExperienceLevel
    
    /// The user's goal
    let goal: Goal
    
    /// The user's preferred unit of weight
    let preferredWeightUnit: Unit
    
    /// The user's preferred unit of distance
    let preferredDistanceUnit: Unit
    
    /// Timestamp when the profile was created
    let createdAt: Date
}
