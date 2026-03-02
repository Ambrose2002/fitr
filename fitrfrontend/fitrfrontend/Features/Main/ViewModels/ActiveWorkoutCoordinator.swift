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
  let restTimerEndsAt: Date?
  let plannedExercises: [ActiveWorkoutPlannedExercise]

  var id: Int64 { workoutId }
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
      restTimerEndsAt: endDate,
      plannedExercises: activeContext.plannedExercises
    )
    setActiveContext(updatedContext, shouldPresent: false)
  }

  func finishActiveWorkout(notes: String?, title: String?) async throws -> WorkoutSessionResponse {
    guard let activeContext else {
      throw URLError(.badURL)
    }

    let response = try await workoutsService.updateWorkoutSession(
      id: activeContext.workoutId,
      request: CreateWorkoutSessionRequest(
        locationId: activeContext.locationId,
        notes: notes,
        endTime: ISO8601DateFormatter().string(from: Date()),
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
