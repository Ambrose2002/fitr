//
//  ActiveWorkoutCoordinator.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/2/26.
//

internal import Combine
import Foundation

struct WorkoutExecutionOrigin: Codable, Equatable {
  enum Kind: String, Codable {
    case planned
    case adHoc
  }

  let kind: Kind
  let planId: Int64?
  let planDayId: Int64?
  let planName: String?
  let planDayName: String?

  static func planned(
    planId: Int64,
    planDayId: Int64,
    planName: String,
    planDayName: String
  ) -> WorkoutExecutionOrigin {
    WorkoutExecutionOrigin(
      kind: .planned,
      planId: planId,
      planDayId: planDayId,
      planName: planName,
      planDayName: planDayName
    )
  }

  static let adHoc = WorkoutExecutionOrigin(
    kind: .adHoc,
    planId: nil,
    planDayId: nil,
    planName: nil,
    planDayName: nil
  )

  var isPlanned: Bool {
    kind == .planned
  }
}

enum LiveWorkoutExerciseSource: String, Codable {
  case planned
  case adHoc
}

struct LiveWorkoutTargetTemplate: Codable, Equatable {
  let sets: Int
  let reps: Int
  let weight: Float
  let durationSeconds: Int
  let distance: Float
  let calories: Float
}

struct ActiveWorkoutPlannedExercise: Codable, Equatable, Identifiable {
  let id: Int64
  let exerciseId: Int64
  let name: String
  let measurementType: MeasurementType
  let source: LiveWorkoutExerciseSource
  let targetTemplate: LiveWorkoutTargetTemplate?
}

struct ActiveWorkoutContext: Codable, Equatable, Identifiable {
  let workoutId: Int64
  let origin: WorkoutExecutionOrigin
  let sessionTitle: String
  let locationId: Int64?
  let locationName: String?
  let startedAt: Date
  let isPaused: Bool
  let pausedAt: Date?
  let pausedDurationSeconds: Double
  let restTimerEndsAt: Date?
  let plannedExercises: [ActiveWorkoutPlannedExercise]

  var id: Int64 { workoutId }

  enum CodingKeys: String, CodingKey {
    case workoutId
    case origin
    case sessionTitle
    case locationId
    case locationName
    case startedAt
    case isPaused
    case pausedAt
    case pausedDurationSeconds
    case restTimerEndsAt
    case plannedExercises
  }

  init(
    workoutId: Int64,
    origin: WorkoutExecutionOrigin,
    sessionTitle: String,
    locationId: Int64?,
    locationName: String?,
    startedAt: Date,
    isPaused: Bool,
    pausedAt: Date?,
    pausedDurationSeconds: Double,
    restTimerEndsAt: Date?,
    plannedExercises: [ActiveWorkoutPlannedExercise]
  ) {
    self.workoutId = workoutId
    self.origin = origin
    self.sessionTitle = sessionTitle
    self.locationId = locationId
    self.locationName = locationName
    self.startedAt = startedAt
    self.isPaused = isPaused
    self.pausedAt = pausedAt
    self.pausedDurationSeconds = pausedDurationSeconds
    self.restTimerEndsAt = restTimerEndsAt
    self.plannedExercises = plannedExercises
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    workoutId = try container.decode(Int64.self, forKey: .workoutId)
    origin = try container.decode(WorkoutExecutionOrigin.self, forKey: .origin)
    sessionTitle = try container.decode(String.self, forKey: .sessionTitle)
    locationId = try container.decodeIfPresent(Int64.self, forKey: .locationId)
    locationName = try container.decodeIfPresent(String.self, forKey: .locationName)
    startedAt = try container.decode(Date.self, forKey: .startedAt)
    isPaused = try container.decode(Bool.self, forKey: .isPaused)
    pausedAt = try container.decodeIfPresent(Date.self, forKey: .pausedAt)
    pausedDurationSeconds =
      try container.decodeIfPresent(Double.self, forKey: .pausedDurationSeconds) ?? 0
    restTimerEndsAt = try container.decodeIfPresent(Date.self, forKey: .restTimerEndsAt)
    plannedExercises =
      try container.decodeIfPresent([ActiveWorkoutPlannedExercise].self, forKey: .plannedExercises)
      ?? []
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(workoutId, forKey: .workoutId)
    try container.encode(origin, forKey: .origin)
    try container.encode(sessionTitle, forKey: .sessionTitle)
    try container.encodeIfPresent(locationId, forKey: .locationId)
    try container.encodeIfPresent(locationName, forKey: .locationName)
    try container.encode(startedAt, forKey: .startedAt)
    try container.encode(isPaused, forKey: .isPaused)
    try container.encodeIfPresent(pausedAt, forKey: .pausedAt)
    try container.encode(pausedDurationSeconds, forKey: .pausedDurationSeconds)
    try container.encodeIfPresent(restTimerEndsAt, forKey: .restTimerEndsAt)
    try container.encode(plannedExercises, forKey: .plannedExercises)
  }
}

