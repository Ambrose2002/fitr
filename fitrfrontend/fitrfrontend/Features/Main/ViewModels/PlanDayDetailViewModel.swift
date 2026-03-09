//
//  PlanDayDetailViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/25/26.
//

internal import Combine
import Foundation

struct PlanExerciseTargets {
  let sets: Int
  let reps: Int
  let durationSeconds: Int
  let distance: Float
  let calories: Float
  let weight: Float
}

struct PlanDayDetailSnapshot {
  let exercises: [EnrichedPlanExercise]
  let availableExercises: [ExerciseResponse]
}

@MainActor
final class PlanDayDetailViewModel: ObservableObject {
  @Published var exercises: [EnrichedPlanExercise] = []
  @Published var availableExercises: [ExerciseResponse] = []
  @Published var isLoading = false
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published var errorMessage: String?
  @Published var showAddExerciseSheet = false
  @Published var showDeleteDayConfirmation = false
  @Published var showRemoveConfirmation = false
  @Published var pendingRemoveExercise: EnrichedPlanExercise?
  @Published var didDeleteDay = false

  let planId: Int64
  let dayId: Int64
  let dayName: String
  let dayNumber: Int

  private let sessionStore: SessionStore
  private let workoutPlanService = WorkoutPlanService()
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(
    planId: Int64,
    dayId: Int64,
    dayName: String,
    dayNumber: Int,
    sessionStore: SessionStore
  ) {
    self.planId = planId
    self.dayId = dayId
    self.dayName = dayName
    self.dayNumber = dayNumber
    self.sessionStore = sessionStore
    restoreSnapshotIfAvailable()
  }

  var exerciseCount: Int {
    exercises.count
  }

  var estimatedDurationSeconds: Int {
    WorkoutDurationEstimator.estimatedDurationSeconds(for: exercises)
  }

  var estimatedMinutes: Int {
    WorkoutDurationEstimator.estimatedMinutes(for: exercises)
  }

  var weekday: WorkoutWeekday? {
    WorkoutWeekday.from(dayNumber: dayNumber)
  }

  var weekdayName: String {
    weekday?.fullName ?? "Day \(dayNumber)"
  }

  var existingExerciseIds: Set<Int64> {
    Set(exercises.map(\.exerciseId))
  }

  func load(forceRefresh: Bool = false) async {
    guard !isFetching else {
      return
    }

    restoreSnapshotIfNewer()

    if
      !forceRefresh,
      let lastLoadedAt,
      Date().timeIntervalSince(lastLoadedAt) < freshnessInterval
    {
      return
    }

    let shouldBlockUI = !hasLoadedSnapshot
    isFetching = true
    if shouldBlockUI {
      isLoading = true
    } else {
      isRefreshing = true
    }
    errorMessage = nil

    defer {
      isFetching = false
      if shouldBlockUI {
        isLoading = false
      } else {
        isRefreshing = false
      }
    }

    do {
      let fetchedExercises = try await workoutPlanService.getExercises(dayId: dayId)
      let exerciseCatalog = try await workoutPlanService.getAllExercises(systemOnly: false)
      let lookup = Dictionary(uniqueKeysWithValues: exerciseCatalog.map { ($0.id, $0) })

      availableExercises = exerciseCatalog
      exercises = fetchedExercises.map { response in
        let meta = lookup[response.exerciseId]
        return EnrichedPlanExercise(
          id: response.id,
          planDayId: response.planDayId,
          exerciseId: response.exerciseId,
          name: meta?.name ?? "Exercise \(response.exerciseId)",
          measurementType: meta?.measurementType,
          targetSets: response.targetSets,
          targetReps: response.targetReps,
          targetDurationSeconds: response.targetDurationSeconds,
          targetDistance: response.targetDistance,
          targetCalories: response.targetCalories,
          targetWeight: response.targetWeight ?? 0
        )
      }
      let loadedAt = Date()
      persistSnapshot(loadedAt: loadedAt)
      syncPlanDetailSnapshot(loadedAt: loadedAt)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      if error.isCancellation {
        return
      }
      errorMessage = "Failed to load plan day exercises."
    }
  }

