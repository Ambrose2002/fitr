//
//  UpdateWorkoutPlanRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

import Foundation

struct UpdateWorkoutPlanRequest: Codable {
  let name: String
  let isActive: Bool

  enum CodingKeys: String, CodingKey {
    case name
    case isActive = "isActive"
  }
}
