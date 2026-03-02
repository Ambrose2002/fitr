//
//  WorkoutsViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

internal import Combine
import Foundation
import SwiftUI

struct WorkoutHistoryFilters: Equatable {
  var selectedMonthKey: String?
  var selectedWorkoutType: WorkoutHistoryType?
  var selectedLocation: String?

  var hasActiveFilters: Bool {
    selectedMonthKey != nil || selectedWorkoutType != nil || selectedLocation != nil
  }

  var activeFilterCount: Int {
    [selectedMonthKey, selectedLocation].compactMap { $0 }.count + (selectedWorkoutType == nil ? 0 : 1)
  }
}

enum WorkoutHistoryType: String, CaseIterable, Identifiable, Hashable {
  case strength
  case cardio
  case hybrid

  var id: String { rawValue }

  var badgeLabel: String {
    rawValue.uppercased()
  }

  var displayLabel: String {
    switch self {
    case .strength:
      return "Strength"
    case .cardio:
      return "Cardio"
    case .hybrid:
      return "Hybrid"
    }
  }

  var accentColor: Color {
    switch self {
    case .strength:
      return AppColors.accent
    case .cardio:
      return AppColors.infoBlue
    case .hybrid:
      return AppColors.warningYellow
    }
  }

  var icon: Image {
    switch self {
    case .strength:
      return AppIcons.strength
    case .cardio:
      return AppIcons.running
    case .hybrid:
      return Image(systemName: "bolt.heart.fill")
    }
  }

  static func modality(for measurementType: MeasurementType) -> WorkoutHistoryType {
    switch measurementType {
    case .reps, .repsAndWeight, .timeAndWeight:
      return .strength
    case .time, .distanceAndTime, .caloriesAndTime:
      return .cardio
    case .repsAndTime:
      return .hybrid
    }
  }
}

struct WorkoutHistoryMonthOption: Identifiable, Hashable {
  let id: String
  let label: String
}

struct WorkoutHistoryRow: Identifiable, Hashable {
  let id: Int64
  let timestampLabel: String
  let title: String
  let locationLabel: String
  let type: WorkoutHistoryType
  let hasPersonalRecord: Bool
  let durationText: String
  let exerciseCountText: String
  let volumeText: String
  let monthKey: String
}

struct WorkoutHistorySection: Identifiable, Hashable {
  let id: String
  let title: String
  let rows: [WorkoutHistoryRow]
}

@MainActor
final class WorkoutsViewModel: ObservableObject {
  @Published var allCompletedWorkouts: [WorkoutSessionResponse] = []
  @Published var isLoading = true
  @Published var errorMessage: String?
  @Published var showFilterSheet = false
  @Published var appliedFilters = WorkoutHistoryFilters()
  @Published var draftFilters = WorkoutHistoryFilters()

