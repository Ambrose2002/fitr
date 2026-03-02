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
}
