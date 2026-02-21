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
  let workoutLocationId: Int64?
  let startTime: Date
  let endTime: Date?
  let notes: String?
  let title: String?
  let workoutExercises: [WorkoutExerciseResponse]

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case workoutLocationId = "workout_location_id"
    case startTime
    case endTime
    case notes
    case title
    case workoutExercises
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    userId = try container.decode(Int64.self, forKey: .userId)
    workoutLocationId = try container.decodeIfPresent(Int64.self, forKey: .workoutLocationId)
    startTime = try container.decode(Date.self, forKey: .startTime)
    endTime = try container.decodeIfPresent(Date.self, forKey: .endTime)
    notes = try container.decodeIfPresent(String.self, forKey: .notes)
    title = try container.decodeIfPresent(String.self, forKey: .title)
    workoutExercises =
      try container.decodeIfPresent([WorkoutExerciseResponse].self, forKey: .workoutExercises) ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(userId, forKey: .userId)
    try container.encodeIfPresent(workoutLocationId, forKey: .workoutLocationId)
    try container.encode(startTime, forKey: .startTime)
    try container.encodeIfPresent(endTime, forKey: .endTime)
    try container.encodeIfPresent(notes, forKey: .notes)
    try container.encodeIfPresent(title, forKey: .title)
    try container.encode(workoutExercises, forKey: .workoutExercises)
  }
}
