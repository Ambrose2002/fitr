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
  struct MetricSummary: Identifiable {
    let id: String
    let label: String
    let value: String
  }

  let id: Int64
  let exerciseName: String
  let measurementType: MeasurementType
  let setCount: Int
  let avgReps: Float?
  let avgWeight: Float?
  let avgDurationSeconds: Int?
  let avgDistance: Float?
  let avgCalories: Float?

  func averageMetricSummaries(
    preferredWeightUnit: Unit,
    preferredDistanceUnit: Unit
  ) -> [MetricSummary] {
    switch measurementType {
    case .reps:
      return [MetricSummary(id: "avg-reps", label: "Avg Reps", value: Self.formatReps(avgReps))]
    case .time:
      return [
        MetricSummary(
          id: "avg-duration",
          label: "Avg Duration",
          value: Self.formatDuration(avgDurationSeconds)
        )
      ]
    case .repsAndTime:
      return [
        MetricSummary(id: "avg-reps", label: "Avg Reps", value: Self.formatReps(avgReps)),
        MetricSummary(
          id: "avg-duration",
          label: "Avg Duration",
          value: Self.formatDuration(avgDurationSeconds)
        ),
      ]
    case .repsAndWeight:
      return [
        MetricSummary(
          id: "avg-weight",
          label: "Avg Weight",
          value: Self.formatWeight(avgWeight, preferredUnit: preferredWeightUnit)
        ),
        MetricSummary(id: "avg-reps", label: "Avg Reps", value: Self.formatReps(avgReps)),
      ]
    case .timeAndWeight:
      return [
        MetricSummary(
          id: "avg-weight",
          label: "Avg Weight",
          value: Self.formatWeight(avgWeight, preferredUnit: preferredWeightUnit)
        ),
        MetricSummary(
          id: "avg-duration",
          label: "Avg Duration",
          value: Self.formatDuration(avgDurationSeconds)
        ),
      ]
    case .distanceAndTime:
      return [
        MetricSummary(
          id: "avg-distance",
          label: "Avg Distance",
          value: Self.formatDistance(avgDistance, preferredUnit: preferredDistanceUnit)
        ),
        MetricSummary(
          id: "avg-duration",
          label: "Avg Duration",
          value: Self.formatDuration(avgDurationSeconds)
        ),
      ]
    case .caloriesAndTime:
      return [
        MetricSummary(
          id: "avg-calories",
          label: "Avg Calories",
          value: Self.formatCalories(avgCalories)
        ),
        MetricSummary(
          id: "avg-duration",
          label: "Avg Duration",
          value: Self.formatDuration(avgDurationSeconds)
        ),
      ]
    }
  }

  /// Formats the weight with the user's preferred unit.
  /// - Parameters:
  ///   - weight: Weight in kg (backend storage format)
  ///   - preferredUnit: User's preferred weight unit
  /// - Returns: Formatted weight string with unit
  static func formatWeight(_ weight: Float?, preferredUnit: Unit) -> String {
    guard let weight, weight > 0 else {
      return "--"
    }
    return UnitFormatter.formatWeight(weight, preferredUnit: preferredUnit)
  }

  static func formatDistance(_ distance: Float?, preferredUnit: Unit) -> String {
    guard let distance, distance > 0 else {
      return "--"
    }
    return UnitFormatter.formatDistance(distance, preferredUnit: preferredUnit)
  }

  static func formatDuration(_ durationSeconds: Int?) -> String {
    guard let durationSeconds, durationSeconds > 0 else {
      return "--"
    }
    return "\(DurationFormatter.minutesString(from: durationSeconds)) min"
  }

  static func formatCalories(_ calories: Float?) -> String {
    guard let calories, calories > 0 else {
      return "--"
    }
    return "\(UnitFormatter.formatValue(calories, decimalPlaces: 0)) cal"
  }

  static func formatReps(_ reps: Float?) -> String {
    guard let reps, reps > 0 else {
      return "--"
    }
    return UnitFormatter.formatValue(reps, decimalPlaces: 1)
  }
}
