//
//  CreateWorkoutPlanDayRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateWorkoutPlanDayRequest: Codable {
  let dayNumber: Int
  let name: String

  enum CodingKeys: String, CodingKey {
    case dayNumber = "day_number"
    case name
  }
}
