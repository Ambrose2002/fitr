//
//  WorkoutExerciseStats.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/22/26.
//

import Foundation

/// Statistics for a single exercise from a workout session.
/// Used to display detailed breakdown of exercises in the last session card.
struct WorkoutExerciseStats: Identifiable {
  let id: Int64
  let exerciseName: String
  let setCount: Int
  let avgReps: Float
  let avgWeight: Float
  let maxWeight: Float
  let totalVolume: Float
  let totalCalories: Float

  /// Formats the weight with the user's preferred unit.
  /// - Parameters:
  ///   - weight: Weight in kg (backend storage format)
  ///   - preferredUnit: User's preferred weight unit
  /// - Returns: Formatted weight string with unit
  static func formatWeight(_ weight: Float, preferredUnit: Unit) -> String {
    let displayValue = preferredUnit == .kg ? weight : UnitConverter.kgToLb(weight)
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
  }

  /// Formats the volume (weight × reps) with the user's preferred unit.
  /// - Parameters:
  ///   - volume: Volume in kg-reps (backend storage format)
  ///   - preferredUnit: User's preferred weight unit
  /// - Returns: Formatted volume string with unit
  static func formatVolume(_ volume: Float, preferredUnit: Unit) -> String {
    let displayValue = preferredUnit == .lb ? volume * UnitConverter.kgToLb(1.0) : volume
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 0)
  }
}
