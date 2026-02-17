//
//  SetLogResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct SetLogResponse: Codable, Identifiable {
    let id: Int64
    let workoutExerciseId: Int64
    let setNumber: Int
    let completedAt: Date
    let weight: Float
    let reps: Int
    let durationSeconds: Int64?
    let distance: Float
    let calories: Float
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutExerciseId = "workout_exercise_id"
        case setNumber
        case completedAt
        case weight
        case reps
        case durationSeconds
        case distance
        case calories
    }
}
