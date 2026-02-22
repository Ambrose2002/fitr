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

  init(
    id: Int64, workoutSessionId: Int64, exercise: ExerciseResponse, setLogs: [SetLogResponse] = []
  ) {
    self.id = id
    self.workoutSessionId = workoutSessionId
    self.exercise = exercise
    self.setLogs = setLogs
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    workoutSessionId = try container.decode(Int64.self, forKey: .workoutSessionId)
    exercise = try container.decode(ExerciseResponse.self, forKey: .exercise)
    setLogs = try container.decodeIfPresent([SetLogResponse].self, forKey: .setLogs) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(workoutSessionId, forKey: .workoutSessionId)
    try container.encode(exercise, forKey: .exercise)
    try container.encode(setLogs, forKey: .setLogs)
  }
}
