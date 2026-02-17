//
//  WorkoutPlan.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a workout plan.
struct WorkoutPlan: Codable, Identifiable {
    /// The identifier of the workout plan
    let id: Int64
    
    /// The user ID associated with the workout plan
    let userId: Int64
    
    /// The name of the workout plan
    var name: String
    
    /// The time at which the workout plan was created
    let createdAt: Date
    
    /// Whether the workout plan is currently active
    var isActive: Bool
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, createdAt, isActive
    }
}
