//
//  CreateSingleSetLogRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/2/26.
//

import Foundation

struct CreateSingleSetLogRequest: Codable {
  let setNumber: Int
  let reps: Int?
  let weight: Float?
  let durationSeconds: Int64?
  let distance: Float?
  let calories: Float?
}
