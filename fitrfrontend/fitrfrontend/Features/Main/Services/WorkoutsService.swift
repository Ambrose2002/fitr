//
//  WorkoutsService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

import Foundation
import KeychainSwift

final class WorkoutsService {
  private var authToken: String? {
    KeychainSwift().get("userAccessToken")
  }

  private static let fractionalSecondsDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let standardDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  private func addAuthHeaders(_ request: inout URLRequest) {
    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      if let date = Self.fractionalSecondsDateFormatter.date(from: dateString)
        ?? Self.standardDateFormatter.date(from: dateString)
      {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container, debugDescription: "Invalid date format: \(dateString)"
      )
    }
    return decoder
  }

  private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
    guard var components = URLComponents(string: Constants.baseUrl + path) else {
      throw URLError(.badURL)
    }

    if !queryItems.isEmpty {
      components.queryItems = queryItems
    }

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    return url
  }

  func fetchWorkoutHistory() async throws -> [WorkoutSessionResponse] {
    let url = try makeURL(path: APIEndpoints.workouts)
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
      return try createDecoder().decode([WorkoutSessionResponse].self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func fetchWorkoutSession(id: Int64) async throws -> WorkoutSessionResponse {
    guard let workoutId = Int(exactly: id) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workout(id: workoutId))
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
      return try createDecoder().decode(WorkoutSessionResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func createWorkoutSession(request payload: CreateWorkoutSessionRequest) async throws
    -> WorkoutSessionResponse
  {
    let url = try makeURL(path: APIEndpoints.workouts)
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutSessionResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func updateWorkoutSession(id: Int64, request payload: CreateWorkoutSessionRequest) async throws
    -> WorkoutSessionResponse
  {
    guard let workoutId = Int(exactly: id) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workout(id: workoutId))
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutSessionResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func deleteWorkoutSession(id: Int64) async throws {
    guard let workoutId = Int(exactly: id) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workout(id: workoutId))
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

  func fetchActiveWorkout() async throws -> WorkoutSessionResponse? {
    let url = try makeURL(path: APIEndpoints.activeWorkout)
    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 204:
      return nil
    case 200...299:
      return try createDecoder().decode(WorkoutSessionResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func fetchWorkoutExercises(workoutId: Int64) async throws -> [WorkoutExerciseResponse] {
    guard let resolvedId = Int(exactly: workoutId) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workoutExercises(workoutId: resolvedId))
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
      return try createDecoder().decode([WorkoutExerciseResponse].self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func addWorkoutExercise(workoutId: Int64, request payload: CreateWorkoutExerciseRequest) async throws
    -> WorkoutExerciseResponse
  {
    guard let resolvedId = Int(exactly: workoutId) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workoutExercises(workoutId: resolvedId))
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(WorkoutExerciseResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func deleteWorkoutExercise(workoutId: Int64, exerciseId: Int64) async throws {
    guard
      let resolvedWorkoutId = Int(exactly: workoutId),
      let resolvedExerciseId = Int(exactly: exerciseId)
    else {
      throw URLError(.badURL)
    }

    let url = try makeURL(
      path: "\(APIEndpoints.workoutExercises(workoutId: resolvedWorkoutId))/\(resolvedExerciseId)")
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

  func createSetLog(workoutExerciseId: Int64, request payload: CreateSingleSetLogRequest) async throws
    -> SetLogResponse
  {
    guard let resolvedId = Int(exactly: workoutExerciseId) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.workoutExerciseSetLogs(workoutExerciseId: resolvedId))
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(SetLogResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func updateSetLog(
    workoutExerciseId: Int64,
    setLogId: Int64,
    request payload: CreateSingleSetLogRequest
  ) async throws -> SetLogResponse {
    guard
      let resolvedWorkoutExerciseId = Int(exactly: workoutExerciseId),
      let resolvedSetLogId = Int(exactly: setLogId)
    else {
      throw URLError(.badURL)
    }

    let url = try makeURL(
      path: APIEndpoints.workoutExerciseSetLog(
        workoutExerciseId: resolvedWorkoutExerciseId,
        setId: resolvedSetLogId
      ))
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(SetLogResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func deleteSetLog(workoutExerciseId: Int64, setLogId: Int64) async throws {
    guard
      let resolvedWorkoutExerciseId = Int(exactly: workoutExerciseId),
      let resolvedSetLogId = Int(exactly: setLogId)
    else {
      throw URLError(.badURL)
    }

    let url = try makeURL(
      path: APIEndpoints.workoutExerciseSetLog(
        workoutExerciseId: resolvedWorkoutExerciseId,
        setId: resolvedSetLogId
      ))
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
