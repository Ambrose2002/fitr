//
//  HomeViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

internal import Combine
import Foundation

@MainActor
final class HomeViewModel: ObservableObject {
  @Published var homeData: HomeScreenData?
  @Published var isLoading = true
  @Published var errorMessage: String?

  private let homeService = HomeService()
  private let sessionStore: SessionStore
  private let skipFetch: Bool

  init(sessionStore: SessionStore, initialData: HomeScreenData? = nil) {
    self.sessionStore = sessionStore
    self.skipFetch = initialData != nil

    if let initialData = initialData {
      self.homeData = initialData
      self.isLoading = false
    }
  }

  func loadHomeData() async {
    // Skip fetch if initialized with data (e.g., preview mode)
    if skipFetch {
      return
    }

    isLoading = true
    errorMessage = nil

    defer {
      isLoading = false
    }

    do {
      let data = try await homeService.fetchHomeScreenData()
      let greeting = buildGreeting()
      let weekProgress =
        data.weekProgress.isEmpty ? "Let's make progress this week." : data.weekProgress

      self.homeData = HomeScreenData(
        greeting: greeting,
        weekProgress: weekProgress,
        nextSession: data.nextSession,
        lastWorkout: data.lastWorkout,
        currentWeight: data.currentWeight,
        weightChange: data.weightChange,
        streak: data.streak,
        streakPercentile: data.streakPercentile,
        weeklyWorkoutCount: data.weeklyWorkoutCount,
        weeklyTotalVolume: data.weeklyTotalVolume,
        weeklyCaloriesBurned: data.weeklyCaloriesBurned,
        weeklyAvgDuration: data.weeklyAvgDuration,
        weeklyPersonalRecords: data.weeklyPersonalRecords,
        weeklyExerciseVariety: data.weeklyExerciseVariety
      )
    } catch {
      self.errorMessage = error.localizedDescription
    }
  }

  private func buildGreeting() -> String {
    if let firstName = sessionStore.userProfile?.firstname, !firstName.isEmpty {
      return "G'day, \(firstName)!"
    }

    return "G'day!"
  }
}
