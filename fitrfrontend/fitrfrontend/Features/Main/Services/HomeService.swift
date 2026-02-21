//
//  HomeService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation
import KeychainSwift

extension ISO8601DateFormatter {
  fileprivate static let fractionalSeconds: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  fileprivate static let standard: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()
}

class HomeService {
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
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      if let date = ISO8601DateFormatter.fractionalSeconds.date(from: dateString)
        ?? ISO8601DateFormatter.standard.date(from: dateString)
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

  private func performRequest<T: Decodable>(_ url: URL) async throws -> T {
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
      return try createDecoder().decode(T.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)

    default:
      throw URLError(.unknown)
    }
  }

  func fetchHomeScreenData() async throws -> HomeScreenData {
    async let recentWorkouts = fetchRecentWorkouts(limit: 2)
    async let currentMetrics = fetchCurrentMetrics()
    async let streak = fetchStreak()
    async let workoutsThisWeek = fetchWorkoutsThisWeekCount()

    let (recentWorkoutsResponse, metricsDTO, streakDTO, workoutsThisWeekCount) = try await (
      recentWorkouts,
      currentMetrics,
      streak,
      workoutsThisWeek
    )

    let nextSessionDTO = recentWorkoutsResponse.first
    let lastWorkoutDTO = recentWorkoutsResponse.dropFirst().first
    let weekProgress = buildWeekProgress(workoutsThisWeekCount)

    return HomeScreenData(
      greeting: "",
      weekProgress: weekProgress,
      nextSession: nextSessionDTO,
      lastWorkout: lastWorkoutDTO,
      currentWeight: String(format: "%.1f", metricsDTO.weight),
      weightChange: String(format: "%.1f", metricsDTO.change),
      streak: streakDTO.currentStreak,
      streakPercentile: streakDTO.streakPercentile
    )
  }

  private func fetchCurrentMetrics() async throws -> CurrentMetricsDTO {
    let metricsURL = try makeURL(
      path: APIEndpoints.bodyMetrics,
      queryItems: [
        URLQueryItem(name: "metricType", value: "WEIGHT"),
        URLQueryItem(name: "limit", value: "2"),
      ]
    )

    let metrics: [BodyMetricResponse] = try await performRequest(metricsURL)
    let formatter = ISO8601DateFormatter()
    let latestMetric = metrics.first
    let previousMetric = metrics.dropFirst().first
    let latestValue = latestMetric?.value ?? 0
    let previousValue = previousMetric?.value ?? latestValue

    return CurrentMetricsDTO(
      weight: Double(latestValue),
      lastUpdated: formatter.string(from: latestMetric?.updatedAt ?? Date()),
      change: Double(latestValue - previousValue)
    )
  }

  private func fetchStreak() async throws -> StreakDTO {
    let workouts = try await fetchRecentWorkouts(limit: 30)
    let currentStreak = calculateStreak(from: workouts)
    let percentile = min(99, max(0, currentStreak * 5))

    return StreakDTO(currentStreak: currentStreak, streakPercentile: percentile)
  }

  private func fetchRecentWorkouts(limit: Int) async throws -> [WorkoutSessionResponse] {
    let url = try makeURL(
      path: APIEndpoints.workouts,
      queryItems: [URLQueryItem(name: "limit", value: "\(limit)")]
    )

    return try await performRequest(url)
  }

  private func fetchWorkoutsThisWeekCount() async throws -> Int {
    let calendar = Calendar.current
    let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date())
    let startDate = weekInterval?.start ?? calendar.startOfDay(for: Date())
    let endDate = weekInterval?.end ?? Date()
    let formatter = ISO8601DateFormatter()

    let url = try makeURL(
      path: APIEndpoints.workouts,
      queryItems: [
        URLQueryItem(name: "startDate", value: formatter.string(from: startDate)),
        URLQueryItem(name: "endDate", value: formatter.string(from: endDate)),
      ]
    )

    let workouts: [WorkoutSessionResponse] = try await performRequest(url)
    return workouts.count
  }

  private func calculateStreak(from workouts: [WorkoutSessionResponse]) -> Int {
    let calendar = Calendar.current
    let workoutDays = Set(workouts.map { calendar.startOfDay(for: $0.startTime) })
    let today = calendar.startOfDay(for: Date())

    guard workoutDays.contains(today) else {
      return 0
    }

    var streak = 0
    var day = today

    while workoutDays.contains(day) {
      streak += 1
      guard let previousDay = calendar.date(byAdding: .day, value: -1, to: day) else {
        break
      }
      day = previousDay
    }

    return streak
  }

  private func buildWeekProgress(_ workoutCount: Int, weeklyTarget: Int = 5) -> String {
    if workoutCount >= weeklyTarget {
      return "You've hit \(workoutCount) workouts this week. Nice work!"
    }

    let remaining = max(weeklyTarget - workoutCount, 0)
    return "You've hit \(workoutCount) workouts this week. \(remaining) to go!"
  }
}
