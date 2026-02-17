//
//  CreateWorkoutSessionRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateWorkoutSessionRequest: Codable {
    let locationId: Int64?
    let notes: String?
    let endTime: String?
}
