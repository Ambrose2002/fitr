//
//  PlanDetailViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

internal import Combine
import Foundation

// MARK: - Enriched Plan Day Model

struct EnrichedPlanExercise: Identifiable, Hashable {
  let id: Int64
  let planDayId: Int64
  let exerciseId: Int64
  let name: String
  let measurementType: MeasurementType?
  let targetSets: Int
  let targetReps: Int
  let targetDurationSeconds: Int
  let targetDistance: Float
  let targetCalories: Float
  let targetWeight: Float
}

struct EnrichedPlanDay: Identifiable, Hashable {
  let id: Int64
  let dayNumber: Int
  let name: String
  let exercises: [EnrichedPlanExercise]

  var weekday: WorkoutWeekday? {
    WorkoutWeekday.from(dayNumber: dayNumber)
  }

  var weekdayName: String {
    weekday?.fullName ?? "Day \(dayNumber)"
  }

  var weekdayShortName: String {
    weekday?.shortName ?? "Day \(dayNumber)"
  }

  var estimatedDurationSeconds: Int {
    WorkoutDurationEstimator.estimatedDurationSeconds(for: exercises)
  }

  var estimatedMinutes: Int {
    WorkoutDurationEstimator.estimatedMinutes(for: exercises)
  }

  var exerciseCount: Int {
    exercises.count
  }

  var exerciseNames: String {
    exercises.map(\.name).joined(separator: ", ")
  }
}

struct PlanDetailSnapshot {
  let planDetail: WorkoutPlanResponse
  let enrichedDays: [EnrichedPlanDay]
  let isActiveToggle: Bool
}

// MARK: - Plan Detail ViewModel

@MainActor
final class PlanDetailViewModel: ObservableObject {
  @Published var planDetail: WorkoutPlanResponse?
  @Published var enrichedDays: [EnrichedPlanDay] = []
  @Published var isLoading = false
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published var errorMessage: String?
  @Published var isActiveToggle = false
  @Published var showAddDaySheet = false

  private var workoutPlanService: WorkoutPlanService
  private var sessionStore: SessionStore
  private var planId: Int64
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(planId: Int64, sessionStore: SessionStore) {
    self.planId = planId
    self.sessionStore = sessionStore
    self.workoutPlanService = WorkoutPlanService()
    restoreSnapshotIfAvailable(for: planId)
  }

  // MARK: - Update Methods for Navigation

  func updatePlanId(_ id: Int64) {
    guard id != planId else {
      return
    }

    self.planId = id
    resetForPlanChange()
    restoreSnapshotIfAvailable(for: id)
  }

  func updateSessionStore(_ store: SessionStore) {
    self.sessionStore = store
    self.workoutPlanService = WorkoutPlanService()
    restoreSnapshotIfAvailable(for: planId)
  }

  // MARK: - Data Loading

