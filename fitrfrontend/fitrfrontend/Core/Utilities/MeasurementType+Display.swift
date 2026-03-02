//
//  MeasurementType+Display.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

import Foundation

extension MeasurementType {
  var workoutDisplayLabel: String {
    switch self {
    case .reps:
      return "Strength"
    case .repsAndTime:
      return "Paced"
    case .time:
      return "Timed"
    case .timeAndWeight:
      return "Timed + Weight"
    case .repsAndWeight:
      return "Strength + Weight"
    case .distanceAndTime:
      return "Distance"
    case .caloriesAndTime:
      return "Calories"
    }
  }
}
