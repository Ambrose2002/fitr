//
//  CreateSetLogRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateSetLogRequest: Codable {
    let sets: Int
    let averageReps: Int
    let averageWeight: Float
    let averageDurationSeconds: Int64?
    let averageDistance: Float
    let averageCalories: Float
}
