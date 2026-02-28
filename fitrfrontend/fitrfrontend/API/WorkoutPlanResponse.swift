//
//  WorkoutPlanResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct WorkoutPlanResponse: Codable, Identifiable, Hashable {
  let id: Int64
  let userId: Int64
  let name: String
  let createdAt: Date
  let isActive: Bool

  enum CodingKeys: String, CodingKey {
    case id
    case userId = "user_id"
    case name
    case createdAt
    case isActive = "isActive"
    case active
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    userId = try container.decode(Int64.self, forKey: .userId)
    name = try container.decode(String.self, forKey: .name)
    createdAt = try container.decode(Date.self, forKey: .createdAt)

    if let isActiveValue = try container.decodeIfPresent(Bool.self, forKey: .isActive) {
      isActive = isActiveValue
    } else if let activeValue = try container.decodeIfPresent(Bool.self, forKey: .active) {
      isActive = activeValue
    } else {
      isActive = false
    }
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(userId, forKey: .userId)
    try container.encode(name, forKey: .name)
    try container.encode(createdAt, forKey: .createdAt)
    try container.encode(isActive, forKey: .isActive)
  }
}
