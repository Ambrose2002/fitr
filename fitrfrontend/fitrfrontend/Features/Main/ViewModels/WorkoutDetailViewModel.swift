//
//  WorkoutDetailViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

internal import Combine
import Foundation
import SwiftUI

enum WorkoutDetailMode {
  case completed
  case inProgress(seed: WorkoutExecutionSeed?)

  var isCompleted: Bool {
    if case .completed = self {
      return true
    }
    return false
  }

  var isInProgress: Bool {
    !isCompleted
  }

  var seed: WorkoutExecutionSeed? {
    switch self {
    case .completed:
      return nil
    case .inProgress(let seed):
      return seed
    }
  }
}

struct WorkoutExecutionSeed {
  let planId: Int64
  let planDayId: Int64
  let planDayName: String
  let sessionTitle: String
  let locationName: String?
  let plannedExercises: [PlannedWorkoutExerciseSeed]
}

struct PlannedWorkoutExerciseSeed {
  let exerciseId: Int64
  let name: String
  let measurementType: MeasurementType
  let targetSets: Int
}

struct WorkoutDetailSummaryItem: Identifiable {
  let id: String
  let label: String
  let value: String
  let iconName: String
}

struct WorkoutDetailExerciseCard: Identifiable {
  let id: String
  let title: String
  let subtitle: String
  let avatarText: String
  let avatarTint: Color
  let columnHeaders: [String]
  let rows: [WorkoutDetailSetRow]
  let measurementType: MeasurementType
}

struct WorkoutDetailSetRow: Identifiable {
  let id: String
  let setLabel: String
  let metricValues: [String]
  let statusText: String
  let statusStyle: WorkoutDetailStatusStyle
}

enum WorkoutDetailStatusStyle {
  case done
  case pending
  case actionable
}

struct WorkoutDetailSharePayload {
  let text: String
}

@MainActor
final class WorkoutDetailViewModel: ObservableObject {
  @Published var workout: WorkoutSessionResponse?
  @Published var isLoading: Bool
  @Published var errorMessage: String?
  @Published var showEditSessionSheet = false
  @Published var editDraft = WorkoutSessionEditDraft()
  @Published var editBaselineDraft = WorkoutSessionEditDraft()
  @Published var availableLocations: [LocationResponse] = []
  @Published var isLoadingLocations = false
  @Published var isSavingSessionEdits = false
  @Published var locationLoadErrorMessage: String?
  @Published var sessionEditErrorMessage: String?
  @Published private var currentDate = Date()

  let workoutId: Int64
  let mode: WorkoutDetailMode

  private let sessionStore: SessionStore
  private let workoutsService: WorkoutsService
  private let locationsService: LocationsService
  private var hasLoaded = false
  private var hasLoadedLocationsForEditing = false
  private var elapsedTimer: AnyCancellable?

  init(
    sessionStore: SessionStore,
    workoutId: Int64,
    mode: WorkoutDetailMode,
    initialWorkout: WorkoutSessionResponse? = nil
  ) {
    self.sessionStore = sessionStore
    self.workoutId = workoutId
    self.mode = mode
    self.workout = initialWorkout
    self.isLoading = initialWorkout == nil
    self.workoutsService = WorkoutsService()
    self.locationsService = LocationsService()
    configureElapsedTimerIfNeeded()
  }

  deinit {
    elapsedTimer?.cancel()
  }

  var titleText: String {
    let trimmed = workout?.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmed.isEmpty {
      return trimmed
    }

    if let seedTitle = mode.seed?.sessionTitle.trimmingCharacters(in: .whitespacesAndNewlines),
      !seedTitle.isEmpty
    {
      return seedTitle
    }

    return "Workout"
  }

  var workoutType: WorkoutHistoryType {
    if let workout {
      return WorkoutSessionClassifier.workoutType(for: workout)
    }

    if case .inProgress(let seed?) = mode, !seed.plannedExercises.isEmpty {
      let uniqueTypes = Set(
        seed.plannedExercises.map { WorkoutHistoryType.modality(for: $0.measurementType) }
      )
      if uniqueTypes.count == 1, let onlyType = uniqueTypes.first {
        return onlyType
      }
      return .hybrid
    }

    return .strength
  }

  var badgeText: String {
    workoutType.badgeLabel
  }

  var sessionLabelText: String {
    "Session #\(workoutId)"
  }

