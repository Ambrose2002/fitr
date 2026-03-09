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
  @Published var isRefreshing = false
  @Published var errorMessage: String?

  private let homeService: HomeService
  private let sessionStore: SessionStore
  private let skipFetch: Bool
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(sessionStore: SessionStore, initialData: HomeScreenData? = nil) {
    self.sessionStore = sessionStore
    self.homeService = HomeService(sessionStore: sessionStore)
    self.skipFetch = initialData != nil

    if let initialData = initialData {
      self.homeData = initialData
      self.isLoading = false
      self.lastLoadedAt = Date()
    }
  }

  func loadHomeData(forceRefresh: Bool = false) async {
    // Skip fetch if initialized with data (e.g., preview mode), unless forcing refresh
    if skipFetch && !forceRefresh {
      return
    }

    guard !isFetching else { return }

    if
      !forceRefresh,
      let lastLoadedAt,
      Date().timeIntervalSince(lastLoadedAt) < freshnessInterval
    {
      return
    }

    let shouldBlockUI = homeData == nil
    isFetching = true
    if shouldBlockUI {
      isLoading = true
    } else {
      isRefreshing = true
    }
    errorMessage = nil

    defer {
      isFetching = false
      if shouldBlockUI {
        isLoading = false
      } else {
        isRefreshing = false
      }
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
        weeklyExerciseVariety: data.weeklyExerciseVariety,
        lastSessionExerciseStats: data.lastSessionExerciseStats
      )
      errorMessage = nil
      lastLoadedAt = Date()
    } catch {
      if error.isCancellation {
        return
      }
      self.errorMessage = error.localizedDescription
    }
  }

  func invalidateFreshness() {
    lastLoadedAt = nil
  }

  private func buildGreeting() -> String {
    if let firstName = sessionStore.userProfile?.firstname, !firstName.isEmpty {
      return "G'day, \(firstName)!"
    }

    return "G'day!"
  }
}
