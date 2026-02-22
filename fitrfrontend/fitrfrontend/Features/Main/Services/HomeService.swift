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
    async let recentWorkouts = fetchRecentWorkouts(limit: 30)
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
    let lastWorkoutDTO = recentWorkoutsResponse.first
    let weekProgress = buildWeekProgress(workoutsThisWeekCount)
    let weeklyStats = calculateWeeklyStats(from: recentWorkoutsResponse)

    return HomeScreenData(
      greeting: "",
      weekProgress: weekProgress,
      nextSession: nextSessionDTO,
      lastWorkout: lastWorkoutDTO,
      currentWeight: String(format: "%.1f", metricsDTO.weight),
      weightChange: String(format: "%.1f", metricsDTO.change),
      streak: streakDTO.currentStreak,
      streakPercentile: streakDTO.streakPercentile,
      weeklyWorkoutCount: workoutsThisWeekCount,
      weeklyTotalVolume: weeklyStats.volumeStr,
      weeklyCaloriesBurned: weeklyStats.caloriesStr,
      weeklyAvgDuration: weeklyStats.durationStr,
      weeklyPersonalRecords: weeklyStats.prStrings,
      weeklyExerciseVariety: weeklyStats.varietyCount
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

  private func calculateWeeklyStats(from workouts: [WorkoutSessionResponse]) -> (
    volumeStr: String, caloriesStr: String, durationStr: String, prStrings: [String],
    varietyCount: Int
  ) {
    let calendar = Calendar.current
    let weekInterval = calendar.dateInterval(of: .weekOfYear, for: Date())
    let weekStart = weekInterval?.start ?? calendar.startOfDay(for: Date())
    let weekEnd = weekInterval?.end ?? Date()

    let weekWorkouts = workouts.filter { $0.startTime >= weekStart && $0.startTime < weekEnd }

    var totalVolume: Double = 0
    var totalCalories: Double = 0
    var totalDuration: Double = 0
    var exerciseMaxWeights: [String: Double] = [:]
    var exerciseNames = Set<String>()

    for workout in weekWorkouts {
      // Calculate workout duration
      if let endTime = workout.endTime {
        let duration = endTime.timeIntervalSince(workout.startTime) / 60
        totalDuration += duration
      }

      for exercise in workout.workoutExercises {
        exerciseNames.insert(exercise.exercise.name)

        for setLog in exercise.setLogs {
          totalVolume += Double(setLog.weight) * Double(setLog.reps)
          totalCalories += Double(setLog.calories)

          let maxWeight = exerciseMaxWeights[exercise.exercise.name] ?? 0
          exerciseMaxWeights[exercise.exercise.name] = max(maxWeight, Double(setLog.weight))
        }
      }
    }

    let avgDuration = !weekWorkouts.isEmpty ? totalDuration / Double(weekWorkouts.count) : 0

    // Volume string
    let volumeStr: String
    if totalVolume >= 1000 {
      volumeStr = String(format: "%.1f", totalVolume / 1000) + " K"
    } else {
      volumeStr = String(format: "%.0f", totalVolume)
    }

    let caloriesStr = String(format: "%.0f", totalCalories) + " cal"
    let durationStr = String(format: "%.0f", avgDuration) + " min"

    // Personal records (comparison to previous weeks would require fetching more data)
    // For now, just return the exercises with their max weights
    let prStrings = exerciseMaxWeights.sorted { $0.value > $1.value }
      .prefix(3)
      .map { exercise, weight in
        let formattedWeight = String(format: "%.0f", weight)
        return "\(exercise) \(formattedWeight) lbs"
      }

    return (
      volumeStr: volumeStr,
      caloriesStr: caloriesStr,
      durationStr: durationStr,
      prStrings: prStrings,
      varietyCount: exerciseNames.count
    )
  }
}
