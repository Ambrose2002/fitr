//
//  MeasurementType.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents the type of measurement associated with a workout exercise.
enum MeasurementType: String, Codable, CaseIterable {
    /// The exercise is measured by the number of repetitions
    case reps = "REPS"
    
    /// The exercise is measured by the time taken to complete the exercise
    case time = "TIME"
    
    /// The exercise is measured by the number of repetitions and the time taken
    case repsAndTime = "REPS_AND_TIME"
    
    /// The exercise is measured by the time taken and the weight used
    case timeAndWeight = "TIME_AND_WEIGHT"
    
    /// The exercise is measured by the number of repetitions and the weight used
    case repsAndWeight = "REPS_AND_WEIGHT"
    
    /// The exercise is measured by the distance travelled and the time taken
    case distanceAndTime = "DISTANCE_AND_TIME"
    
    /// The exercise is measured by the calories burned and the time taken
    case caloriesAndTime = "CALORIES_AND_TIME"
}
