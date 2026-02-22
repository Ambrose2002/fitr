import Foundation

/// Formats unit values for display in the UI.
/// Converts backend values (kg, km) to user's preferred units and formats them with proper formatting.
struct UnitFormatter {

  /// Formats a weight value for display.
  /// - Parameters:
  ///   - kg: Weight value in kilograms (backend storage format)
  ///   - preferredUnit: The user's preferred weight unit
  ///   - decimalPlaces: Number of decimal places to display (default: 1)
  /// - Returns: Formatted string with value and unit suffix
  static func formatWeight(
    _ kg: Float,
    preferredUnit: Unit,
    decimalPlaces: Int = 1
  ) -> String {
    // Convert from kg to user's preferred unit
    let displayValue = preferredUnit == .kg ? kg : UnitConverter.kgToLb(kg)
    return
      "\(formatValue(displayValue, decimalPlaces: decimalPlaces)) \(preferredUnit.abbreviation)"
  }

  /// Formats a distance value for display.
  /// - Parameters:
  ///   - km: Distance value in kilometers (backend storage format)
  ///   - preferredUnit: The user's preferred distance unit
  ///   - decimalPlaces: Number of decimal places to display (default: 2)
  /// - Returns: Formatted string with value and unit suffix
  static func formatDistance(
    _ km: Float,
    preferredUnit: Unit,
    decimalPlaces: Int = 2
  ) -> String {
    // Convert from km to user's preferred unit
    let displayValue = preferredUnit == .km ? km : UnitConverter.kmToMi(km)
    return
      "\(formatValue(displayValue, decimalPlaces: decimalPlaces)) \(preferredUnit.abbreviation)"
  }

  /// Formats a height value for display.
  /// - Parameters:
  ///   - cm: Height value in centimeters (backend storage format)
  ///   - decimalPlaces: Number of decimal places to display (default: 1)
  /// - Returns: Formatted string with value and unit suffix
  static func formatHeight(
    _ cm: Float,
    decimalPlaces: Int = 1
  ) -> String {
    return "\(formatValue(cm, decimalPlaces: decimalPlaces)) cm"
  }

  /// Formats a numeric value to a specified number of decimal places.
  /// - Parameters:
  ///   - value: The numeric value to format
  ///   - decimalPlaces: Number of decimal places (default: 1)
  /// - Returns: Formatted string representation of the value
  static func formatValue(
    _ value: Float,
    decimalPlaces: Int = 1
  ) -> String {
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimalPlaces

    if let formattedValue = formatter.string(from: NSNumber(value: value)) {
      return formattedValue
    }
    return String(format: "%.\(decimalPlaces)f", value)
  }

  /// Formats a raw numeric value with a specified unit suffix.
  /// - Parameters:
  ///   - value: The numeric value to format
  ///   - unit: The unit to append
  ///   - decimalPlaces: Number of decimal places to display (default: 1)
  /// - Returns: Formatted string with value and unit suffix
  static func formatValueWithUnit(
    _ value: Float,
    unit: Unit,
    decimalPlaces: Int = 1
  ) -> String {
    return "\(formatValue(value, decimalPlaces: decimalPlaces)) \(unit.abbreviation)"
  }

  /// Gets the appropriate display format for a specific measurement type and unit.
  /// - Parameters:
  ///   - value: The numeric value to format
  ///   - unit: The unit of the value
  ///   - decimalPlaces: Number of decimal places to display
  /// - Returns: Formatted string with proper unit suffix
  static func formatMeasurement(
    _ value: Float,
    unit: Unit,
    decimalPlaces: Int = 1
  ) -> String {
    return "\(formatValue(value, decimalPlaces: decimalPlaces)) \(unit.abbreviation)"
  }
}

// MARK: - Unit Extension for Display

extension Unit {
  /// Returns the user-friendly abbreviation for this unit.
  /// - Returns: "KG", "LB", "KM", "MI", or "CM"
  var abbreviation: String {
    switch self {
    case .kg:
      return "kg"
    case .lb:
      return "lbs"
    case .km:
      return "km"
    case .mi:
      return "mi"
    case .cm:
      return "cm"
    }
  }

  /// Determines if this is a weight unit.
  var isWeightUnit: Bool {
    return self == .kg || self == .lb
  }

  /// Determines if this is a distance unit.
  var isDistanceUnit: Bool {
    return self == .km || self == .mi
  }

  /// Determines if this is a height unit.
  var isHeightUnit: Bool {
    return self == .cm
  }
}
