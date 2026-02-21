//
//  HomeScreenData.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation

struct HomeScreenData: Codable {
  let greeting: String
  let weekProgress: String
  let nextSession: WorkoutSessionResponse?
  let lastWorkout: WorkoutSessionResponse?
  let currentWeight: String
  let weightChange: String
  let streak: Int
  let streakPercentile: Int
}

struct CurrentMetricsDTO: Codable {
  let weight: Double
  let lastUpdated: String
  let change: Double
}

struct StreakDTO: Codable {
  let currentStreak: Int
  let streakPercentile: Int
}
