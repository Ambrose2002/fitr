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

