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
    let isSystemDefined: Bool
    let createdAt: Date
}
