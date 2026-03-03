//
//  ProgressViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/3/26.
//

import Foundation
internal import Combine

struct ProgressWeightPoint: Identifiable, Hashable {
  let id: Date
  let date: Date
  let value: Double

  init(date: Date, value: Double) {
    self.id = date
    self.date = date
    self.value = value
  }
}

struct ProgressMonthlyTrendPoint: Identifiable, Hashable {
  let id: Date
  let monthStart: Date
  let monthLabel: String
  let sessionCount: Int
  let totalVolume: Double
  let totalVolumeText: String
  let totalDurationMinutes: Int
  let totalDurationText: String
  let averageDurationMinutes: Int
  let averageDurationText: String
  let totalCalories: Double
  let totalCaloriesText: String
  let distinctExerciseIDs: [Int64]
  let normalizedVolume: Double

  init(
    monthStart: Date,
    monthLabel: String,
    sessionCount: Int,
    totalVolume: Double,
    totalVolumeText: String,
    totalDurationMinutes: Int,
    totalDurationText: String,
    averageDurationMinutes: Int,
    averageDurationText: String,
    totalCalories: Double,
    totalCaloriesText: String,
    distinctExerciseIDs: [Int64],
    normalizedVolume: Double
  ) {
    self.id = monthStart
    self.monthStart = monthStart
    self.monthLabel = monthLabel
    self.sessionCount = sessionCount
    self.totalVolume = totalVolume
    self.totalVolumeText = totalVolumeText
    self.totalDurationMinutes = totalDurationMinutes
    self.totalDurationText = totalDurationText
    self.averageDurationMinutes = averageDurationMinutes
    self.averageDurationText = averageDurationText
    self.totalCalories = totalCalories
    self.totalCaloriesText = totalCaloriesText
    self.distinctExerciseIDs = distinctExerciseIDs
    self.normalizedVolume = normalizedVolume
  }
}

struct ProgressSummaryStat: Identifiable, Hashable {
  let id: String
  let title: String
  let subtitle: String?
  let valueText: String
  let systemImage: String
  let isValueAccent: Bool
}

enum ProgressDeltaDirection {
  case up
  case down
  case flat
}

struct ProgressDashboardData {
  struct BodyCompositionData {
    let weightDisplayText: String?
    let weightBadgeText: String
    let weightDeltaText: String?
    let weightDeltaDirection: ProgressDeltaDirection?
    let weightDeltaDescription: String
    let weightPoints: [ProgressWeightPoint]
    let heightDisplayText: String
    let volumeDisplayText: String
    let bodyEmptyMessage: String?
  }

  let bodyComposition: BodyCompositionData
  let workoutSummary: [ProgressSummaryStat]
  let monthlyTrendPoints: [ProgressMonthlyTrendPoint]
  let monthlyInsight: String
  let hasMonthlyTrendData: Bool
}

@MainActor
final class ProgressViewModel: ObservableObject {
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var dashboard: ProgressDashboardData?

  private let workoutsService: WorkoutsService
  private let bodyMetricsService: BodyMetricsService
  private let sessionStore: SessionStore
  private var hasResolvedInitialState = false

  init(
    sessionStore: SessionStore,
    initialDashboard: ProgressDashboardData? = nil,
    initialError: String? = nil
  ) {
    self.sessionStore = sessionStore
    self.workoutsService = WorkoutsService()
    self.bodyMetricsService = BodyMetricsService()
    self.dashboard = initialDashboard
    self.errorMessage = initialError
    self.hasResolvedInitialState = initialDashboard != nil || initialError != nil
  }

  func loadDashboard(forceRefresh: Bool = false) async {
    guard !isLoading else { return }
    if hasResolvedInitialState && dashboard != nil && !forceRefresh {
      return
    }

    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    let calendar = Calendar.current
    let now = Date()
    let workoutsStartDate =
      calendar.date(byAdding: .day, value: -180, to: now) ?? now.addingTimeInterval(-180 * 86_400)

    do {
      async let workoutsResponse = workoutsService.fetchWorkoutHistory(
        startDate: workoutsStartDate,
        endDate: now
      )
      async let weightMetricsResponse = bodyMetricsService.fetchBodyMetrics(
        metricType: .weight,
        limit: 30
      )
      async let latestMetricsResponse = bodyMetricsService.fetchLatestBodyMetrics()

      let (workouts, weightMetrics, latestMetrics) = try await (
        workoutsResponse,
        weightMetricsResponse,
        latestMetricsResponse
      )

      let completedWorkouts = workouts
        .filter { $0.endTime != nil }
        .sorted { $0.startTime > $1.startTime }
      let sortedWeightMetrics = weightMetrics.sorted { $0.updatedAt > $1.updatedAt }

      dashboard = buildDashboard(
        completedWorkouts: completedWorkouts,
        weightMetrics: sortedWeightMetrics,
        latestMetrics: latestMetrics
      )
      hasResolvedInitialState = true
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
      hasResolvedInitialState = true
    } catch {
      errorMessage = error.localizedDescription
      hasResolvedInitialState = true
    }
  }