  var summaryItems: [WorkoutDetailSummaryItem] {
    guard let workout else { return [] }

    return [
      WorkoutDetailSummaryItem(
        id: "date",
        label: "DATE",
        value: summaryDateText(for: workout.startTime),
        iconName: "calendar"
      ),
      WorkoutDetailSummaryItem(
        id: "time",
        label: "TIME",
        value: summaryDurationText(for: workout),
        iconName: "clock"
      ),
      WorkoutDetailSummaryItem(
        id: "gym",
        label: "GYM",
        value: normalizedLocationName(from: workout.locationName),
        iconName: "mappin.and.ellipse"
      ),
    ]
  }

  var notesText: String {
    let trimmed = workout?.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? "No notes recorded." : trimmed
  }

  var hasNotes: Bool {
    let trimmed = workout?.notes?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return !trimmed.isEmpty
  }

  var exerciseCountText: String {
    let count = exerciseCards.count
    return count == 1 ? "1 Exercise" : "\(count) Exercises"
  }

  var exerciseCards: [WorkoutDetailExerciseCard] {
    guard let workout else {
      return []
    }

    let workoutExercises = mode.isCompleted
      ? workout.includedExercisesForCompletedDisplay
      : workout.workoutExercises
    let plannedByExerciseId = Dictionary(
      uniqueKeysWithValues: (mode.seed?.plannedExercises ?? []).map { ($0.exerciseId, $0) }
    )
    let loggedCards = workoutExercises.map { workoutExercise in
      buildExerciseCard(
        workoutExercise: workoutExercise,
        plannedExercise: plannedByExerciseId[workoutExercise.exercise.id]
      )
    }

    guard case .inProgress(let seed?) = mode else {
      return loggedCards
    }

    let existingExerciseIds = Set(workout.workoutExercises.map(\.exercise.id))
    let pendingOnlyCards = seed.plannedExercises
      .filter { !existingExerciseIds.contains($0.exerciseId) }
      .map(buildPendingExerciseCard)

    return loggedCards + pendingOnlyCards
  }

  var sharePayload: WorkoutDetailSharePayload? {
    guard mode.isCompleted, let workout else {
      return nil
    }

    let lines = [
      titleText,
      "Date: \(summaryDateText(for: workout.startTime))",
      "Duration: \(summaryDurationText(for: workout))",
      "Location: \(normalizedLocationName(from: workout.locationName))",
      exerciseCountText,
    ]

    return WorkoutDetailSharePayload(text: lines.joined(separator: "\n"))
  }

  func loadIfNeeded() async {
    guard !hasLoaded else { return }
    hasLoaded = true
    await reload()
  }