  func addExercise(exercise: ExerciseResponse, targets: PlanExerciseTargets) async {
    guard !existingExerciseIds.contains(exercise.id) else {
      errorMessage = "This exercise is already added to this workout day."
      return
    }

    do {
      let request = CreatePlanDayExerciseRequest(
        exerciseId: exercise.id,
        targetSets: targets.sets,
        targetReps: targets.reps,
        targetDurationSeconds: targets.durationSeconds,
        targetDistance: targets.distance,
        targetCalories: targets.calories,
        targetWeight: targets.weight
      )

      let response = try await workoutPlanService.addExerciseToDay(dayId: dayId, request: request)
      let newExercise = EnrichedPlanExercise(
        id: response.id,
        planDayId: response.planDayId,
        exerciseId: response.exerciseId,
        name: exercise.name,
        measurementType: exercise.measurementType,
        targetSets: response.targetSets,
        targetReps: response.targetReps,
        targetDurationSeconds: response.targetDurationSeconds,
        targetDistance: response.targetDistance,
        targetCalories: response.targetCalories,
        targetWeight: response.targetWeight ?? targets.weight
      )
      exercises.append(newExercise)
      let loadedAt = Date()
      persistSnapshot(loadedAt: loadedAt)
      syncPlanDetailSnapshot(loadedAt: loadedAt)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to add exercise."
    }
  }

  func updateExercise(
    planExerciseId: Int64,
    catalogExerciseId: Int64,
    targetSets: Int,
    targetReps: Int,
    targetDurationSeconds: Int,
    targetDistance: Float,
    targetCalories: Float,
    targetWeight: Float
  ) async {
    let sets = targetSets
    let reps = targetReps
    let durationSeconds = targetDurationSeconds
    let distance = targetDistance
    let calories = targetCalories
    let weight = targetWeight

    let maxSets = 30
    let maxReps = 200
    let maxDurationSeconds = 21_600

    guard let index = exercises.firstIndex(where: { $0.id == planExerciseId }) else {
      errorMessage = "Exercise not found."
      return
    }

    let existingExercise = exercises[index]

    guard (1...maxSets).contains(sets) else {
      errorMessage = "Invalid exercise targets."
      return
    }

    var sanitizedReps = 0
    var sanitizedDurationSeconds = 0
    var sanitizedDistance: Float = 0
    var sanitizedCalories: Float = 0
    var sanitizedWeight: Float = 0

    switch existingExercise.measurementType {
    case .reps:
      guard (1...maxReps).contains(reps) else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedReps = reps

    case .time:
      guard (1...maxDurationSeconds).contains(durationSeconds) else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedDurationSeconds = durationSeconds

    case .repsAndTime:
      guard (1...maxReps).contains(reps), (1...maxDurationSeconds).contains(durationSeconds) else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedReps = reps
      sanitizedDurationSeconds = durationSeconds

    case .repsAndWeight:
      guard (1...maxReps).contains(reps), weight.isFinite, weight > 0 else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedReps = reps
      sanitizedWeight = weight

    case .timeAndWeight:
      guard (1...maxDurationSeconds).contains(durationSeconds), weight.isFinite, weight > 0 else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedDurationSeconds = durationSeconds
      sanitizedWeight = weight

    case .distanceAndTime:
      guard
        (1...maxDurationSeconds).contains(durationSeconds),
        distance.isFinite,
        distance > 0
      else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedDurationSeconds = durationSeconds
      sanitizedDistance = distance

    case .caloriesAndTime:
      guard
        (1...maxDurationSeconds).contains(durationSeconds),
        calories.isFinite,
        calories > 0
      else {
        errorMessage = "Invalid exercise targets."
        return
      }
      sanitizedDurationSeconds = durationSeconds
      sanitizedCalories = calories

    case .none:
      break
    }

    do {
      let response = try await workoutPlanService.updateDayExercise(
        dayId: dayId,
        planExerciseId: planExerciseId,
        catalogExerciseId: catalogExerciseId,
        targetSets: sets,
        targetReps: sanitizedReps,
        targetDurationSeconds: sanitizedDurationSeconds,
        targetDistance: sanitizedDistance,
        targetCalories: sanitizedCalories,
        targetWeight: sanitizedWeight
      )

      exercises[index] = EnrichedPlanExercise(
        id: response.id,
        planDayId: response.planDayId,
        exerciseId: response.exerciseId,
        name: existingExercise.name,
        measurementType: existingExercise.measurementType,
        targetSets: response.targetSets,
        targetReps: response.targetReps,
        targetDurationSeconds: response.targetDurationSeconds,
        targetDistance: response.targetDistance,
        targetCalories: response.targetCalories,
        targetWeight: response.targetWeight ?? sanitizedWeight
      )
      let loadedAt = Date()
      persistSnapshot(loadedAt: loadedAt)
      syncPlanDetailSnapshot(loadedAt: loadedAt)
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to update exercise."
    }
  }

