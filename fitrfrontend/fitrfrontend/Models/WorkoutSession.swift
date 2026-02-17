//
//  WorkoutSession.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a single workout session.
struct WorkoutSession: Codable, Identifiable {
    /// Unique identifier for the workout session
    let id: Int64
    
    /// The user ID that performed the workout session
    let userId: Int64
    
    /// The location ID of the workout session
    var workoutLocationId: Int64?
    
    /// The start time of the workout session
    var startTime: Date
    
    /// The end time of the workout session
    var endTime: Date?
    
    /// Any notes made about the workout session
    var notes: String?
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", workoutLocationId = "workout_location_id"
        case startTime, endTime, notes
    }
}
