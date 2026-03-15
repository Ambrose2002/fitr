//
//  WorkoutWeightNormalizer.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/14/26.
//

import Foundation

/// Workout-specific weight normalization utilities.
/// Keeps backend values in kg while presenting/editing user-friendly .0/.5 steps.
struct WorkoutWeightNormalizer {
  static let defaultStep: Float = 0.5
  private static let backendPrecision = 3

  static func snapToStep(_ value: Float, step: Float = defaultStep) -> Float {
    guard value.isFinite, step > 0 else {
      return value
    }

    let snapped = (Double(value) / Double(step)).rounded() * Double(step)
    return Float(snapped)
  }

  static func displayWeight(
    fromKg kg: Float,
    preferredUnit: Unit,
    step: Float = defaultStep
  ) -> Float {
    let converted = preferredUnit == .kg ? kg : UnitConverter.kgToLb(kg)
    return snapToStep(converted, step: step)
  }

  static func displayWeightText(
    fromKg kg: Float,
    preferredUnit: Unit,
    step: Float = defaultStep
  ) -> String {
    formatDisplayWeight(displayWeight(fromKg: kg, preferredUnit: preferredUnit, step: step), step: step)
  }

  static func formatDisplayWeight(_ value: Float, step: Float = defaultStep) -> String {
    let snapped = snapToStep(value, step: step)
    let decimalPlaces = snapped.rounded() == snapped ? 0 : 1
    return UnitFormatter.formatValue(snapped, decimalPlaces: decimalPlaces)
  }

  static func backendKg(
    fromDisplayWeight displayWeight: Float,
    preferredUnit: Unit,
    step: Float = defaultStep
  ) -> Float {
    let normalizedDisplayWeight = snapToStep(displayWeight, step: step)
    let kgValue = preferredUnit == .kg ? normalizedDisplayWeight : UnitConverter.lbToKg(normalizedDisplayWeight)
    return UnitConverter.round(kgValue, decimalPlaces: backendPrecision)
  }

  static func isEffectivelyEqual(_ lhs: Float, _ rhs: Float, tolerance: Float = 0.0001) -> Bool {
    abs(lhs - rhs) <= tolerance
  }
}