  func requestRemove(_ exercise: EnrichedPlanExercise) {
    pendingRemoveExercise = exercise
    showRemoveConfirmation = true
  }

  func confirmRemove() async {
    guard let exercise = pendingRemoveExercise else { return }

    do {
      try await workoutPlanService.deleteDayExercise(dayId: dayId, exerciseId: exercise.id)
      exercises.removeAll { $0.id == exercise.id }
      let loadedAt = Date()
      persistSnapshot(loadedAt: loadedAt)
      syncPlanDetailSnapshot(loadedAt: loadedAt)
    } catch {
      errorMessage = "Failed to remove exercise."
    }
  }

  func deleteDay() async {
    do {
      try await workoutPlanService.deletePlanDay(planId: planId, dayId: dayId)
      sessionStore.runtimeViewCache.remove(.planDayDetail(dayId))
      removeDayFromPlanDetailSnapshot(loadedAt: Date())
      didDeleteDay = true
    } catch {
      errorMessage = "Failed to delete workout day."
    }
  }

  private func persistSnapshot(loadedAt: Date) {
    let snapshot = PlanDayDetailSnapshot(
      exercises: exercises,
      availableExercises: availableExercises
    )
    hasLoadedSnapshot = true
    lastLoadedAt = loadedAt
    sessionStore.runtimeViewCache.store(snapshot, for: .planDayDetail(dayId), at: loadedAt)
  }

  private func restoreSnapshotIfAvailable() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDayDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDayDetail(dayId), as: PlanDayDetailSnapshot.self)
    else {
      return
    }

    exercises = snapshot.value.exercises
    availableExercises = snapshot.value.availableExercises
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
    isLoading = false
  }

  private func restoreSnapshotIfNewer() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDayDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDayDetail(dayId), as: PlanDayDetailSnapshot.self)
    else {
      return
    }

    if let lastLoadedAt, snapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    exercises = snapshot.value.exercises
    availableExercises = snapshot.value.availableExercises
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
  }

  private func syncPlanDetailSnapshot(loadedAt: Date) {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDetail(planId), as: PlanDetailSnapshot.self)
    else {
      return
    }

    let updatedDays = snapshot.value.enrichedDays.map { day in
      guard day.id == dayId else {
        return day
      }

      return EnrichedPlanDay(
        id: day.id,
        dayNumber: day.dayNumber,
        name: day.name,
        exercises: exercises
      )
    }

    let updatedSnapshot = PlanDetailSnapshot(
      planDetail: snapshot.value.planDetail,
      enrichedDays: updatedDays,
      isActiveToggle: snapshot.value.isActiveToggle
    )
    sessionStore.runtimeViewCache.store(updatedSnapshot, for: .planDetail(planId), at: loadedAt)
  }

  private func removeDayFromPlanDetailSnapshot(loadedAt: Date) {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDetail(planId), as: PlanDetailSnapshot.self)
    else {
      return
    }

    let updatedDays = snapshot.value.enrichedDays.filter { $0.id != dayId }
    let updatedSnapshot = PlanDetailSnapshot(
      planDetail: snapshot.value.planDetail,
      enrichedDays: updatedDays,
      isActiveToggle: snapshot.value.isActiveToggle
    )
    sessionStore.runtimeViewCache.store(updatedSnapshot, for: .planDetail(planId), at: loadedAt)
  }
}
