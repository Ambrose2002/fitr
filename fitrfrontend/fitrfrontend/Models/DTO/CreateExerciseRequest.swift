//
//  CreateExerciseRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateExerciseRequest: Codable {
    let name: String
    let measurementType: MeasurementType
}