  func refresh() async {
    await loadDashboard(forceRefresh: true)
  }

  private func buildDashboard(
    completedWorkouts: [WorkoutSessionResponse],
    weightMetrics: [BodyMetricResponse],
    latestMetrics: [BodyMetricResponse]
  ) -> ProgressDashboardData {
    let latestMetricsByType = latestMetricLookup(from: latestMetrics)
    let bodyComposition = buildBodyComposition(
      completedWorkouts: completedWorkouts,
      weightMetrics: weightMetrics,
      latestMetricsByType: latestMetricsByType
    )
    let recentWorkouts = recentCompletedWorkouts(from: completedWorkouts, days: 30)
    let workoutSummary = buildWorkoutSummary(from: recentWorkouts, allCompletedWorkouts: completedWorkouts)
    let monthlyTrendPoints = buildMonthlyTrendPoints(from: completedWorkouts)

    return ProgressDashboardData(
      bodyComposition: bodyComposition,
      workoutSummary: workoutSummary,
      monthlyTrendPoints: monthlyTrendPoints,
      monthlyInsight: buildMonthlyInsight(from: monthlyTrendPoints),
      hasMonthlyTrendData: monthlyTrendPoints.contains { $0.sessionCount > 0 || $0.totalVolume > 0 }
    )
  }

  private func latestMetricLookup(from metrics: [BodyMetricResponse]) -> [MetricType: BodyMetricResponse] {
    var lookup: [MetricType: BodyMetricResponse] = [:]

    for metric in metrics {
      if let current = lookup[metric.metricType] {
        if metric.updatedAt > current.updatedAt {
          lookup[metric.metricType] = metric
        }
      } else {
        lookup[metric.metricType] = metric
      }
    }

    return lookup
  }

  private func buildBodyComposition(
    completedWorkouts: [WorkoutSessionResponse],
    weightMetrics: [BodyMetricResponse],
    latestMetricsByType: [MetricType: BodyMetricResponse]
  ) -> ProgressDashboardData.BodyCompositionData {
    let latestWeightMetric = weightMetrics.first ?? latestMetricsByType[.weight]
    let latestWeightValue = latestWeightMetric?.value ?? sessionStore.userProfile?.weight
    let weightDisplayText = latestWeightValue.map {
      UnitFormatter.formatWeight($0, preferredUnit: preferredWeightUnit, decimalPlaces: 1)
    }

    let weightPoints = buildWeightPoints(
      from: weightMetrics,
      fallbackWeight: latestWeightValue.map(Double.init)
    )
    let weightDelta = weightDeltaDetails(from: weightMetrics)

    let heightValue = latestMetricsByType[.height]?.value ?? sessionStore.userProfile?.height
    let heightDisplayText = heightValue.map {
      UnitFormatter.formatHeight($0)
    } ?? "--"

    let trailingMonthWorkouts = recentCompletedWorkouts(from: completedWorkouts, days: 30)
    let volumeKgReps = totalVolumeKgReps(for: trailingMonthWorkouts)

    return ProgressDashboardData.BodyCompositionData(
      weightDisplayText: weightDisplayText,
      weightBadgeText: weightMetrics.isEmpty ? "Current" : weightBadgeText(from: weightMetrics),
      weightDeltaText: weightDelta.text,
      weightDeltaDirection: weightDelta.direction,
      weightDeltaDescription: weightDelta.description,
      weightPoints: weightPoints,
      heightDisplayText: heightDisplayText,
      volumeDisplayText: formattedVolume(fromKgReps: volumeKgReps),
      bodyEmptyMessage: weightDisplayText == nil
        ? "Log your first weigh-in to start tracking body composition."
        : nil
    )
  }

