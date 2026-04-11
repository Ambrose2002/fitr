//
//  ExerciseLibraryViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 4/11/26.
//

internal import Combine
import Foundation

struct ExerciseLibrarySnapshot {
  let exercises: [ExerciseResponse]
}

@MainActor
final class ExerciseLibraryViewModel: ObservableObject {
  @Published var exercises: [ExerciseResponse] = []
  @Published var searchText = ""
  @Published var isLoading = false
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published var errorMessage: String?

  private let sessionStore: SessionStore
  private let workoutPlanService: WorkoutPlanService
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(
    sessionStore: SessionStore,
    workoutPlanService: WorkoutPlanService
  ) {
    self.sessionStore = sessionStore
    self.workoutPlanService = workoutPlanService
    restoreSnapshotIfAvailable()
  }

  convenience init(sessionStore: SessionStore) {
    self.init(sessionStore: sessionStore, workoutPlanService: WorkoutPlanService())
  }

  var filteredExercises: [ExerciseResponse] {
    ExerciseSearchMatcher.filterAndSort(exercises, query: searchText)
  }

  var customExerciseCount: Int {
    exercises.filter(\.isCustomExercise).count
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
      let fetchedExercises = try await workoutPlanService.getAllExercises(systemOnly: false)
      exercises = sortedExercises(fetchedExercises)
      errorMessage = nil
      persistSnapshot(loadedAt: Date())
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      if error.isCancellation {
        return
      }
      errorMessage = "Couldn't load exercises."
    }
  }

  func createCustomExercise(
    name: String,
    measurementType: MeasurementType
  ) async throws -> ExerciseResponse {
    let payload = CreateExerciseRequest(name: name, measurementType: measurementType)
    let createdExercise = try await workoutPlanService.createExercise(
      request: payload,
      isSystemDefined: false
    )
    upsertExercise(createdExercise)
    errorMessage = nil
    persistSnapshot(loadedAt: Date())
    return createdExercise
  }

  func updateCustomExercise(
    exerciseId: Int64,
    name: String,
    measurementType: MeasurementType
  ) async throws -> ExerciseResponse {
    guard let existingExercise = exercises.first(where: { $0.id == exerciseId }) else {
      throw APIErrorResponse(message: "Exercise not found.", timestamp: "", status: 404)
    }

    guard existingExercise.isCustomExercise else {
      throw APIErrorResponse(
        message: "Only custom exercises can be edited.",
        timestamp: "",
        status: 400
      )
    }

    let payload = CreateExerciseRequest(name: name, measurementType: measurementType)
    let updatedExercise = try await workoutPlanService.updateExercise(id: exerciseId, request: payload)
    upsertExercise(updatedExercise)
    errorMessage = nil
    persistSnapshot(loadedAt: Date())
    return updatedExercise
  }

  private func upsertExercise(_ exercise: ExerciseResponse) {
    var updatedExercises = exercises
    if let index = updatedExercises.firstIndex(where: { $0.id == exercise.id }) {
      updatedExercises[index] = exercise
    } else {
      updatedExercises.append(exercise)
    }
    exercises = sortedExercises(updatedExercises)
  }

  private func sortedExercises(_ source: [ExerciseResponse]) -> [ExerciseResponse] {
    source.sorted { lhs, rhs in
      let order = lhs.name.localizedCaseInsensitiveCompare(rhs.name)
      if order == .orderedSame {
        return lhs.id < rhs.id
      }
      return order == .orderedAscending
    }
  }

  private func persistSnapshot(loadedAt: Date) {
    let snapshot = ExerciseLibrarySnapshot(exercises: exercises)
    hasLoadedSnapshot = true
    lastLoadedAt = loadedAt
    sessionStore.runtimeViewCache.store(snapshot, for: .exerciseLibrary, at: loadedAt)
  }

  private func restoreSnapshotIfAvailable() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<ExerciseLibrarySnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .exerciseLibrary, as: ExerciseLibrarySnapshot.self)
    else {
      return
    }

    exercises = snapshot.value.exercises
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
    isLoading = false
  }

  private func restoreSnapshotIfNewer() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<ExerciseLibrarySnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .exerciseLibrary, as: ExerciseLibrarySnapshot.self)
    else {
      return
    }

    if let lastLoadedAt, snapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    exercises = snapshot.value.exercises
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
  }
}
