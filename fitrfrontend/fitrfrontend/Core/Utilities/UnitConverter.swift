import Foundation

/// Handles unit conversions between metric (kg, km) and imperial (lb, mi) units.
/// Backend always uses kg for weight and km for distance.
/// This utility converts user input to backend units and converts backend values to user's preferred units.
struct UnitConverter {

  // MARK: - Weight Conversions

  /// Converts kilograms to pounds.
  /// - Parameter kg: Weight in kilograms
  /// - Returns: Weight in pounds
  static func kgToLb(_ kg: Float) -> Float {
    return kg * 2.20462
  }

  /// Converts pounds to kilograms.
  /// - Parameter lb: Weight in pounds
  /// - Returns: Weight in kilograms
  static func lbToKg(_ lb: Float) -> Float {
    return lb / 2.20462
  }

  // MARK: - Distance Conversions

  /// Converts kilometers to miles.
  /// - Parameter km: Distance in kilometers
  /// - Returns: Distance in miles
  static func kmToMi(_ km: Float) -> Float {
    return km * 0.621371
  }

  /// Converts miles to kilometers.
  /// - Parameter mi: Distance in miles
  /// - Returns: Distance in kilometers
  static func miToKm(_ mi: Float) -> Float {
    return mi / 0.621371
  }

  // MARK: - Height Conversions

  /// Converts centimeters to inches.
  /// - Parameter cm: Height in centimeters
  /// - Returns: Height in inches
  static func cmToInches(_ cm: Float) -> Float {
    return cm / 2.54
  }

  /// Converts inches to centimeters.
  /// - Parameter inches: Height in inches
  /// - Returns: Height in centimeters
  static func inchesToCm(_ inches: Float) -> Float {
    return inches * 2.54
  }

  // MARK: - Generic Conversions

  /// Converts a weight value from one unit to another.
  /// - Parameters:
  ///   - value: The weight value to convert
  ///   - from: The source unit
  ///   - to: The target unit
  /// - Returns: The converted weight value, or 0 if conversion is not valid
  static func convertWeight(_ value: Float, from: Unit, to: Unit) -> Float {
    // No conversion needed if units are the same
    if from == to {
      return value
    }

    // Convert to kg first as intermediate unit
    let valueInKg: Float
    switch from {
    case .kg:
      valueInKg = value
    case .lb:
      valueInKg = lbToKg(value)
    case .km, .mi, .cm:
      // Weight conversion from non-weight unit is invalid
      return 0
    }

    // Then convert from kg to target unit
    switch to {
    case .kg:
      return valueInKg
    case .lb:
      return kgToLb(valueInKg)
    case .km, .mi, .cm:
      // Weight conversion to non-weight unit is invalid
      return 0
    }
  }

  /// Converts a distance value from one unit to another.
  /// - Parameters:
  ///   - value: The distance value to convert
  ///   - from: The source unit
  ///   - to: The target unit
  /// - Returns: The converted distance value, or 0 if conversion is not valid
  static func convertDistance(_ value: Float, from: Unit, to: Unit) -> Float {
    // No conversion needed if units are the same
    if from == to {
      return value
    }

    // Convert to km first as intermediate unit
    let valueInKm: Float
    switch from {
    case .km:
      valueInKm = value
    case .mi:
      valueInKm = miToKm(value)
    case .kg, .lb, .cm:
      // Distance conversion from non-distance unit is invalid
      return 0
    }

    // Then convert from km to target unit
    switch to {
    case .km:
      return valueInKm
    case .mi:
      return kmToMi(valueInKm)
    case .kg, .lb, .cm:
      // Distance conversion to non-distance unit is invalid
      return 0
    }
  }

  /// Converts a height value from one unit to another.
  /// - Parameters:
  ///   - value: The height value to convert
  ///   - from: The source unit
  ///   - to: The target unit
  /// - Returns: The converted height value, or 0 if conversion is not valid
  static func convertHeight(_ value: Float, from: Unit, to: Unit) -> Float {
    // No conversion needed if units are the same
    if from == to {
      return value
    }

    // Convert to cm first as intermediate unit
    let valueInCm: Float
    switch from {
    case .cm:
      valueInCm = value
    case .kg, .lb, .km, .mi:
      // Height conversion from non-height unit is invalid
      return 0
    }

    // Then convert from cm to target unit
    switch to {
    case .cm:
      return valueInCm
    case .kg, .lb, .km, .mi:
      // Height conversion to non-height unit is invalid
      return 0
    }
  }
}
