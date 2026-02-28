import Foundation

struct DurationFormatter {
  static func minutesString(from seconds: Int, decimalPlaces: Int = 2) -> String {
    let minutes = Double(seconds) / 60.0
    let formatter = NumberFormatter()
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = decimalPlaces

    if let formattedMinutes = formatter.string(from: NSNumber(value: minutes)) {
      return formattedMinutes
    }

    return String(format: "%.\(decimalPlaces)f", minutes)
  }

  static func seconds(fromMinutesText text: String, maxMinutes: Double = 360) -> Int? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard
      let minutes = Double(trimmed),
      minutes.isFinite,
      minutes > 0,
      minutes <= maxMinutes
    else {
      return nil
    }

    return Int((minutes * 60).rounded())
  }

  static func isValidMinutesInput(_ text: String, maxMinutes: Double = 360) -> Bool {
    seconds(fromMinutesText: text, maxMinutes: maxMinutes) != nil
  }
}