  func reload() async {
    if workout == nil {
      isLoading = true
    }
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      workout = try await workoutsService.fetchWorkoutSession(id: workoutId)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func presentEditSession() {
    guard let workout else {
      return
    }

    let draft = WorkoutSessionEditDraft(workout: workout)
    editDraft = draft
    editBaselineDraft = draft
    sessionEditErrorMessage = nil
    showEditSessionSheet = true

    Task {
      await loadLocationsForEditingIfNeeded()
    }
  }

  func dismissEditSession() {
    showEditSessionSheet = false
    sessionEditErrorMessage = nil
  }

  func loadLocationsForEditingIfNeeded() async {
    guard !isLoadingLocations, !hasLoadedLocationsForEditing else {
      return
    }

    isLoadingLocations = true
    locationLoadErrorMessage = nil

    defer {
      isLoadingLocations = false
    }

    do {
      availableLocations = try await locationsService.fetchLocations()
      hasLoadedLocationsForEditing = true
    } catch {
      locationLoadErrorMessage = "Couldn't load saved locations. You can still update title and notes."
    }
  }

  func saveSessionEdits() async -> WorkoutSessionResponse? {
    guard !isSavingSessionEdits, let workout else {
      return nil
    }

    let trimmedTitle = editDraft.trimmedTitle
    guard !trimmedTitle.isEmpty else {
      sessionEditErrorMessage = "Enter a workout title."
      return nil
    }

    guard editDraft.hasChanges(comparedTo: editBaselineDraft) else {
      return nil
    }

    isSavingSessionEdits = true
    sessionEditErrorMessage = nil

    defer {
      isSavingSessionEdits = false
    }

    let trimmedNotes = editDraft.trimmedNotes

    do {
      let updatedWorkout = try await workoutsService.updateWorkoutSession(
        id: workout.id,
        request: CreateWorkoutSessionRequest(
          locationId: editDraft.selectedLocationId,
          notes: trimmedNotes.isEmpty ? "" : trimmedNotes,
          endTime: nil,
          title: trimmedTitle
        )
      )

      self.workout = updatedWorkout
      let updatedDraft = WorkoutSessionEditDraft(workout: updatedWorkout)
      editDraft = updatedDraft
      editBaselineDraft = updatedDraft
      sessionEditErrorMessage = nil
      showEditSessionSheet = false
      return updatedWorkout
    } catch let apiError as APIErrorResponse {
      sessionEditErrorMessage = apiError.message
      return nil
    } catch {
      sessionEditErrorMessage = "Failed to save your changes."
      return nil
    }
  }

  private func configureElapsedTimerIfNeeded() {
    guard mode.isInProgress else { return }

    elapsedTimer = Timer.publish(every: 1, on: .main, in: .common)
      .autoconnect()
      .sink { [weak self] now in
        self?.currentDate = now
      }
  }

  private func buildExerciseCard(
    workoutExercise: WorkoutExerciseResponse,
    plannedExercise: PlannedWorkoutExerciseSeed?
  ) -> WorkoutDetailExerciseCard {
    let sortedLogs = workoutExercise.setLogs.sorted {
      if $0.setNumber == $1.setNumber {
        return $0.id < $1.id
      }
      return $0.setNumber < $1.setNumber
    }
    let columnHeaders = metricColumnHeaders(for: workoutExercise.exercise.measurementType)
    var rows = sortedLogs.map { setLog in
      WorkoutDetailSetRow(
        id: "log-\(setLog.id)",
        setLabel: "\(setLog.setNumber)",
        metricValues: metricValues(for: setLog, measurementType: workoutExercise.exercise.measurementType),
        statusText: "DONE",
        statusStyle: .done
      )
    }

    if mode.isInProgress {
      let loggedCount = sortedLogs.count
      let targetSets = max(plannedExercise?.targetSets ?? loggedCount, loggedCount)

      if targetSets > loggedCount {
        rows.append(
          contentsOf: ((loggedCount + 1)...targetSets).map { setNumber in
            WorkoutDetailSetRow(
              id: "pending-\(workoutExercise.exercise.id)-\(setNumber)",
              setLabel: "\(setNumber)",
              metricValues: Array(repeating: "--", count: columnHeaders.count),
              statusText: "LOG SET",
              statusStyle: .actionable
            )
          }
        )
      }
    }

    return WorkoutDetailExerciseCard(
      id: "exercise-\(workoutExercise.id)",
      title: workoutExercise.exercise.name,
      subtitle: workoutExercise.exercise.measurementType.workoutDisplayLabel,
      avatarText: avatarText(for: workoutExercise.exercise.name),
      avatarTint: avatarTint(for: workoutExercise.exercise.measurementType),
      columnHeaders: columnHeaders,
      rows: rows,
      measurementType: workoutExercise.exercise.measurementType
    )
  }

  private func buildPendingExerciseCard(_ plannedExercise: PlannedWorkoutExerciseSeed)
    -> WorkoutDetailExerciseCard
  {
    let columnHeaders = metricColumnHeaders(for: plannedExercise.measurementType)
    let rows = (1...max(plannedExercise.targetSets, 1)).map { setNumber in
      WorkoutDetailSetRow(
        id: "pending-\(plannedExercise.exerciseId)-\(setNumber)",
        setLabel: "\(setNumber)",
        metricValues: Array(repeating: "--", count: columnHeaders.count),
        statusText: "LOG SET",
        statusStyle: .actionable
      )
    }

    return WorkoutDetailExerciseCard(
      id: "seed-\(plannedExercise.exerciseId)",
      title: plannedExercise.name,
      subtitle: plannedExercise.measurementType.workoutDisplayLabel,
      avatarText: avatarText(for: plannedExercise.name),
      avatarTint: avatarTint(for: plannedExercise.measurementType),
      columnHeaders: columnHeaders,
      rows: rows,
      measurementType: plannedExercise.measurementType
    )
  }

  private func metricColumnHeaders(for measurementType: MeasurementType) -> [String] {
    switch measurementType {
    case .reps:
      return ["REPS"]
    case .time:
      return ["TIME (min)"]
    case .repsAndTime:
      return ["REPS", "TIME (min)"]
    case .repsAndWeight:
      return [preferredWeightUnit.abbreviation.uppercased(), "REPS"]
    case .timeAndWeight:
      return [preferredWeightUnit.abbreviation.uppercased(), "TIME (min)"]
    case .distanceAndTime:
      return [preferredDistanceUnit.abbreviation.uppercased(), "TIME (min)"]
    case .caloriesAndTime:
      return ["CAL", "TIME (min)"]
    }
  }

  private func metricValues(for setLog: SetLogResponse, measurementType: MeasurementType) -> [String] {
    switch measurementType {
    case .reps:
      return ["\(setLog.reps)"]
    case .time:
      return [formattedDurationValue(setLog.durationSeconds)]
    case .repsAndTime:
      return ["\(setLog.reps)", formattedDurationValue(setLog.durationSeconds)]
    case .repsAndWeight:
      return [formattedWeightValue(setLog.weight), "\(setLog.reps)"]
    case .timeAndWeight:
      return [formattedWeightValue(setLog.weight), formattedDurationValue(setLog.durationSeconds)]
    case .distanceAndTime:
      return [formattedDistanceValue(setLog.distance), formattedDurationValue(setLog.durationSeconds)]
    case .caloriesAndTime:
      return [formattedCaloriesValue(setLog.calories), formattedDurationValue(setLog.durationSeconds)]
    }
  }

  private func formattedWeightValue(_ kg: Float) -> String {
    let displayValue = preferredWeightUnit == .kg ? kg : UnitConverter.kgToLb(kg)
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
  }

  private func formattedDistanceValue(_ km: Float) -> String {
    let displayValue = preferredDistanceUnit == .km ? km : UnitConverter.kmToMi(km)
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 2)
  }

