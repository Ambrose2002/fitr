//
//  SetLog.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a set log in a workout session.
struct SetLog: Codable, Identifiable {
    /// Unique identifier for the set log
    let id: Int64
    
    /// The workout exercise ID this set log belongs to
    var workoutExerciseId: Int64
    
    /// The number of the set in the workout session
    var setNumber: Int
    
    /// The time at which the set was completed
    var completedAt: Date
    
    /// The weight used in the set
    var weight: Float
    
    /// The number of repetitions in the set
    var reps: Int
    
    /// The duration of the set in seconds
    var durationSeconds: Int64?
    
    /// The distance covered in the set
    var distance: Float
    
    /// The number of calories burned in the set
    var calories: Float
    
    enum CodingKeys: String, CodingKey {
        case id, workoutExerciseId = "workout_exercise_id", setNumber, completedAt
        case weight, reps, durationSeconds, distance, calories
    }
}