@MainActor
final class ActiveWorkoutCoordinator: ObservableObject {
  @Published private(set) var activeContext: ActiveWorkoutContext?
  @Published var presentedContext: ActiveWorkoutContext?

  private let userDefaults = UserDefaults.standard
  private let storageKey = "activeWorkoutContext"
  private let workoutsService = WorkoutsService()

  init() {
    restorePersistedContext()
  }

  func beginAdHocWorkout() async throws {
    let title = "Quick Start Workout"
    let workout = try await workoutsService.createWorkoutSession(
      request: CreateWorkoutSessionRequest(
        locationId: nil,
        notes: nil,
        endTime: nil,
        title: title
      ))

    let context = ActiveWorkoutContext(
      workoutId: workout.id,
      origin: .adHoc,
      sessionTitle: normalizedTitle(from: workout.title, fallback: title),
      locationId: workout.workoutLocationId,
      locationName: workout.locationName,
      startedAt: workout.startTime,
      isPaused: false,
      pausedAt: nil,
      pausedDurationSeconds: 0,
      restTimerEndsAt: nil,
      plannedExercises: []
    )

    setActiveContext(context, shouldPresent: true)
  }

  func beginPlannedWorkout(
    planId: Int64,
    planName: String,
    planDayId: Int64,
    planDayName: String,
    plannedExercises: [ActiveWorkoutPlannedExercise]
  ) async throws {
    let title = planDayName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? "Planned Workout"
      : planDayName
    let workout = try await workoutsService.createWorkoutSession(
      request: CreateWorkoutSessionRequest(
        locationId: nil,
        notes: nil,
        endTime: nil,
        title: title
      ))

    do {
      for plannedExercise in plannedExercises {
        _ = try await workoutsService.addWorkoutExercise(
          workoutId: workout.id,
          request: CreateWorkoutExerciseRequest(exerciseId: plannedExercise.exerciseId)
        )
      }
    } catch {
      try? await workoutsService.deleteWorkoutSession(id: workout.id)
      throw error
    }

    let context = ActiveWorkoutContext(
      workoutId: workout.id,
      origin: .planned(
        planId: planId,
        planDayId: planDayId,
        planName: planName,
        planDayName: planDayName
      ),
      sessionTitle: normalizedTitle(from: workout.title, fallback: title),
      locationId: workout.workoutLocationId,
      locationName: workout.locationName,
      startedAt: workout.startTime,
      isPaused: false,
      pausedAt: nil,
      pausedDurationSeconds: 0,
      restTimerEndsAt: nil,
      plannedExercises: plannedExercises
    )

    setActiveContext(context, shouldPresent: true)
  }

  func restoreRemoteActiveWorkoutIfNeeded() async {
    do {
      let remoteWorkout = try await workoutsService.fetchActiveWorkout()
      guard let remoteWorkout else {
        if activeContext != nil {
          clearStoredContext()
        }
        return
      }

      if let existingContext = activeContext, existingContext.workoutId == remoteWorkout.id {
        let synced = ActiveWorkoutContext(
          workoutId: existingContext.workoutId,
          origin: existingContext.origin,
          sessionTitle: normalizedTitle(from: remoteWorkout.title, fallback: existingContext.sessionTitle),
          locationId: remoteWorkout.workoutLocationId,
          locationName: remoteWorkout.locationName,
          startedAt: remoteWorkout.startTime,
          isPaused: existingContext.isPaused,
          pausedAt: existingContext.pausedAt,
          pausedDurationSeconds: existingContext.pausedDurationSeconds,
          restTimerEndsAt: existingContext.restTimerEndsAt,
          plannedExercises: existingContext.plannedExercises
        )
        setActiveContext(synced, shouldPresent: presentedContext != nil)
      } else {
        let restored = ActiveWorkoutContext(
          workoutId: remoteWorkout.id,
          origin: .adHoc,
          sessionTitle: normalizedTitle(from: remoteWorkout.title, fallback: "Active Workout"),
          locationId: remoteWorkout.workoutLocationId,
          locationName: remoteWorkout.locationName,
          startedAt: remoteWorkout.startTime,
          isPaused: false,
          pausedAt: nil,
          pausedDurationSeconds: 0,
          restTimerEndsAt: nil,
          plannedExercises: []
        )
        let shouldPresent = presentedContext != nil || activeContext == nil
        setActiveContext(restored, shouldPresent: shouldPresent)
      }
    } catch {
      // Ignore restore failures and keep the last local state.
    }
  }

  func presentActiveWorkout() {
    guard let activeContext else {
      return
    }
    presentedContext = activeContext
  }

  func dismissPresentedWorkout() {
    presentedContext = nil
  }

