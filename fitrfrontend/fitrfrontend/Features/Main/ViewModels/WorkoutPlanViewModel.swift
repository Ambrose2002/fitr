//
//  WorkoutPlanViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

internal import Combine
import Foundation

// MARK: - Plan Summary Model

struct PlanSummary: Identifiable {
  let id: Int64
  let name: String
  let createdAt: Date
  let isActive: Bool
  let daysCount: Int
  let exercisesCount: Int
  let averageExercisesPerDay: Double

  var frequencyDescription: String {
    "\(daysCount) \(daysCount == 1 ? "day" : "days")/week"
  }

  var exerciseCountDescription: String {
    "\(exercisesCount) \(exercisesCount == 1 ? "exercise" : "exercises")"
  }

  var createdDescription: String {
    let calendar = Calendar.current
    let today = Date()
    let components = calendar.dateComponents([.day], from: createdAt, to: today)

    if let days = components.day {
      if days == 0 {
        return "Created today"
      } else if days == 1 {
        return "Created yesterday"
      } else if days < 7 {
        return "Created \(days) days ago"
      } else if days < 30 {
        let weeks = days / 7
        return "Created \(weeks) \(weeks == 1 ? "week" : "weeks") ago"
      } else {
        return "Created \(createdAt.formatted(date: .abbreviated, time: .omitted))"
      }
    }
    return "Created \(createdAt.formatted(date: .abbreviated, time: .omitted))"
  }
}

@MainActor
final class WorkoutPlanViewModel: ObservableObject {
  @Published var plans: [PlanSummary] = []
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
      let basePlans = try await workoutPlanService.getAllPlans()
      var enrichedPlans: [PlanSummary] = []

      for plan in basePlans {
        do {
          let days = try await workoutPlanService.getPlanDays(planId: plan.id)
          var totalExercises = 0

          for day in days {
            let exercises = try await workoutPlanService.getExercises(dayId: day.id)
            totalExercises += exercises.count
          }

          let avgExercises = days.isEmpty ? 0.0 : Double(totalExercises) / Double(days.count)

          let summary = PlanSummary(
            id: plan.id,
            name: plan.name,
            createdAt: plan.createdAt,
            isActive: plan.isActive,
            daysCount: days.count,
            exercisesCount: totalExercises,
            averageExercisesPerDay: avgExercises
          )
          enrichedPlans.append(summary)
        } catch {
          print("DEBUG: Failed to fetch details for plan '\(plan.name)' (ID: \(plan.id)): \(error)")
          let summary = PlanSummary(
            id: plan.id,
            name: plan.name,
            createdAt: plan.createdAt,
            isActive: plan.isActive,
            daysCount: 0,
            exercisesCount: 0,
            averageExercisesPerDay: 0
          )
          enrichedPlans.append(summary)
        }
      }

      self.plans = enrichedPlans
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  func createPlan(name: String) async {
    errorMessage = nil

    let request = CreateWorkoutPlanRequest(name: name)

    do {
      let newPlan = try await workoutPlanService.createPlan(request: request)
      let summary = PlanSummary(
        id: newPlan.id,
        name: newPlan.name,
        createdAt: newPlan.createdAt,
        isActive: newPlan.isActive,
        daysCount: 0,
        exercisesCount: 0,
        averageExercisesPerDay: 0
      )
      self.plans.insert(summary, at: 0)
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
        let summary = PlanSummary(
          id: updatedPlan.id,
          name: updatedPlan.name,
          createdAt: updatedPlan.createdAt,
          isActive: updatedPlan.isActive,
          daysCount: plans[index].daysCount,
          exercisesCount: plans[index].exercisesCount,
          averageExercisesPerDay: plans[index].averageExercisesPerDay
        )
        self.plans[index] = summary
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
    Task {
      do {
        self.selectedPlan = try await workoutPlanService.getPlan(id: id)
      } catch {
        self.errorMessage = error.localizedDescription
      }
    }
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