  private func buildWeightPoints(
    from metrics: [BodyMetricResponse],
    fallbackWeight: Double?
  ) -> [ProgressWeightPoint] {
    let calendar = Calendar.current
    let now = Date()
    let thirtyDaysAgo =
      calendar.date(byAdding: .day, value: -30, to: now) ?? now.addingTimeInterval(-30 * 86_400)

    var chartMetrics = metrics
      .filter { $0.updatedAt >= thirtyDaysAgo }
      .sorted { $0.updatedAt < $1.updatedAt }

    if chartMetrics.isEmpty, let latestMetric = metrics.first {
      chartMetrics = [latestMetric]
    }

    if chartMetrics.isEmpty, let fallbackWeight {
      return [
        ProgressWeightPoint(
          date: now,
          value: displayWeightValue(fromKg: fallbackWeight)
        )
      ]
    }

    return chartMetrics.map { metric in
      ProgressWeightPoint(
        date: metric.updatedAt,
        value: displayWeightValue(fromKg: Double(metric.value))
      )
    }
  }

  private func weightDeltaDetails(
    from metrics: [BodyMetricResponse]
  ) -> (text: String?, direction: ProgressDeltaDirection?, description: String) {
    guard let latestMetric = metrics.first else {
      return (
        text: nil,
        direction: nil,
        description: "Add another weigh-in to see weekly change"
      )
    }

    let comparisonMetric = weeklyComparisonMetric(for: latestMetric, in: Array(metrics.dropFirst()))

    guard let comparisonMetric else {
      return (
        text: nil,
        direction: nil,
        description: "Add another weigh-in to see weekly change"
      )
    }

    let deltaKg = Double(latestMetric.value - comparisonMetric.value)
    let displayDelta = abs(displayWeightValue(fromKg: deltaKg))
    let deltaText = Self.formattedNumberString(displayDelta, maximumFractionDigits: 1)
      + " " + preferredWeightUnit.abbreviation

    if abs(deltaKg) < 0.01 {
      return (
        text: deltaText,
        direction: .flat,
        description: "since last week"
      )
    }

    return (
      text: deltaText,
      direction: deltaKg < 0 ? .down : .up,
      description: "since last week"
    )
  }

  private func weeklyComparisonMetric(
    for latestMetric: BodyMetricResponse,
    in previousMetrics: [BodyMetricResponse]
  ) -> BodyMetricResponse? {
    let calendar = Calendar.current

    let weeklyCandidates = previousMetrics.compactMap { metric -> (BodyMetricResponse, Int)? in
      let dayDifference = calendar.dateComponents(
        [.day],
        from: metric.updatedAt,
        to: latestMetric.updatedAt
      ).day ?? 0

      guard (6...14).contains(dayDifference) else {
        return nil
      }

      return (metric, abs(dayDifference - 7))
    }

    if let matchedMetric = weeklyCandidates.min(by: { lhs, rhs in
      if lhs.1 == rhs.1 {
        return lhs.0.updatedAt > rhs.0.updatedAt
      }
      return lhs.1 < rhs.1
    })?.0 {
      return matchedMetric
    }

    return previousMetrics.first
  }

  private func weightBadgeText(from metrics: [BodyMetricResponse]) -> String {
    guard let latestMetric = metrics.first else {
      return "Current"
    }

    let calendar = Calendar.current
    let weekStart =
      calendar.date(byAdding: .day, value: -7, to: latestMetric.updatedAt)
      ?? latestMetric.updatedAt.addingTimeInterval(-7 * 86_400)
    let trailingWeekMetrics = metrics.filter { $0.updatedAt >= weekStart }
    let window = trailingWeekMetrics.isEmpty ? [latestMetric] : trailingWeekMetrics
    let minimumValue = window.map(\.value).min() ?? latestMetric.value
    let maximumValue = window.map(\.value).max() ?? latestMetric.value

    if latestMetric.value <= minimumValue {
      return "Weekly Low"
    }

    if latestMetric.value >= maximumValue {
      return "Weekly High"
    }

    return "7-Day Trend"
  }

  private func buildWorkoutSummary(
    from recentWorkouts: [WorkoutSessionResponse],
    allCompletedWorkouts: [WorkoutSessionResponse]
  ) -> [ProgressSummaryStat] {
    let sessionCount = recentWorkouts.count
    let averageMinutes = averageDurationMinutes(for: recentWorkouts)
    let currentStreak = streak(for: allCompletedWorkouts)

    return [
      ProgressSummaryStat(
        id: "total-sessions",
        title: "Total Sessions",
        subtitle: "Last 30 days",
        valueText: "\(sessionCount)",
        systemImage: "link",
        isValueAccent: false
      ),
      ProgressSummaryStat(
        id: "average-duration",
        title: "Average Duration",
        subtitle: "Active minutes",
        valueText: "\(averageMinutes)m",
        systemImage: "clock",
        isValueAccent: false
      ),
      ProgressSummaryStat(
        id: "consistency",
        title: "Consistency",
        subtitle: "Current streak",
        valueText: "\(currentStreak) days",
        systemImage: "calendar",
        isValueAccent: true
      ),
    ]
  }

