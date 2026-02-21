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
    
    enum CodingKeys: String, CodingKey {
        case id, userId, firstname, lastname, email, gender, height, weight
        case experience, goal, preferredWeightUnit, preferredDistanceUnit, createdAt
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(Int64.self, forKey: .id)
        userId = try container.decode(Int64.self, forKey: .userId)
        firstname = try container.decode(String.self, forKey: .firstname)
        lastname = try container.decode(String.self, forKey: .lastname)
        email = try container.decode(String.self, forKey: .email)
        gender = try container.decode(Gender.self, forKey: .gender)
        height = try container.decode(Float.self, forKey: .height)
        weight = try container.decode(Float.self, forKey: .weight)
        experience = try container.decode(ExperienceLevel.self, forKey: .experience)
        goal = try container.decode(Goal.self, forKey: .goal)
        preferredWeightUnit = try container.decode(Unit.self, forKey: .preferredWeightUnit)
        preferredDistanceUnit = try container.decode(Unit.self, forKey: .preferredDistanceUnit)
        
        // Handle date decoding - supports both ISO 8601 string and timestamp
        let dateFormatter = ISO8601DateFormatter()
        if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt),
           let date = dateFormatter.date(from: dateString) {
            createdAt = date
        } else if let timestamp = try container.decodeIfPresent(Double.self, forKey: .createdAt) {
            createdAt = Date(timeIntervalSince1970: timestamp)
        } else {
            throw DecodingError.dataCorruptedError(forKey: .createdAt,
                                                   in: container,
                                                   debugDescription: "Cannot decode createdAt")
        }
    }
}