  private func formattedCaloriesValue(_ calories: Float) -> String {
    UnitFormatter.formatValue(calories, decimalPlaces: 0)
  }

  private func formattedDurationValue(_ durationSeconds: Int64?) -> String {
    guard let durationSeconds else {
      return "--"
    }
    return DurationFormatter.minutesString(from: Int(durationSeconds))
  }

  private func summaryDateText(for date: Date) -> String {
    Self.summaryDateFormatter.string(from: date)
  }

  private func summaryDurationText(for workout: WorkoutSessionResponse) -> String {
    let endDate: Date
    switch mode {
    case .completed:
      endDate = workout.endTime ?? workout.startTime
    case .inProgress:
      endDate = workout.endTime ?? currentDate
    }

    return formattedSummaryDuration(
      startTime: workout.startTime,
      endTime: endDate
    )
  }

  private func formattedSummaryDuration(startTime: Date, endTime: Date) -> String {
    let durationSeconds = max(Int(endTime.timeIntervalSince(startTime)), 0)
    if durationSeconds == 0 {
      return "0m"
    }

    let hours = durationSeconds / 3600
    let minutes = (durationSeconds % 3600) / 60
    let seconds = durationSeconds % 60

    if hours > 0 {
      return "\(hours)h \(String(format: "%02d", minutes))m"
    }

    if minutes == 0 {
      return "\(seconds)s"
    }

    if seconds == 0 {
      return "\(minutes)m"
    }

    return "\(minutes)m \(seconds)s"
  }

  private func normalizedLocationName(from locationName: String?) -> String {
    let trimmed = locationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if !trimmed.isEmpty {
      return trimmed
    }

    let seedLocation = mode.seed?.locationName?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return seedLocation.isEmpty ? "No location" : seedLocation
  }

  private func avatarText(for name: String) -> String {
    let letters = name
      .split(whereSeparator: { !$0.isLetter })
      .prefix(2)
      .compactMap { $0.first.map(String.init) }
      .joined()
      .uppercased()

    if !letters.isEmpty {
      return letters
    }

    let fallbackLetters = name
      .filter(\.isLetter)
      .prefix(2)
      .uppercased()

    return String(fallbackLetters)
  }

  private func avatarTint(for measurementType: MeasurementType) -> Color {
    switch WorkoutHistoryType.modality(for: measurementType) {
    case .strength:
      return AppColors.accent
    case .cardio:
      return AppColors.infoBlue
    case .hybrid:
      return AppColors.warningYellow
    }
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  private static let summaryDateFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM d"
    return formatter
  }()
}