  private func buildMonthlyTrendPoints(
    from workouts: [WorkoutSessionResponse]
  ) -> [ProgressMonthlyTrendPoint] {
    let calendar = Calendar.current
    let now = Date()
    let currentMonthStart = calendar.date(
      from: calendar.dateComponents([.year, .month], from: now)
    ) ?? now

    let monthStarts: [Date] = (0..<6).compactMap { offset in
      calendar.date(byAdding: .month, value: offset - 5, to: currentMonthStart)
    }

    struct MonthlyAggregate {
      let monthStart: Date
      let monthLabel: String
      let sessionCount: Int
      let totalVolume: Double
      let totalVolumeText: String
      let totalDurationMinutes: Int
      let totalDurationText: String
      let averageDurationMinutes: Int
      let averageDurationText: String
      let totalCalories: Double
      let totalCaloriesText: String
      let distinctExerciseIDs: [Int64]
    }

    let aggregates = monthStarts.map { monthStart -> MonthlyAggregate in
      let nextMonthStart = calendar.date(byAdding: .month, value: 1, to: monthStart) ?? monthStart
      let monthWorkouts = workouts.filter { workout in
        workout.startTime >= monthStart && workout.startTime < nextMonthStart
      }

      let totalVolume = displayVolumeValue(fromKgReps: totalVolumeKgReps(for: monthWorkouts))
      let totalDurationMinutes = monthWorkouts.compactMap(durationMinutes(for:)).reduce(0, +)
      let averageMinutes = averageDurationMinutes(for: monthWorkouts)
      let totalCalories = monthWorkouts.reduce(0.0) { partialResult, workout in
        partialResult + workout.workoutExercises.reduce(0.0) { workoutTotal, workoutExercise in
          workoutTotal + workoutExercise.setLogs.reduce(0.0) { setTotal, setLog in
            setTotal + Double(setLog.calories)
          }
        }
      }
      let distinctExerciseIDs = Array(
        Set(
          monthWorkouts.flatMap { workout in
            workout.workoutExercises.map { $0.exercise.id }
          }
        )
      ).sorted()

      return MonthlyAggregate(
        monthStart: monthStart,
        monthLabel: Self.monthFormatter.string(from: monthStart),
        sessionCount: monthWorkouts.count,
        totalVolume: totalVolume,
        totalVolumeText: formattedVolume(fromDisplayValue: totalVolume),
        totalDurationMinutes: totalDurationMinutes,
        totalDurationText: Self.formattedDurationText(minutes: totalDurationMinutes),
        averageDurationMinutes: averageMinutes,
        averageDurationText: Self.formattedDurationText(minutes: averageMinutes),
        totalCalories: totalCalories,
        totalCaloriesText: Self.formattedCaloriesText(totalCalories),
        distinctExerciseIDs: distinctExerciseIDs
      )
    }

    let maxSessionCount = max(aggregates.map { $0.sessionCount }.max() ?? 0, 1)
    let maxVolume = aggregates.map { $0.totalVolume }.max() ?? 0

    return aggregates.map { aggregate in
      let normalizedVolume: Double
      if maxVolume > 0 {
        normalizedVolume = (aggregate.totalVolume / maxVolume) * Double(maxSessionCount)
      } else {
        normalizedVolume = 0
      }

      return ProgressMonthlyTrendPoint(
        monthStart: aggregate.monthStart,
        monthLabel: aggregate.monthLabel,
        sessionCount: aggregate.sessionCount,
        totalVolume: aggregate.totalVolume,
        totalVolumeText: aggregate.totalVolumeText,
        totalDurationMinutes: aggregate.totalDurationMinutes,
        totalDurationText: aggregate.totalDurationText,
        averageDurationMinutes: aggregate.averageDurationMinutes,
        averageDurationText: aggregate.averageDurationText,
        totalCalories: aggregate.totalCalories,
        totalCaloriesText: aggregate.totalCaloriesText,
        distinctExerciseIDs: aggregate.distinctExerciseIDs,
        normalizedVolume: normalizedVolume
      )
    }
  }

