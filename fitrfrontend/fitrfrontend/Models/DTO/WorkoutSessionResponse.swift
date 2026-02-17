//
//  WorkoutSessionResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct WorkoutSessionResponse: Codable, Identifiable {
    let id: Int64
    let userId: Int64
    let workoutLocationId: Int64
    let startTime: Date
    let endTime: Date
    let notes: String?
    let workoutExercises: [WorkoutExerciseResponse]
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case workoutLocationId = "workout_location_id"
        case startTime
        case endTime
        case notes
        case workoutExercises
    }
}
