//
//  UserProfile.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a user's profile.
struct UserProfile: Codable, Identifiable {
    /// The ID of the user profile
    let id: Int64
    
    /// The associated user ID
    let userId: Int64
    
    /// The user's height in meters
    var height: Float
    
    /// The user's weight in kilograms
    var weight: Float
    
    /// The user's gender
    var gender: Gender
    
    /// The user's experience level
    var experienceLevel: ExperienceLevel
    
    /// The user's goal
    var goal: Goal
    
    /// The preferred unit of measurement for weight
    var preferredWeightUnit: Unit
    
    /// The preferred unit of measurement for distance
    var preferredDistanceUnit: Unit
    
    /// The time the user profile was created
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", height, weight, gender, experienceLevel, goal
        case preferredWeightUnit, preferredDistanceUnit, createdAt
    }
}
