//
//  WorkoutPlanService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

import Foundation
import KeychainSwift

struct WorkoutPlanService {

  private var authToken: String? {
    KeychainSwift().get("userAccessToken")
  }

  private func addAuthHeaders(_ request: inout URLRequest) {
    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder -> Date in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      // Try ISO8601 with fractional seconds first
      let formatter1 = ISO8601DateFormatter()
      formatter1.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
      if let date = formatter1.date(from: dateString) {
        return date
      }

      // Fallback to standard ISO8601
      let formatter2 = ISO8601DateFormatter()
      formatter2.formatOptions = [.withInternetDateTime]
      if let date = formatter2.date(from: dateString) {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Cannot decode date string \(dateString)"
      )
    }
    return decoder
  }

  // MARK: - Exercises

  /// Fetches exercises available to the user and/or system exercises
  func getAllExercises(systemOnly: Bool = false) async throws -> [ExerciseResponse] {
    guard var components = URLComponents(string: Constants.baseUrl + APIEndpoints.exercises) else {
      throw URLError(.badURL)
    }

    components.queryItems = [
      URLQueryItem(name: "systemOnly", value: systemOnly ? "true" : "false")
    ]

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode([ExerciseResponse].self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  // MARK: - Workout Plans CRUD

  /// Fetches all workout plans for the current user
  func getAllPlans() async throws -> [WorkoutPlanResponse] {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.plans) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode([WorkoutPlanResponse].self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Fetches a specific workout plan by ID
  func getPlan(id: Int64) async throws -> WorkoutPlanResponse {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.plan(id: Int(id))) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutPlanResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Creates a new workout plan
  func createPlan(request: CreateWorkoutPlanRequest) async throws -> WorkoutPlanResponse {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.plans) else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutPlanResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Updates an existing workout plan
  func updatePlan(id: Int64, request: UpdateWorkoutPlanRequest) async throws -> WorkoutPlanResponse
  {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.plan(id: Int(id))) else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "PUT"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutPlanResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Deletes a workout plan
  func deletePlan(id: Int64) async throws {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.plan(id: Int(id))) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return

    default:
      throw URLError(.unknown)
    }
  }

  // MARK: - Plan Days Management

  /// Fetches all days in a workout plan
  func getPlanDays(planId: Int64) async throws -> [PlanDayResponse] {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.planDays(planId: Int(planId)))
    else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode([PlanDayResponse].self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Adds a new day to a workout plan
  func addPlanDay(planId: Int64, request: CreateWorkoutPlanDayRequest) async throws
    -> PlanDayResponse
  {
    guard let url = URL(string: Constants.baseUrl + APIEndpoints.planDays(planId: Int(planId)))
    else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(PlanDayResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Updates a plan day
  func updatePlanDay(planId: Int64, dayId: Int64, request: CreateWorkoutPlanDayRequest) async throws
    -> PlanDayResponse
  {
    guard let url = URL(string: Constants.baseUrl + "/api/plans/\(planId)/days/\(dayId)") else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "PUT"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(PlanDayResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Deletes a plan day
  func deletePlanDay(planId: Int64, dayId: Int64) async throws {
    guard let url = URL(string: Constants.baseUrl + "/api/plans/\(planId)/days/\(dayId)") else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return

    default:
      throw URLError(.unknown)
    }
  }

  // MARK: - Plan Day Exercises Management

  /// Fetches all exercises for a plan day
  func getExercises(dayId: Int64) async throws -> [PlanExerciseResponse] {
    guard let url = URL(string: Constants.baseUrl + "/api/plan-days/\(dayId)/exercises") else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode([PlanExerciseResponse].self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Adds an exercise to a plan day
  func addExerciseToDay(
    dayId: Int64,
    request: CreatePlanDayExerciseRequest
  ) async throws -> PlanExerciseResponse {
    guard let url = URL(string: Constants.baseUrl + "/api/plan-days/\(dayId)/exercises") else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "POST"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(PlanExerciseResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Updates an exercise in a plan day
  func updateDayExercise(
    dayId: Int64,
    exerciseId: Int64,
    request: CreatePlanDayExerciseRequest
  ) async throws -> PlanExerciseResponse {
    guard
      let url = URL(string: Constants.baseUrl + "/api/plan-days/\(dayId)/exercises/\(exerciseId)")
    else {
      throw URLError(.badURL)
    }

    var urlRequest = URLRequest(url: url)
    urlRequest.httpMethod = "PUT"
    urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&urlRequest)
    urlRequest.httpBody = try JSONEncoder().encode(request)

    let (data, response) = try await URLSession.shared.data(for: urlRequest)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(PlanExerciseResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Deletes an exercise from a plan day
  func deleteDayExercise(dayId: Int64, exerciseId: Int64) async throws {
    guard
      let url = URL(string: Constants.baseUrl + "/api/plan-days/\(dayId)/exercises/\(exerciseId)")
    else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (_, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return

    default:
      throw URLError(.unknown)
    }
  }
}