  func updateRestTimer(endDate: Date?) {
    guard let activeContext else {
      return
    }

    let updatedContext = ActiveWorkoutContext(
      workoutId: activeContext.workoutId,
      origin: activeContext.origin,
      sessionTitle: activeContext.sessionTitle,
      locationId: activeContext.locationId,
      locationName: activeContext.locationName,
      startedAt: activeContext.startedAt,
      isPaused: activeContext.isPaused,
      pausedAt: activeContext.pausedAt,
      pausedDurationSeconds: activeContext.pausedDurationSeconds,
      restTimerEndsAt: endDate,
      plannedExercises: activeContext.plannedExercises
    )
    setActiveContext(updatedContext, shouldPresent: false)
  }

  func applyEditedSession(_ workout: WorkoutSessionResponse) {
    guard let activeContext, activeContext.workoutId == workout.id else {
      return
    }

    let updatedContext = ActiveWorkoutContext(
      workoutId: activeContext.workoutId,
      origin: activeContext.origin,
      sessionTitle: normalizedTitle(from: workout.title, fallback: activeContext.sessionTitle),
      locationId: workout.workoutLocationId,
      locationName: workout.locationName,
      startedAt: activeContext.startedAt,
      isPaused: activeContext.isPaused,
      pausedAt: activeContext.pausedAt,
      pausedDurationSeconds: activeContext.pausedDurationSeconds,
      restTimerEndsAt: activeContext.restTimerEndsAt,
      plannedExercises: activeContext.plannedExercises
    )
    setActiveContext(updatedContext, shouldPresent: false)
  }

  func syncSessionTimerState(
    isPaused: Bool,
    pausedAt: Date?,
    pausedDurationSeconds: Double
  ) {
    guard let activeContext else {
      return
    }

    let updatedContext = ActiveWorkoutContext(
      workoutId: activeContext.workoutId,
      origin: activeContext.origin,
      sessionTitle: activeContext.sessionTitle,
      locationId: activeContext.locationId,
      locationName: activeContext.locationName,
      startedAt: activeContext.startedAt,
      isPaused: isPaused,
      pausedAt: pausedAt,
      pausedDurationSeconds: pausedDurationSeconds,
      restTimerEndsAt: activeContext.restTimerEndsAt,
      plannedExercises: activeContext.plannedExercises
    )
    setActiveContext(updatedContext, shouldPresent: false)
  }

  func finishActiveWorkout(
    notes: String?,
    title: String?,
    locationId: Int64?
  ) async throws -> WorkoutSessionResponse {
    guard let activeContext else {
      throw URLError(.badURL)
    }

    let finishTimestamp = Date()
    let effectiveEndDate = activeContext.startedAt.addingTimeInterval(
      effectiveElapsedSeconds(for: activeContext, asOf: finishTimestamp)
    )

    let response = try await workoutsService.updateWorkoutSession(
      id: activeContext.workoutId,
      request: CreateWorkoutSessionRequest(
        locationId: locationId,
        notes: notes,
        endTime: ISO8601DateFormatter().string(from: effectiveEndDate),
        title: title
      ))
    return response
  }

  func completeFinishedWorkout() {
    clearStoredContext()
  }

  func discardActiveWorkout() async throws {
    guard let activeContext else {
      return
    }

    try await workoutsService.deleteWorkoutSession(id: activeContext.workoutId)
    clearStoredContext()
  }

  func resetLocalState() {
    clearStoredContext()
  }

  private func effectiveElapsedSeconds(for context: ActiveWorkoutContext, asOf now: Date) -> Double {
    let wallClockElapsed = now.timeIntervalSince(context.startedAt)
    let currentPauseSeconds: Double

    if context.isPaused, let pausedAt = context.pausedAt {
      currentPauseSeconds = max(now.timeIntervalSince(pausedAt), 0)
    } else {
      currentPauseSeconds = 0
    }

    return max(0, wallClockElapsed - context.pausedDurationSeconds - currentPauseSeconds)
  }

  private func normalizedTitle(from title: String?, fallback: String) -> String {
    let trimmed = title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    return trimmed.isEmpty ? fallback : trimmed
  }

  private func restorePersistedContext() {
    guard let data = userDefaults.data(forKey: storageKey) else {
      return
    }

    do {
      let decoded = try JSONDecoder().decode(ActiveWorkoutContext.self, from: data)
      activeContext = decoded
      presentedContext = decoded
    } catch {
      userDefaults.removeObject(forKey: storageKey)
    }
  }

  private func persistContext(_ context: ActiveWorkoutContext?) {
    guard let context else {
      userDefaults.removeObject(forKey: storageKey)
      return
    }

    do {
      let encoded = try JSONEncoder().encode(context)
      userDefaults.set(encoded, forKey: storageKey)
    } catch {
      userDefaults.removeObject(forKey: storageKey)
    }
  }

  private func setActiveContext(_ context: ActiveWorkoutContext, shouldPresent: Bool) {
    activeContext = context
    persistContext(context)
    if shouldPresent {
      presentedContext = context
    } else if presentedContext?.workoutId == context.workoutId {
      presentedContext = context
    }
  }

  private func clearStoredContext() {
    activeContext = nil
    presentedContext = nil
    persistContext(nil)
  }
}
