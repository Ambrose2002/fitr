//
//  PlanDetailViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

internal import Combine
import Foundation

// MARK: - Enriched Plan Day Model

struct EnrichedPlanDay: Identifiable {
  let id: Int64
  let dayNumber: Int
  let name: String
  let exercises: [PlanExerciseResponse]

  var durationMinutes: Int {
    let totalSeconds = exercises.reduce(0) { $0 + $1.targetDurationSeconds }
    return totalSeconds > 0 ? totalSeconds / 60 : 0
  }

  var exerciseCount: Int {
    exercises.count
  }

  var exerciseNames: String {
    exercises.map { "Exercise \($0.id)" }.joined(separator: ", ")
  }
}

// MARK: - Plan Detail ViewModel

@MainActor
final class PlanDetailViewModel: ObservableObject {
  @Published var planDetail: WorkoutPlanResponse?
  @Published var enrichedDays: [EnrichedPlanDay] = []
  @Published var isLoading = false
  @Published var errorMessage: String?
  @Published var isActiveToggle = false
  @Published var showAddDaySheet = false
  @Published var newDayName = ""

  private var workoutPlanService: WorkoutPlanService
  private var sessionStore: SessionStore
  private var planId: Int64

  init(planId: Int64, sessionStore: SessionStore) {
    self.planId = planId
    self.sessionStore = sessionStore
    self.workoutPlanService = WorkoutPlanService()
  }

  // MARK: - Update Methods for Navigation

  func updatePlanId(_ id: Int64) {
    self.planId = id
  }

  func updateSessionStore(_ store: SessionStore) {
    self.sessionStore = store
    self.workoutPlanService = WorkoutPlanService()
  }

  // MARK: - Data Loading

  func loadPlanDetail() async {
    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      // Fetch plan
      let plan = try await workoutPlanService.getPlan(id: planId)
      self.planDetail = plan
      self.isActiveToggle = plan.isActive

      // Fetch plan days
      let days = try await workoutPlanService.getPlanDays(planId: planId)

      // Fetch exercises for each day
      var enrichedDaysList: [EnrichedPlanDay] = []
      for day in days {
        do {
          let exercises = try await workoutPlanService.getExercises(dayId: day.id)
          let enrichedDay = EnrichedPlanDay(
            id: day.id,
            dayNumber: day.dayNumber,
            name: day.name,
            exercises: exercises
          )
          enrichedDaysList.append(enrichedDay)
        } catch {
          print("DEBUG: Failed to fetch exercises for day \(day.name): \(error)")
          // Add day with empty exercises
          let enrichedDay = EnrichedPlanDay(
            id: day.id,
            dayNumber: day.dayNumber,
            name: day.name,
            exercises: []
          )
          enrichedDaysList.append(enrichedDay)
        }
      }

      enrichedDays = enrichedDaysList.sorted { $0.dayNumber < $1.dayNumber }
    } catch {
      print("DEBUG: Failed to load plan detail: \(error)")
      errorMessage = "Failed to load plan details. Please try again."
    }
  }

  // MARK: - Toggle Active Status

  func toggleActiveStatus(_ newValue: Bool) async {
    guard let plan = planDetail else { return }

    do {
      // The service expects CreateWorkoutPlanRequest which only has name
      // We need to use the backend endpoint that handles isActive
      // For now, we'll use the updatePlan with name
      let updateRequest = CreateWorkoutPlanRequest(name: plan.name)
      let updatedPlan = try await workoutPlanService.updatePlan(id: plan.id, request: updateRequest)
      self.planDetail = updatedPlan
      self.isActiveToggle = updatedPlan.isActive
    } catch {
      print("DEBUG: Failed to toggle active status: \(error)")
      errorMessage = "Failed to update plan status."
      // Revert toggle
      isActiveToggle = plan.isActive
    }
  }

  // MARK: - Plan Day Management

  func addPlanDay(name: String) async {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

    let nextDayNumber = (enrichedDays.max { $0.dayNumber < $1.dayNumber }?.dayNumber ?? 0) + 1
    let createRequest = CreateWorkoutPlanDayRequest(
      dayNumber: nextDayNumber,
      name: name
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
      newDayName = ""
      showAddDaySheet = false
    } catch {
      print("DEBUG: Failed to add plan day: \(error)")
      errorMessage = "Failed to add workout day."
    }
  }

  func updatePlanDay(id: Int64, name: String) async {
    guard !name.trimmingCharacters(in: .whitespaces).isEmpty else { return }

    do {
      let updateRequest = CreateWorkoutPlanDayRequest(
        dayNumber: 0,  // Will be ignored in update
        name: name
      )
      let updatedDay = try await workoutPlanService.updatePlanDay(dayId: id, request: updateRequest)

      if let index = enrichedDays.firstIndex(where: { $0.id == id }) {
        let oldDay = enrichedDays[index]
        enrichedDays[index] = EnrichedPlanDay(
          id: oldDay.id,
          dayNumber: oldDay.dayNumber,
          name: updatedDay.name,
          exercises: oldDay.exercises
        )
      }
    } catch {
      print("DEBUG: Failed to update plan day: \(error)")
      errorMessage = "Failed to update workout day."
    }
  }

  func deletePlanDay(id: Int64) async {
    do {
      try await workoutPlanService.deletePlanDay(dayId: id)
      enrichedDays.removeAll { $0.id == id }
    } catch {
      print("DEBUG: Failed to delete plan day: \(error)")
      errorMessage = "Failed to delete workout day."
    }
  }

  func deletePlan() async {
    do {
      try await workoutPlanService.deletePlan(id: planId)
    } catch {
      print("DEBUG: Failed to delete plan: \(error)")
      errorMessage = "Failed to delete plan."
    }
  }

  // MARK: - Request Models Helper

  var planDayCount: Int {
    enrichedDays.count
  }

  var totalExercisesCount: Int {
    enrichedDays.reduce(0) { $0 + $1.exerciseCount }
  }

  var averageExercisesPerDay: Double {
    guard !enrichedDays.isEmpty else { return 0 }
    return Double(totalExercisesCount) / Double(enrichedDays.count)
  }
}