  private func buildMonthlyInsight(from points: [ProgressMonthlyTrendPoint]) -> String {
    guard !points.isEmpty else {
      return "Your workload has been steady across the last 6 months."
    }

    if points.allSatisfy({ $0.sessionCount == 0 && $0.totalVolume == 0 }) {
      return "Complete your first workout to start tracking monthly trends."
    }

    let firstHalf = Array(points.prefix(3))
    let secondHalf = Array(points.suffix(3))

    let firstHalfSessions = firstHalf.reduce(0) { $0 + $1.sessionCount }
    let secondHalfSessions = secondHalf.reduce(0) { $0 + $1.sessionCount }
    let firstHalfVolume = firstHalf.reduce(0.0) { $0 + $1.totalVolume }
    let secondHalfVolume = secondHalf.reduce(0.0) { $0 + $1.totalVolume }

    if secondHalfSessions > firstHalfSessions {
      return "Your training cadence is trending up across the last 6 months."
    }

    if secondHalfSessions < firstHalfSessions && secondHalfVolume < firstHalfVolume {
      return "Your recent momentum is below your earlier 6-month average."
    }

    return "Your workload has been steady across the last 6 months."
  }

  private func recentCompletedWorkouts(
    from workouts: [WorkoutSessionResponse],
    days: Int
  ) -> [WorkoutSessionResponse] {
    let calendar = Calendar.current
    let now = Date()
    let startDate =
      calendar.date(byAdding: .day, value: -days, to: now) ?? now.addingTimeInterval(Double(-days) * 86_400)

    return workouts.filter { workout in
      workout.startTime >= startDate && workout.startTime <= now
    }
  }

  private func averageDurationMinutes(for workouts: [WorkoutSessionResponse]) -> Int {
    let durations = workouts.compactMap { durationMinutes(for: $0) }

    guard !durations.isEmpty else {
      return 0
    }

    let total = durations.reduce(0, +)
    return Int((Double(total) / Double(durations.count)).rounded())
  }

  private func durationMinutes(for workout: WorkoutSessionResponse) -> Int? {
    guard let endTime = workout.endTime else {
      return nil
    }

    let durationSeconds = max(Int(endTime.timeIntervalSince(workout.startTime)), 0)
    return Int((Double(durationSeconds) / 60).rounded())
  }

  private func streak(for workouts: [WorkoutSessionResponse]) -> Int {
    let calendar = Calendar.current
    let workoutDays = Set(workouts.map { calendar.startOfDay(for: $0.startTime) })
    let today = calendar.startOfDay(for: Date())

    guard workoutDays.contains(today) else {
      return 0
    }

    var streakCount = 0
    var currentDay = today

    while workoutDays.contains(currentDay) {
      streakCount += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: currentDay) else {
        break
      }
      currentDay = previousDay
    }

    return streakCount
  }

  private func totalVolumeKgReps(for workouts: [WorkoutSessionResponse]) -> Double {
    workouts.reduce(0) { partialResult, workout in
      partialResult + workout.workoutExercises.reduce(0) { workoutTotal, workoutExercise in
        workoutTotal + workoutExercise.setLogs.reduce(0) { setTotal, setLog in
          setTotal + (Double(setLog.weight) * Double(setLog.reps))
        }
      }
    }
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private func displayWeightValue(fromKg value: Double) -> Double {
    if preferredWeightUnit == .lb {
      return Double(UnitConverter.kgToLb(Float(value)))
    }

    return value
  }

  private func displayVolumeValue(fromKgReps value: Double) -> Double {
    if preferredWeightUnit == .lb {
      return value * Double(UnitConverter.kgToLb(1.0))
    }

    return value
  }

  private func formattedVolume(fromKgReps value: Double) -> String {
    formattedVolume(fromDisplayValue: displayVolumeValue(fromKgReps: value))
  }

  private func formattedVolume(fromDisplayValue value: Double) -> String {
    if value >= 1000 {
      return String(format: "%.1f K %@", value / 1000, preferredWeightUnit.abbreviation)
    }

    if value <= 0 {
      return "0 \(preferredWeightUnit.abbreviation)"
    }

    return "\(Self.formattedNumberString(value, maximumFractionDigits: 0)) \(preferredWeightUnit.abbreviation)"
  }

  private static func formattedNumberString(
    _ value: Double,
    maximumFractionDigits: Int
  ) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = maximumFractionDigits

    if let result = formatter.string(from: NSNumber(value: value)) {
      return result
    }

    return String(format: "%.\(maximumFractionDigits)f", value)
  }

  private static func formattedDurationText(minutes: Int) -> String {
    guard minutes > 0 else {
      return "0m"
    }

    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours == 0 {
      return "\(minutes)m"
    }

    if remainingMinutes == 0 {
      return "\(hours)h"
    }

    return "\(hours)h \(remainingMinutes)m"
  }

  private static func formattedCaloriesText(_ calories: Double) -> String {
    let formattedValue = formattedNumberString(max(calories, 0), maximumFractionDigits: 0)
    return "\(formattedValue) cal"
  }

  private static let monthFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM"
    return formatter
  }()
}
