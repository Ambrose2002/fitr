//
//  ExerciseResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct ExerciseResponse: Codable, Identifiable {
  let id: Int64
  let name: String
  let measurementType: MeasurementType
  let isSystemDefined: Bool?
  let createdAt: Date?

  enum CodingKeys: String, CodingKey {
    case id
    case name
    case measurementType
    case isSystemDefined
    case createdAt
  }

  init(
    id: Int64, name: String, measurementType: MeasurementType = .reps, isSystemDefined: Bool? = nil,
    createdAt: Date? = nil
  ) {
    self.id = id
    self.name = name
    self.measurementType = measurementType
    self.isSystemDefined = isSystemDefined
    self.createdAt = createdAt
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    name = try container.decode(String.self, forKey: .name)
    measurementType = try container.decode(MeasurementType.self, forKey: .measurementType)
    isSystemDefined = try container.decodeIfPresent(Bool.self, forKey: .isSystemDefined)
    createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(id, forKey: .id)
    try container.encode(name, forKey: .name)
    try container.encode(measurementType, forKey: .measurementType)
    try container.encodeIfPresent(isSystemDefined, forKey: .isSystemDefined)
    try container.encodeIfPresent(createdAt, forKey: .createdAt)
  }
}
