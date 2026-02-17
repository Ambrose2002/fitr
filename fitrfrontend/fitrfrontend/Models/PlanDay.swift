//
//  PlanDay.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a single day in a workout plan.
struct PlanDay: Codable, Identifiable {
    /// Unique identifier for the plan day
    let id: Int64
    
    /// The workout plan ID that this day belongs to
    let workoutPlanId: Int64
    
    /// The number of the day in the workout plan
    var dayNumber: Int
    
    /// The name of the day in the workout plan
    var name: String
    
    enum CodingKeys: String, CodingKey {
        case id, workoutPlanId = "workout_plan_id", dayNumber, name
    }
}
