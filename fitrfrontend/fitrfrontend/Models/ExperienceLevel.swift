//
//  ExperienceLevel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents the experience level of a user.
enum ExperienceLevel: String, Codable, CaseIterable {
    /// A beginner user is one who is just starting out with fitness
    case beginner = "BEGINNER"
    
    /// An intermediate user is one who has some experience with working out
    case intermediate = "INTERMEDIATE"
    
    /// An advanced user is one who is an expert in fitness
    case advanced = "ADVANCED"
}
