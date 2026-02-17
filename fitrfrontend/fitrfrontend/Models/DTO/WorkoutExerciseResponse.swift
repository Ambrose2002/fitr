//
//  WorkoutExerciseResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct WorkoutExerciseResponse: Codable, Identifiable {
    let id: Int64
    let workoutSessionId: Int64
    let exercise: ExerciseResponse
    let setLogs: [SetLogResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutSessionId = "workout_session_id"
        case exercise
        case setLogs
    }
}
