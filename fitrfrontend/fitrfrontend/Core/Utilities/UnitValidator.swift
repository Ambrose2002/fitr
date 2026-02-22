import Foundation

/// Validates and converts user input from their preferred units to backend units (kg, km).
/// Used when users enter values in the UI - ensures they're converted to backend storage format before sending to API.
struct UnitValidator {

  // MARK: - Weight Input Validation

  /// Converts user-entered weight input to kilograms.
  /// - Parameters:
  ///   - input: String input from the user (e.g., "150")
  ///   - sourceUnit: The unit the user entered in
  /// - Returns: Weight in kilograms, or nil if input is invalid
  static func convertWeightToKg(_ input: String, sourceUnit: Unit) -> Float? {
    guard let value = Float(input.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    switch sourceUnit {
    case .kg:
      return value
    case .lb:
      return UnitConverter.lbToKg(value)
    default:
      return nil
    }
  }

  /// Converts user-entered weight input from one unit to another.
  /// - Parameters:
  ///   - input: String input from the user
  ///   - from: The unit the user entered in
  ///   - to: The target unit to convert to
  /// - Returns: Converted weight value, or nil if input is invalid
  static func convertWeight(_ input: String, from: Unit, to: Unit) -> Float? {
    guard let value = Float(input.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    return UnitConverter.convertWeight(value, from: from, to: to)
  }

  // MARK: - Distance Input Validation

  /// Converts user-entered distance input to kilometers.
  /// - Parameters:
  ///   - input: String input from the user (e.g., "5.5")
  ///   - sourceUnit: The unit the user entered in
  /// - Returns: Distance in kilometers, or nil if input is invalid
  static func convertDistanceToKm(_ input: String, sourceUnit: Unit) -> Float? {
    guard let value = Float(input.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    switch sourceUnit {
    case .km:
      return value
    case .mi:
      return UnitConverter.miToKm(value)
    default:
      return nil
    }
  }

  /// Converts user-entered distance input from one unit to another.
  /// - Parameters:
  ///   - input: String input from the user
  ///   - from: The unit the user entered in
  ///   - to: The target unit to convert to
  /// - Returns: Converted distance value, or nil if input is invalid
  static func convertDistance(_ input: String, from: Unit, to: Unit) -> Float? {
    guard let value = Float(input.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    return UnitConverter.convertDistance(value, from: from, to: to)
  }

  // MARK: - Height Input Validation

  /// Converts user-entered height input to centimeters.
  /// - Parameters:
  ///   - input: String input from the user
  ///   - sourceUnit: The unit the user entered in
  /// - Returns: Height in centimeters, or nil if input is invalid
  static func convertHeightToCm(_ input: String, sourceUnit: Unit) -> Float? {
    guard let value = Float(input.trimmingCharacters(in: .whitespaces)) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    switch sourceUnit {
    case .cm:
      return value
    case .kg, .lb, .km, .mi:
      return nil
    }
  }

  // MARK: - Generic Input Validation

  /// Validates that a numeric input is positive and returns the parsed Float.
  /// - Parameter input: String input from the user
  /// - Returns: Positive Float value, or nil if input is invalid or non-positive
  static func validatePositiveNumber(_ input: String) -> Float? {
    let trimmed = input.trimmingCharacters(in: .whitespaces)

    guard let value = Float(trimmed) else {
      return nil
    }

    guard value > 0 else {
      return nil
    }

    return value
  }

  /// Validates and returns the range for reasonable weight values in a given unit.
  /// - Parameter unit: The weight unit to validate against
  /// - Returns: ClosedRange of valid values
  static func validWeightRange(for unit: Unit) -> ClosedRange<Float>? {
    switch unit {
    case .kg:
      // Reasonable weight range: 20kg to 500kg
      return 20...500
    case .lb:
      // Reasonable weight range: 44lbs to 1100lbs
      return 44...1100
    default:
      return nil
    }
  }

  /// Validates and returns the range for reasonable distance values in a given unit.
  /// - Parameter unit: The distance unit to validate against
  /// - Returns: ClosedRange of valid values
  static func validDistanceRange(for unit: Unit) -> ClosedRange<Float>? {
    switch unit {
    case .km:
      // Reasonable distance range: 0.1km to 1000km
      return 0.1...1000
    case .mi:
      // Reasonable distance range: 0.05mi to 620mi
      return 0.05...620
    default:
      return nil
    }
  }
}
