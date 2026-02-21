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

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    workoutExerciseId = try container.decode(Int64.self, forKey: .workoutExerciseId)
    setNumber = try container.decode(Int.self, forKey: .setNumber)
    completedAt = try container.decodeIfPresent(Date.self, forKey: .completedAt) ?? .distantPast
    weight = try container.decodeIfPresent(Float.self, forKey: .weight) ?? 0
    reps = try container.decodeIfPresent(Int.self, forKey: .reps) ?? 0
    durationSeconds = try container.decodeIfPresent(Int64.self, forKey: .durationSeconds)
    distance = try container.decodeIfPresent(Float.self, forKey: .distance) ?? 0
    calories = try container.decodeIfPresent(Float.self, forKey: .calories) ?? 0
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(workoutExerciseId, forKey: .workoutExerciseId)
    try container.encode(setNumber, forKey: .setNumber)
    try container.encode(completedAt, forKey: .completedAt)
    try container.encode(weight, forKey: .weight)
    try container.encode(reps, forKey: .reps)
    try container.encodeIfPresent(durationSeconds, forKey: .durationSeconds)
    try container.encode(distance, forKey: .distance)
    try container.encode(calories, forKey: .calories)
  }
}
