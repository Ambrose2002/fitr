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

@MainActor
final class PlanDayDetailViewModel: ObservableObject {
  @Published var exercises: [EnrichedPlanExercise] = []
  @Published var availableExercises: [ExerciseResponse] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var showAddExerciseSheet = false
  @Published var showDeleteDayConfirmation = false
  @Published var showRemoveConfirmation = false
  @Published var pendingRemoveExercise: EnrichedPlanExercise?
  @Published var shouldDismiss = false

  let planId: Int64
  let dayId: Int64
  let dayName: String

  private let workoutPlanService = WorkoutPlanService()

  init(planId: Int64, dayId: Int64, dayName: String) {
    self.planId = planId
    self.dayId = dayId
    self.dayName = dayName
  }

  var exerciseCount: Int {
    exercises.count
  }

  var durationMinutes: Int {
    let totalSeconds = exercises.reduce(0) { $0 + $1.targetDurationSeconds }
    return totalSeconds > 0 ? totalSeconds / 60 : 0
  }

  func load() async {
    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
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
    } catch {
      errorMessage = "Failed to load plan day exercises."
    }
  }

  func addExercise(exercise: ExerciseResponse, targets: PlanExerciseTargets) async {
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
    } catch {
      errorMessage = "Failed to add exercise."
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
    } catch {
      errorMessage = "Failed to remove exercise."
    }
  }

  func deleteDay() async {
    do {
      try await workoutPlanService.deletePlanDay(planId: planId, dayId: dayId)
      shouldDismiss = true
    } catch {
      errorMessage = "Failed to delete workout day."
    }
  }
}