  func loadPlanDetail(forceRefresh: Bool = false) async {
    guard !isFetching else {
      return
    }

    restoreSnapshotIfNewer(for: planId)

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
      let plan = try await workoutPlanService.getPlan(id: planId)
      let days = try await buildEnrichedDays()
      applyLoadedData(plan: plan, days: days, loadedAt: Date())
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to load plan details. Please try again."
    }
  }

  // MARK: - Toggle Active Status

  func toggleActiveStatus(_ newValue: Bool) async {
    guard let plan = planDetail else { return }

    do {
      let updateRequest = UpdateWorkoutPlanRequest(name: plan.name, isActive: newValue)
      let updatedPlan = try await workoutPlanService.updatePlan(id: plan.id, request: updateRequest)
      self.planDetail = updatedPlan
      self.isActiveToggle = updatedPlan.isActive
      persistSnapshot(loadedAt: Date())
    } catch {
      errorMessage = "Failed to update plan status."
      // Revert toggle
      isActiveToggle = plan.isActive
    }
  }

  // MARK: - Plan Day Management

  func addPlanDay(name: String, dayNumber: Int) async {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else { return }
    guard availableDayNumbersForNewDay.contains(dayNumber) else {
      let weekdayName = WorkoutWeekday.from(dayNumber: dayNumber)?.fullName ?? "that day"
      errorMessage = "A workout day is already assigned to \(weekdayName)."
      return
    }

    let createRequest = CreateWorkoutPlanDayRequest(
      dayNumber: dayNumber,
      name: trimmedName
    )

    do {
      let newDay = try await workoutPlanService.addPlanDay(planId: planId, request: createRequest)
      let enrichedDay = EnrichedPlanDay(
        id: newDay.id,
        dayNumber: newDay.dayNumber,
        name: newDay.name,
        exercises: []
      )
      enrichedDays.append(enrichedDay)
      enrichedDays.sort { $0.dayNumber < $1.dayNumber }
      showAddDaySheet = false
      persistSnapshot(loadedAt: Date())
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to add workout day."
    }
  }

  func updatePlanDay(id: Int64, name: String, dayNumber: Int) async throws {
    let trimmedName = name.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !trimmedName.isEmpty else {
      throw APIErrorResponse(message: "Workout day name is required.", timestamp: "", status: 400)
    }
    guard availableDayNumbers(forEditing: id).contains(dayNumber) else {
      let weekdayName = WorkoutWeekday.from(dayNumber: dayNumber)?.fullName ?? "that day"
      throw APIErrorResponse(
        message: "A workout day is already assigned to \(weekdayName).",
        timestamp: "",
        status: 400
      )
    }

    guard let dayIndex = enrichedDays.firstIndex(where: { $0.id == id }) else {
      return
    }

    let updateRequest = CreateWorkoutPlanDayRequest(
      dayNumber: dayNumber,
      name: trimmedName
    )
    let updatedDay = try await workoutPlanService.updatePlanDay(
      planId: planId, dayId: id, request: updateRequest)

    let oldDay = enrichedDays[dayIndex]
    enrichedDays[dayIndex] = EnrichedPlanDay(
      id: oldDay.id,
      dayNumber: updatedDay.dayNumber,
      name: updatedDay.name,
      exercises: oldDay.exercises
    )
    enrichedDays.sort { $0.dayNumber < $1.dayNumber }
    persistSnapshot(loadedAt: Date())
  }

  func deletePlanDay(id: Int64) async {
    do {
      try await workoutPlanService.deletePlanDay(planId: planId, dayId: id)
      enrichedDays.removeAll { $0.id == id }
      sessionStore.runtimeViewCache.remove(.planDayDetail(id))
      persistSnapshot(loadedAt: Date())
    } catch {
      errorMessage = "Failed to delete workout day."
    }
  }

  func removeDeletedDay(id: Int64) {
    enrichedDays.removeAll { $0.id == id }
    sessionStore.runtimeViewCache.remove(.planDayDetail(id))
    persistSnapshot(loadedAt: Date())
  }

  func deletePlan() async {
    do {
      try await workoutPlanService.deletePlan(id: planId)
      for day in enrichedDays {
        sessionStore.runtimeViewCache.remove(.planDayDetail(day.id))
      }
      sessionStore.runtimeViewCache.remove(.planDetail(planId))
    } catch {
      errorMessage = "Failed to delete plan."
    }
  }

  // MARK: - Request Models Helper

  var planDayCount: Int {
    enrichedDays.count
  }

  var assignedDayNumbers: Set<Int> {
    Set(enrichedDays.map(\.dayNumber))
  }

  var availableDayNumbersForNewDay: [Int] {
    WorkoutWeekday.allCases.map { $0.rawValue }.filter { !assignedDayNumbers.contains($0) }
  }

  func availableDayNumbers(forEditing dayId: Int64) -> [Int] {
    guard let currentDay = enrichedDays.first(where: { $0.id == dayId }) else {
      return availableDayNumbersForNewDay
    }

    return WorkoutWeekday.allCases.map { $0.rawValue }.filter {
      $0 == currentDay.dayNumber || !assignedDayNumbers.contains($0)
    }
  }

  var hasAvailableWeekdays: Bool {
    !availableDayNumbersForNewDay.isEmpty
  }

  var totalExercisesCount: Int {
    enrichedDays.reduce(0) { $0 + $1.exerciseCount }
  }

  var averageExercisesPerDay: Double {
    guard !enrichedDays.isEmpty else { return 0 }
    return Double(totalExercisesCount) / Double(enrichedDays.count)
  }

  private func resetForPlanChange() {
    planDetail = nil
    enrichedDays = []
    isActiveToggle = false
    errorMessage = nil
    isLoading = false
    isRefreshing = false
    hasLoadedSnapshot = false
    lastLoadedAt = nil
  }

  private func buildEnrichedDays() async throws -> [EnrichedPlanDay] {
    let days = try await workoutPlanService.getPlanDays(planId: planId)

    let exerciseLookup: [Int64: ExerciseResponse]
    do {
      let availableExercises = try await workoutPlanService.getAllExercises(systemOnly: false)
      exerciseLookup = Dictionary(uniqueKeysWithValues: availableExercises.map { ($0.id, $0) })
    } catch {
      exerciseLookup = [:]
    }

    var enrichedDaysList: [EnrichedPlanDay] = []
    for day in days {
      do {
        let exercises = try await workoutPlanService.getExercises(dayId: day.id)
        let enrichedExercises = exercises.map { exercise in
          let exerciseMeta = exerciseLookup[exercise.exerciseId]
          return EnrichedPlanExercise(
            id: exercise.id,
            planDayId: exercise.planDayId,
            exerciseId: exercise.exerciseId,
            name: exerciseMeta?.name ?? "Exercise \(exercise.exerciseId)",
            measurementType: exerciseMeta?.measurementType,
            targetSets: exercise.targetSets,
            targetReps: exercise.targetReps,
            targetDurationSeconds: exercise.targetDurationSeconds,
            targetDistance: exercise.targetDistance,
            targetCalories: exercise.targetCalories,
            targetWeight: exercise.targetWeight ?? 0
          )
        }
        enrichedDaysList.append(
          EnrichedPlanDay(
            id: day.id,
            dayNumber: day.dayNumber,
            name: day.name,
            exercises: enrichedExercises
          )
        )
      } catch {
        enrichedDaysList.append(
          EnrichedPlanDay(
            id: day.id,
            dayNumber: day.dayNumber,
            name: day.name,
            exercises: []
          )
        )
      }
    }

    return enrichedDaysList.sorted { $0.dayNumber < $1.dayNumber }
  }

  private func applyLoadedData(
    plan: WorkoutPlanResponse,
    days: [EnrichedPlanDay],
    loadedAt: Date
  ) {
    planDetail = plan
    isActiveToggle = plan.isActive
    enrichedDays = days
    hasLoadedSnapshot = true
    lastLoadedAt = loadedAt
    persistSnapshot(loadedAt: loadedAt)
  }

  private func persistSnapshot(loadedAt: Date) {
    guard let planDetail else {
      return
    }

    hasLoadedSnapshot = true
    lastLoadedAt = loadedAt
    let snapshot = PlanDetailSnapshot(
      planDetail: planDetail,
      enrichedDays: enrichedDays,
      isActiveToggle: isActiveToggle
    )
    sessionStore.runtimeViewCache.store(snapshot, for: .planDetail(planId), at: loadedAt)
  }

  private func restoreSnapshotIfAvailable(for planId: Int64) {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDetail(planId), as: PlanDetailSnapshot.self)
    else {
      return
    }

    planDetail = snapshot.value.planDetail
    enrichedDays = snapshot.value.enrichedDays
    isActiveToggle = snapshot.value.isActiveToggle
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
    isLoading = false
  }

  private func restoreSnapshotIfNewer(for planId: Int64) {
    guard
      let snapshot: RuntimeViewCacheSnapshot<PlanDetailSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .planDetail(planId), as: PlanDetailSnapshot.self)
    else {
      return
    }

    if let lastLoadedAt, snapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    planDetail = snapshot.value.planDetail
    enrichedDays = snapshot.value.enrichedDays
    isActiveToggle = snapshot.value.isActiveToggle
    hasLoadedSnapshot = true
    self.lastLoadedAt = snapshot.lastLoadedAt
  }
}
