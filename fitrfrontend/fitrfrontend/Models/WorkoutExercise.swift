//
//  WorkoutExercise.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents an exercise performed in a workout session.
struct WorkoutExercise: Codable, Identifiable {
    /// Unique identifier for the exercise in the workout session
    let id: Int64
    
    /// The workout session ID that the exercise was performed in
    var workoutSessionId: Int64
    
    /// The exercise ID that was performed
    var exerciseId: Int64
    
    enum CodingKeys: String, CodingKey {
        case id, workoutSessionId = "workout_session_id", exerciseId = "exercise_id"
    }
}