  private let workoutsService: WorkoutsService
  let sessionStore: SessionStore

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
    self.workoutsService = WorkoutsService()
  }

  var summaryLabel: String {
    appliedFilters.hasActiveFilters ? "MATCHING WORKOUTS" : "TOTAL WORKOUTS"
  }

  var summaryCountText: String {
    groupedIntegerString(filteredRows.count)
  }

  var activeFilterCount: Int {
    appliedFilters.activeFilterCount
  }

  var hasWorkouts: Bool {
    !allCompletedWorkouts.isEmpty
  }

  var hasFilteredResults: Bool {
    !filteredRows.isEmpty
  }

  var availableMonthOptions: [WorkoutHistoryMonthOption] {
    var seenMonthKeys = Set<String>()
    var options: [WorkoutHistoryMonthOption] = []

    for workout in allCompletedWorkouts {
      let monthKey = Self.monthKey(for: workout.startTime)
      guard seenMonthKeys.insert(monthKey).inserted else { continue }
      options.append(
        WorkoutHistoryMonthOption(
          id: monthKey,
          label: Self.monthLabel(forMonthKey: monthKey)
        )
      )
    }

    return options
  }

  var availableLocations: [String] {
    let locations = Set(allCompletedWorkouts.map { normalizedLocationName(from: $0.locationName) })
    return locations.sorted { lhs, rhs in
      if lhs == Self.noLocationLabel { return true }
      if rhs == Self.noLocationLabel { return false }
      return lhs.localizedCaseInsensitiveCompare(rhs) == .orderedAscending
    }
  }

  var sections: [WorkoutHistorySection] {
    var order: [String] = []
    var rowsByMonth: [String: [WorkoutHistoryRow]] = [:]

    for row in filteredRows {
      if rowsByMonth[row.monthKey] == nil {
        order.append(row.monthKey)
        rowsByMonth[row.monthKey] = []
      }
      rowsByMonth[row.monthKey]?.append(row)
    }

    return order.map { monthKey in
      WorkoutHistorySection(
        id: monthKey,
        title: Self.sectionTitle(forMonthKey: monthKey),
        rows: rowsByMonth[monthKey] ?? []
      )
    }
  }

  var historyFooterText: String? {
    guard let oldestWorkout = allCompletedWorkouts.last else {
      return nil
    }

    return "Showing your fitness journey since \(Self.footerMonthLabel(for: oldestWorkout.startTime))"
  }

  func loadWorkoutHistory() async {
    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      let workouts = try await workoutsService.fetchWorkoutHistory()
      let completedWorkouts = Self.sortedCompletedWorkouts(
        workouts.filter { $0.endTime != nil }
      )

      allCompletedWorkouts = completedWorkouts
      let sanitizedFilters = sanitize(filters: appliedFilters)
      appliedFilters = sanitizedFilters
      draftFilters = sanitize(filters: draftFilters)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func presentFilterSheet() {
    draftFilters = appliedFilters
    showFilterSheet = true
  }

  func clearDraftFilters() {
    draftFilters = WorkoutHistoryFilters()
  }

  func applyDraftFilters() {
    appliedFilters = sanitize(filters: draftFilters)
    showFilterSheet = false
  }

  func cancelFilterSheet() {
    draftFilters = appliedFilters
    showFilterSheet = false
  }

  func resetDraftFiltersAfterDismiss() {
    draftFilters = appliedFilters
  }

  func clearAppliedFilters() {
    appliedFilters = WorkoutHistoryFilters()
    draftFilters = appliedFilters
  }

  func workoutSession(id: Int64) -> WorkoutSessionResponse? {
    allCompletedWorkouts.first { $0.id == id }
  }

  func applyUpdatedWorkout(_ updated: WorkoutSessionResponse) {
    guard let existingIndex = allCompletedWorkouts.firstIndex(where: { $0.id == updated.id }) else {
      return
    }

    allCompletedWorkouts[existingIndex] = updated
    allCompletedWorkouts = Self.sortedCompletedWorkouts(
      allCompletedWorkouts.filter { $0.endTime != nil }
    )
    appliedFilters = sanitize(filters: appliedFilters)
    draftFilters = sanitize(filters: draftFilters)
  }

  private static let noLocationLabel = "No location"

  private static let monthKeyFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM"
    return formatter
  }()

  private static let monthLabelFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMMM yyyy"
    return formatter
  }()

  private static let footerMonthFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM yyyy"
    return formatter
  }()

  private static let timestampFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "h:mm a"
    return formatter
  }()

  private static let monthSectionParser: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "yyyy-MM"
    return formatter
  }()

  private static func sortedCompletedWorkouts(
    _ workouts: [WorkoutSessionResponse]
  ) -> [WorkoutSessionResponse] {
    workouts.sorted {
      if $0.startTime == $1.startTime {
        return $0.id > $1.id
      }
      return $0.startTime > $1.startTime
    }
  }

  private var filteredRows: [WorkoutHistoryRow] {
    allHistoryRows.filter { row in
      if let monthKey = appliedFilters.selectedMonthKey, row.monthKey != monthKey {
        return false
      }

      if let workoutType = appliedFilters.selectedWorkoutType, row.type != workoutType {
        return false
      }

      if let location = appliedFilters.selectedLocation, row.locationLabel != location {
        return false
      }

      return true
    }
  }

  private var allHistoryRows: [WorkoutHistoryRow] {
    let workoutsDescending = allCompletedWorkouts
    let workoutsAscending = workoutsDescending.sorted {
      if $0.startTime == $1.startTime {
        return $0.id < $1.id
      }
      return $0.startTime < $1.startTime
    }

    var personalBests: [Int64: Double] = [:]
    var sessionsWithPersonalRecords = Set<Int64>()

    for workout in workoutsAscending {
      let sessionBestMetrics = sessionBestMetrics(for: workout)

      for (exerciseId, sessionBest) in sessionBestMetrics {
        if let priorBest = personalBests[exerciseId], sessionBest > priorBest {
          sessionsWithPersonalRecords.insert(workout.id)
        }
      }

      for (exerciseId, sessionBest) in sessionBestMetrics {
        let currentBest = personalBests[exerciseId] ?? sessionBest
        personalBests[exerciseId] = max(currentBest, sessionBest)
      }
    }

    return workoutsDescending.map { workout in
      WorkoutHistoryRow(
        id: workout.id,
        timestampLabel: timestampLabel(for: workout.startTime),
        title: normalizedTitle(from: workout.title),
        locationLabel: normalizedLocationName(from: workout.locationName),
        type: WorkoutSessionClassifier.workoutType(for: workout),
        hasPersonalRecord: sessionsWithPersonalRecords.contains(workout.id),
        durationText: formattedDuration(for: workout),
        exerciseCountText: "\(workout.workoutExercises.count)",
        volumeText: formattedVolume(for: workout),
        monthKey: Self.monthKey(for: workout.startTime)
      )
    }
  }

  private func sanitize(filters: WorkoutHistoryFilters) -> WorkoutHistoryFilters {
    guard !allCompletedWorkouts.isEmpty else {
      return WorkoutHistoryFilters()
    }

    var sanitized = filters
    let validMonthKeys = Set(availableMonthOptions.map(\.id))
    let validLocations = Set(availableLocations)

    if let selectedMonthKey = sanitized.selectedMonthKey, !validMonthKeys.contains(selectedMonthKey) {
      sanitized.selectedMonthKey = nil
    }

    if let selectedLocation = sanitized.selectedLocation, !validLocations.contains(selectedLocation) {
      sanitized.selectedLocation = nil
    }

    return sanitized
  }

  private func normalizedTitle(from title: String?) -> String {
    let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? "Workout" : trimmed
  }

  private func normalizedLocationName(from locationName: String?) -> String {
    let trimmed = locationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? Self.noLocationLabel : trimmed
  }

  private func timestampLabel(for date: Date) -> String {
    let calendar = Calendar.current
    let timeString = Self.timestampFormatter.string(from: date)

    if calendar.isDateInToday(date) {
      return "TODAY, \(timeString)"
    }

    if calendar.isDateInYesterday(date) {
      return "YESTERDAY, \(timeString)"
    }

    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM d, h:mm a"
    return formatter.string(from: date).uppercased()
  }

  private func formattedDuration(for workout: WorkoutSessionResponse) -> String {
    guard let endTime = workout.endTime else {
      return "0m"
    }

    let durationSeconds = max(Int(endTime.timeIntervalSince(workout.startTime)), 0)
    if durationSeconds == 0 {
      return "0m"
    }

    if durationSeconds < 60 {
      return "< 1m"
    }

    let totalMinutes = durationSeconds / 60
    let hours = totalMinutes / 60
    let minutes = totalMinutes % 60

    if hours == 0 {
      return "\(totalMinutes)m"
    }

    if minutes == 0 {
      return "\(hours)h"
    }

    return "\(hours)h \(minutes)m"
  }

  private func formattedVolume(for workout: WorkoutSessionResponse) -> String {
    let totalVolumeKgReps = workout.workoutExercises.reduce(0.0) { partialResult, workoutExercise in
      partialResult + workoutExercise.setLogs.reduce(0.0) { setTotal, setLog in
        setTotal + (Double(setLog.weight) * Double(setLog.reps))
      }
    }

    guard totalVolumeKgReps > 0 else {
      return "---"
    }

    let preferredUnit = sessionStore.userProfile?.preferredWeightUnit ?? .kg
    let displayVolume: Double
    if preferredUnit == .lb {
      displayVolume = totalVolumeKgReps * Double(UnitConverter.kgToLb(1.0))
    } else {
      displayVolume = totalVolumeKgReps
    }

    return "\(groupedIntegerString(displayVolume)) \(preferredUnit.abbreviation)"
  }

  private func sessionBestMetrics(for workout: WorkoutSessionResponse) -> [Int64: Double] {
    var bestsByExerciseId: [Int64: Double] = [:]

    for workoutExercise in workout.workoutExercises {
      let exerciseId = workoutExercise.exercise.id
      let metricValue = primaryMetricValue(for: workoutExercise)
      let currentBest = bestsByExerciseId[exerciseId] ?? metricValue
      bestsByExerciseId[exerciseId] = max(currentBest, metricValue)
    }

    return bestsByExerciseId
  }

  private func primaryMetricValue(for workoutExercise: WorkoutExerciseResponse) -> Double {
    switch workoutExercise.exercise.measurementType {
    case .reps:
      return Double(workoutExercise.setLogs.map(\.reps).max() ?? 0)
    case .time:
      return Double(workoutExercise.setLogs.compactMap(\.durationSeconds).max() ?? 0)
    case .repsAndTime:
      return Double(workoutExercise.setLogs.map(\.reps).max() ?? 0)
    case .timeAndWeight:
      return Double(workoutExercise.setLogs.map(\.weight).max() ?? 0)
    case .repsAndWeight:
      return Double(workoutExercise.setLogs.map(\.weight).max() ?? 0)
    case .distanceAndTime:
      return Double(workoutExercise.setLogs.map(\.distance).max() ?? 0)
    case .caloriesAndTime:
      return Double(workoutExercise.setLogs.map(\.calories).max() ?? 0)
    }
  }

  private func groupedIntegerString(_ value: Int) -> String {
    groupedIntegerString(Double(value))
  }

  private func groupedIntegerString(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.maximumFractionDigits = 0
    formatter.minimumFractionDigits = 0

    if let formattedValue = formatter.string(from: NSNumber(value: value.rounded())) {
      return formattedValue
    }

    return String(Int(value.rounded()))
  }

  private static func monthKey(for date: Date) -> String {
    monthKeyFormatter.string(from: date)
  }

  private static func monthLabel(forMonthKey monthKey: String) -> String {
    guard let date = monthSectionParser.date(from: monthKey) else {
      return monthKey
    }

    return monthLabelFormatter.string(from: date)
  }

  private static func sectionTitle(forMonthKey monthKey: String) -> String {
    monthLabel(forMonthKey: monthKey).uppercased()
  }

  private static func footerMonthLabel(for date: Date) -> String {
    footerMonthFormatter.string(from: date)
  }
}
