//
//  PlanExercise.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents an exercise in a workout plan.
struct PlanExercise: Codable, Identifiable {
    /// The ID of the plan exercise
    let id: Int64
    
    /// The plan day ID that the plan exercise belongs to
    var planDayId: Int64
    
    /// The exercise ID that the plan exercise refers to
    var exerciseId: Int64
    
    /// The target number of sets for the plan exercise
    var targetSets: Int
    
    /// The target number of reps for the plan exercise
    var targetReps: Int
    
    /// The target duration in seconds for the plan exercise
    var targetDurationSeconds: Int
    
    /// The target distance in meters for the plan exercise
    var targetDistance: Float
    
    /// The target calories for the plan exercise
    var targetCalories: Float
    
    enum CodingKeys: String, CodingKey {
        case id, planDayId = "plan_day_id", exerciseId = "exercise_id"
        case targetSets, targetReps, targetDurationSeconds, targetDistance, targetCalories
    }
}
