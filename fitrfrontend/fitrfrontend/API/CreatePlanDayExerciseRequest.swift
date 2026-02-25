//
//  CreatePlanDayExerciseRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreatePlanDayExerciseRequest: Codable {
  let exerciseId: Int64
  let targetSets: Int
  let targetReps: Int
  let targetDurationSeconds: Int
  let targetDistance: Float
  let targetCalories: Float
  let targetWeight: Float

  enum CodingKeys: String, CodingKey {
    case exerciseId = "exercise_id"
    case targetSets = "target_sets"
    case targetReps = "target_reps"
    case targetDurationSeconds = "target_duration_seconds"
    case targetDistance = "target_distance"
    case targetCalories = "target_calories"
    case targetWeight = "target_weight"
  }
}
