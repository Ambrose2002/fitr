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
}
