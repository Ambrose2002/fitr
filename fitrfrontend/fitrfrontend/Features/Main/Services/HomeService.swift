//
//  HomeService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation

class HomeService {

  func fetchHomeScreenData() async throws -> HomeScreenData {
    async let nextSession = fetchNextSession()
    async let lastWorkout = fetchLastWorkout()
    async let currentMetrics = fetchCurrentMetrics()
    async let streak = fetchStreak()

    let (nextSessionDTO, lastWorkoutDTO, metricsDTO, streakDTO) = try await (
      nextSession,
      lastWorkout,
      currentMetrics,
      streak
    )

    return HomeScreenData(
      greeting: "G'day, Alex!",
      weekProgress: "You've hit 4 workouts this week. 1 to go!",
      nextSession: nextSessionDTO,
      lastWorkout: lastWorkoutDTO,
      currentWeight: String(format: "%.1f", metricsDTO.weight),
      weightChange: String(format: "%.1f", metricsDTO.change),
      streak: streakDTO.currentStreak,
      streakPercentile: streakDTO.streakPercentile
    )
  }

  private func fetchNextSession() async throws -> WorkoutSessionResponse? {
    // This would call your backend endpoint
    // For now, returning mock data
    return nil
  }

  private func fetchLastWorkout() async throws -> WorkoutSessionResponse? {
    // GET /api/workouts?limit=1
    return nil
  }

  private func fetchCurrentMetrics() async throws -> CurrentMetricsDTO {
    // GET /api/body-metrics/latest?metricType=WEIGHT
    return CurrentMetricsDTO(
      weight: 82.4, lastUpdated: ISO8601DateFormatter().string(from: Date()), change: -0.6)
  }

  private func fetchStreak() async throws -> StreakDTO {
    // This would need a backend endpoint or be calculated from workout data
    return StreakDTO(currentStreak: 12, streakPercentile: 5)
  }
}
