//
//  PlanDayResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct PlanDayResponse: Codable, Identifiable {
    let id: Int64
    let workoutPlanId: Int64
    let dayNumber: Int
    let name: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case workoutPlanId = "workout_plan_id"
        case dayNumber
        case name
    }
}
