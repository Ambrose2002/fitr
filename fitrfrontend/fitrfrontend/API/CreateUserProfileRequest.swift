//
//  CreateUserProfileRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateUserProfileRequest: Codable {
    let gender: Gender
    let height: Float
    let weight: Float
    let experienceLevel: ExperienceLevel
    let goal: Goal
    let preferredWeightUnit: Unit
    let preferredDistanceUnit: Unit
}
