//
//  ExperienceLevel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents the experience level of a user.
enum ExperienceLevel: String, Codable, CaseIterable, Identifiable {
    /// A beginner user is one who is just starting out with fitness
    case beginner = "BEGINNER"
    
    /// An intermediate user is one who has some experience with working out
    case intermediate = "INTERMEDIATE"
    
    /// An advanced user is one who is an expert in fitness
    case advanced = "ADVANCED"
    
    var id: String { rawValue }
    var description: String {
        switch self {
        case .beginner: return "New to consistent training (0-1 years)"
        case .intermediate: return "Consistent training (1-3 years)"
        case .advanced: return "Expert level performance (3+ years)"
        }
    }
    
    var representation: String {
        switch self {
        case .beginner: return "Beginner"
        case .advanced: return "Advanced"
        case .intermediate: return "Intermediate"
        }
    }
}
