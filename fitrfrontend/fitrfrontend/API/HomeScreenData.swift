//
//  HomeScreenData.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation
import SwiftUI

struct HomeScreenData: Codable {
  let greeting: String
  let weekProgress: String
  let nextSession: WorkoutSessionResponse?
  let lastWorkout: WorkoutSessionResponse?
  let currentWeight: String
  let weightChange: String
  let streak: Int
  let streakPercentile: Int
  let weeklyWorkoutCount: Int
  let weeklyTotalVolume: String
  let weeklyCaloriesBurned: String
  let weeklyAvgDuration: String
  let weeklyPersonalRecords: [String]
  let weeklyExerciseVariety: Int
  var lastSessionExerciseStats: [WorkoutExerciseStats]

  enum CodingKeys: String, CodingKey {
    case greeting, weekProgress, nextSession, lastWorkout, currentWeight, weightChange
    case streak, streakPercentile, weeklyWorkoutCount, weeklyTotalVolume
    case weeklyCaloriesBurned, weeklyAvgDuration, weeklyPersonalRecords, weeklyExerciseVariety
    // Note: lastSessionExerciseStats is excluded - it's calculated on frontend
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    greeting = try container.decode(String.self, forKey: .greeting)
    weekProgress = try container.decode(String.self, forKey: .weekProgress)
    nextSession = try container.decodeIfPresent(WorkoutSessionResponse.self, forKey: .nextSession)
    lastWorkout = try container.decodeIfPresent(WorkoutSessionResponse.self, forKey: .lastWorkout)
    currentWeight = try container.decode(String.self, forKey: .currentWeight)
    weightChange = try container.decode(String.self, forKey: .weightChange)
    streak = try container.decode(Int.self, forKey: .streak)
    streakPercentile = try container.decode(Int.self, forKey: .streakPercentile)
    weeklyWorkoutCount = try container.decode(Int.self, forKey: .weeklyWorkoutCount)
    weeklyTotalVolume = try container.decode(String.self, forKey: .weeklyTotalVolume)
    weeklyCaloriesBurned = try container.decode(String.self, forKey: .weeklyCaloriesBurned)
    weeklyAvgDuration = try container.decode(String.self, forKey: .weeklyAvgDuration)
    weeklyPersonalRecords = try container.decode([String].self, forKey: .weeklyPersonalRecords)
    weeklyExerciseVariety = try container.decode(Int.self, forKey: .weeklyExerciseVariety)
    lastSessionExerciseStats = []  // Calculated on frontend
  }

  func encode(to encoder: Encoder) throws {
    var container = encoder.container(keyedBy: CodingKeys.self)
    try container.encode(greeting, forKey: .greeting)
    try container.encode(weekProgress, forKey: .weekProgress)
    try container.encodeIfPresent(nextSession, forKey: .nextSession)
    try container.encodeIfPresent(lastWorkout, forKey: .lastWorkout)
    try container.encode(currentWeight, forKey: .currentWeight)
    try container.encode(weightChange, forKey: .weightChange)
    try container.encode(streak, forKey: .streak)
    try container.encode(streakPercentile, forKey: .streakPercentile)
    try container.encode(weeklyWorkoutCount, forKey: .weeklyWorkoutCount)
    try container.encode(weeklyTotalVolume, forKey: .weeklyTotalVolume)
    try container.encode(weeklyCaloriesBurned, forKey: .weeklyCaloriesBurned)
    try container.encode(weeklyAvgDuration, forKey: .weeklyAvgDuration)
    try container.encode(weeklyPersonalRecords, forKey: .weeklyPersonalRecords)
    try container.encode(weeklyExerciseVariety, forKey: .weeklyExerciseVariety)
    // Note: lastSessionExerciseStats is excluded - it's calculated on frontend
  }

