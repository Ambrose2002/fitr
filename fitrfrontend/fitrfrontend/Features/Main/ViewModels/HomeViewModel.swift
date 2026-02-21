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

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
  }

  func loadHomeData() async {
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
        streakPercentile: data.streakPercentile
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
