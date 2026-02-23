//
//  WorkoutPlanViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

internal import Combine
import Foundation

@MainActor
final class WorkoutPlanViewModel: ObservableObject {
  @Published var plans: [WorkoutPlanResponse] = []
  @Published var selectedPlan: WorkoutPlanResponse?
  @Published var planDays: [PlanDayResponse] = []
  @Published var isLoading = false
  @Published var errorMessage: String?

  private let workoutPlanService: WorkoutPlanService
  private let sessionStore: SessionStore

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
    self.workoutPlanService = WorkoutPlanService()
  }

  // MARK: - Workout Plans

  func loadPlans() async {
    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      self.plans = try await workoutPlanService.getAllPlans()
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func createPlan(name: String) async {
    errorMessage = nil

    let request = CreateWorkoutPlanRequest(name: name)

    do {
      let newPlan = try await workoutPlanService.createPlan(request: request)
      self.plans.append(newPlan)
      self.selectedPlan = newPlan
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func updatePlan(id: Int64, name: String) async {
    errorMessage = nil

    let request = CreateWorkoutPlanRequest(name: name)

    do {
      let updatedPlan = try await workoutPlanService.updatePlan(id: id, request: request)
      if let index = plans.firstIndex(where: { $0.id == id }) {
        self.plans[index] = updatedPlan
      }
      if selectedPlan?.id == id {
        self.selectedPlan = updatedPlan
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func deletePlan(id: Int64) async {
    errorMessage = nil

    do {
      try await workoutPlanService.deletePlan(id: id)
      self.plans.removeAll { $0.id == id }
      if selectedPlan?.id == id {
        self.selectedPlan = nil
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func selectPlan(id: Int64) {
    self.selectedPlan = plans.first(where: { $0.id == id })
  }

  // MARK: - Plan Days

  func loadPlanDays(for planId: Int64) async {
    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      self.planDays = try await workoutPlanService.getPlanDays(planId: planId)
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func addPlanDay(planId: Int64, dayNumber: Int, name: String) async {
    errorMessage = nil

    let request = CreateWorkoutPlanDayRequest(dayNumber: dayNumber, name: name)

    do {
      let newDay = try await workoutPlanService.addPlanDay(planId: planId, request: request)
      self.planDays.append(newDay)
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func updatePlanDay(dayId: Int64, dayNumber: Int, name: String) async {
    errorMessage = nil

    let request = CreateWorkoutPlanDayRequest(dayNumber: dayNumber, name: name)

    do {
      let updatedDay = try await workoutPlanService.updatePlanDay(dayId: dayId, request: request)
      if let index = planDays.firstIndex(where: { $0.id == dayId }) {
        self.planDays[index] = updatedDay
      }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func deletePlanDay(dayId: Int64) async {
    errorMessage = nil

    do {
      try await workoutPlanService.deletePlanDay(dayId: dayId)
      self.planDays.removeAll { $0.id == dayId }
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  // MARK: - Plan Day Exercises

  func addExerciseToDay(
    dayId: Int64,
    exerciseId: Int64,
    targetSets: Int,
    targetReps: Int,
    targetDurationSeconds: Int,
    targetDistance: Float,
    targetCalories: Float
  ) async {
    errorMessage = nil

    let request = CreatePlanDayExerciseRequest(
      exerciseId: exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetDurationSeconds: targetDurationSeconds,
      targetDistance: targetDistance,
      targetCalories: targetCalories
    )

    do {
      _ = try await workoutPlanService.addExerciseToDay(dayId: dayId, request: request)
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func updateDayExercise(
    dayId: Int64,
    exerciseId: Int64,
    targetSets: Int,
    targetReps: Int,
    targetDurationSeconds: Int,
    targetDistance: Float,
    targetCalories: Float
  ) async {
    errorMessage = nil

    let request = CreatePlanDayExerciseRequest(
      exerciseId: exerciseId,
      targetSets: targetSets,
      targetReps: targetReps,
      targetDurationSeconds: targetDurationSeconds,
      targetDistance: targetDistance,
      targetCalories: targetCalories
    )

    do {
      _ = try await workoutPlanService.updateDayExercise(
        dayId: dayId,
        exerciseId: exerciseId,
        request: request
      )
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func deleteDayExercise(dayId: Int64, exerciseId: Int64) async {
    errorMessage = nil

    do {
      try await workoutPlanService.deleteDayExercise(dayId: dayId, exerciseId: exerciseId)
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }
}