  // Convenience initializer for creating instances with all fields
  init(
    greeting: String,
    weekProgress: String,
    nextSession: WorkoutSessionResponse? = nil,
    lastWorkout: WorkoutSessionResponse? = nil,
    currentWeight: String,
    weightChange: String,
    streak: Int,
    streakPercentile: Int,
    weeklyWorkoutCount: Int,
    weeklyTotalVolume: String,
    weeklyCaloriesBurned: String,
    weeklyAvgDuration: String,
    weeklyPersonalRecords: [String],
    weeklyExerciseVariety: Int,
    lastSessionExerciseStats: [WorkoutExerciseStats] = []
  ) {
    self.greeting = greeting
    self.weekProgress = weekProgress
    self.nextSession = nextSession
    self.lastWorkout = lastWorkout
    self.currentWeight = currentWeight
    self.weightChange = weightChange
    self.streak = streak
    self.streakPercentile = streakPercentile
    self.weeklyWorkoutCount = weeklyWorkoutCount
    self.weeklyTotalVolume = weeklyTotalVolume
    self.weeklyCaloriesBurned = weeklyCaloriesBurned
    self.weeklyAvgDuration = weeklyAvgDuration
    self.weeklyPersonalRecords = weeklyPersonalRecords
    self.weeklyExerciseVariety = weeklyExerciseVariety
    self.lastSessionExerciseStats = lastSessionExerciseStats
  }

  // MARK: - Computed Display Properties

  var nextSessionTitle: String {
    nextSession?.title ?? "Workout"
  }

  var nextSessionExerciseCount: String {
    let count = nextSession?.workoutExercises.count ?? 0
    return "\(count) Move\(count != 1 ? "s" : "")"
  }

  var lastWorkoutTitle: String {
    lastWorkout?.title ?? "Last Workout"
  }

  var lastWorkoutRelativeDate: String {
    guard let startTime = lastWorkout?.startTime else { return "" }
    return DateFormatter.relativeDate(from: startTime)
  }

  var lastWorkoutDuration: String? {
    guard let endTime = lastWorkout?.endTime else { return nil }
    let duration = endTime.timeIntervalSince(lastWorkout?.startTime ?? Date())
    let minutes = Int(duration / 60)
    if minutes < 1 {
      return "< 1 min"
    }
    return "\(minutes) min\(minutes != 1 ? "s" : "")"
  }

  var personalRecordsDisplay: String {
    weeklyPersonalRecords.prefix(3).joined(separator: ", ")
  }
}

// MARK: - Skeleton Loader Card
struct SkeletonCard: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.systemGray5))
          .frame(height: 16)
          .frame(maxWidth: 100)

        Spacer()
      }

      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray5))
        .frame(height: 24)

      HStack(spacing: 16) {
        RoundedRectangle(cornerRadius: 8)
          .fill(Color(.systemGray5))
          .frame(width: 48, height: 48)

        VStack(alignment: .leading, spacing: 4) {
          RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
            .frame(height: 12)

          RoundedRectangle(cornerRadius: 4)
            .fill(Color(.systemGray5))
            .frame(height: 12)
            .frame(maxWidth: 150)
        }

        Spacer()
      }
    }
    .padding(16)
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .padding(.horizontal, 16)
    .redacted(reason: .placeholder)
    .shimmer()
  }
}

// MARK: - Shimmer Animation Extension
extension View {
  func shimmer() -> some View {
    modifier(ShimmerModifier())
  }
}

struct ShimmerModifier: ViewModifier {
  @State private var isShimmering = false

  func body(content: Content) -> some View {
    content
      .overlay(
        LinearGradient(
          gradient: Gradient(stops: [
            .init(color: .clear, location: 0),
            .init(color: Color.white.opacity(0.3), location: 0.5),
            .init(color: .clear, location: 1),
          ]),
          startPoint: .leading,
          endPoint: .trailing
        )
        .offset(x: isShimmering ? 400 : -400)
        .animation(.linear(duration: 2).repeatForever(autoreverses: false), value: isShimmering)
      )
      .onAppear {
        isShimmering = true
      }
  }
}
