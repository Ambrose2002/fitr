//
//  ProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/6/26.
//

import Foundation
internal import Combine

@MainActor
final class ProfileViewModel: ObservableObject {
  private enum FetchOutcome<Value> {
    case success(Value)
    case failure(Error)
    case cancelled
  }

  struct HeaderStats {
    var workoutsCount: String
    var streakWeeks: String
  }

  struct RowSubtitles {
    var personalInfo: String
    var locations: String
    var exercises: String
    var units: String
    var appVersion: String
  }

  @Published private(set) var isLoading = true
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var displayName = "Your Profile"
  @Published private(set) var email = "No email on file"
  @Published private(set) var profile: UserProfileResponse?
  @Published private(set) var headerStats = HeaderStats(workoutsCount: "0", streakWeeks: "0 w")
  @Published private(set) var rowSubtitles = RowSubtitles(
    personalInfo: "Name, email, gender, goals",
    locations: "No saved locations yet",
    exercises: "Create and edit custom exercises",
    units: "Weight: KG • Distance: KM",
    appVersion: ProfileViewModel.appVersionString
  )

  private let sessionStore: SessionStore
  private let profileService: ProfileService
  private let workoutsService: WorkoutsService
  private let locationsService: LocationsService
  private var cancellables = Set<AnyCancellable>()
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  private static let groupedIntegerFormatter: NumberFormatter = {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.locale = Locale.current
    return formatter
  }()

  private static var appVersionString: String {
    let info = Bundle.main.infoDictionary
    let version = info?["CFBundleShortVersionString"] as? String
    let build = info?["CFBundleVersion"] as? String

    if let version, let build, version != build {
      return "v\(version) (\(build))"
    }

    if let version {
      return "v\(version)"
    }

    if let build {
      return "Build \(build)"
    }

    return "Version unavailable"
  }

  init(
    sessionStore: SessionStore,
    profileService: ProfileService,
    workoutsService: WorkoutsService,
    locationsService: LocationsService
  ) {
    self.sessionStore = sessionStore
    self.profileService = profileService
    self.workoutsService = workoutsService
    self.locationsService = locationsService
    sessionStore.$userProfile
      .receive(on: RunLoop.main)
      .sink { [weak self] profile in
        self?.applyProfile(profile)
        if profile != nil {
          self?.hasLoadedSnapshot = true
          self?.lastLoadedAt = Date()
        }
      }
      .store(in: &cancellables)
    applyProfile(sessionStore.userProfile)
    if sessionStore.userProfile != nil {
      hasLoadedSnapshot = true
      lastLoadedAt = Date()
      isLoading = false
    }
  }

  convenience init(sessionStore: SessionStore) {
    self.init(
      sessionStore: sessionStore,
      profileService: ProfileService(),
      workoutsService: WorkoutsService(),
      locationsService: LocationsService()
    )
  }

  func load(forceRefresh: Bool = false) async {
    guard !isFetching else {
      return
    }

    if
      !forceRefresh,
      let lastLoadedAt,
      Date().timeIntervalSince(lastLoadedAt) < freshnessInterval
    {
      return
    }

    let shouldBlockUI = !hasLoadedSnapshot
    isFetching = true
    if shouldBlockUI {
      isLoading = true
    } else {
      isRefreshing = true
    }
    errorMessage = nil
    if let cachedProfile = sessionStore.userProfile {
      applyProfile(cachedProfile)
    }

    defer {
      isFetching = false
      if shouldBlockUI {
        isLoading = false
      } else {
        isRefreshing = false
      }
    }

    async let profileRequest = fetchProfile()
    async let workoutsRequest = fetchWorkouts()
    async let locationsRequest = fetchLocations()

    let (profileResult, workoutsResult, locationsResult) = await (
      profileRequest, workoutsRequest, locationsRequest)

    let hadCachedProfile = sessionStore.userProfile != nil || hasLoadedSnapshot
    var didRefreshPrimaryProfile = false

    switch profileResult {
    case .success(let profile):
      sessionStore.updateUserProfile(profile)
      applyProfile(profile)
      didRefreshPrimaryProfile = true
    case .failure(let error):
      if !hadCachedProfile {
        applyProfile(nil)
        errorMessage = resolveErrorMessage(
          error,
          fallback: "Couldn't refresh your profile right now."
        )
      }
    case .cancelled:
      break
    }

    switch workoutsResult {
    case .success(let workouts):
      applyWorkoutStats(from: workouts)
    case .failure:
      break
    case .cancelled:
      break
    }

    switch locationsResult {
    case .success(let locations):
      applyLocationSummary(locations.count)
    case .failure:
      break
    case .cancelled:
      break
    }

    if didRefreshPrimaryProfile {
      lastLoadedAt = Date()
      hasLoadedSnapshot = true
    }
  }

  func logout() {
    sessionStore.logout()
  }

  func applyLocationCount(_ count: Int) {
    applyLocationSummary(count)
    hasLoadedSnapshot = true
    lastLoadedAt = Date()
  }

  func invalidateFreshness() {
    lastLoadedAt = nil
  }

  private func fetchProfile() async -> FetchOutcome<UserProfileResponse> {
    do {
      return .success(try await profileService.getProfile())
    } catch {
      return error.isCancellation ? .cancelled : .failure(error)
    }
  }

  private func fetchWorkouts() async -> FetchOutcome<[WorkoutSessionResponse]> {
    do {
      return .success(try await workoutsService.fetchWorkoutHistory())
    } catch {
      return error.isCancellation ? .cancelled : .failure(error)
    }
  }

  private func fetchLocations() async -> FetchOutcome<[LocationResponse]> {
    do {
      return .success(try await locationsService.fetchLocations())
    } catch {
      return error.isCancellation ? .cancelled : .failure(error)
    }
  }

  private func resolveErrorMessage(_ error: Error, fallback: String) -> String {
    if let apiError = error as? APIErrorResponse {
      return apiError.message
    }

    return fallback
  }

  private func applyProfile(_ profile: UserProfileResponse?) {
    self.profile = profile

    guard let profile else {
      displayName = "Your Profile"
      email = "No email on file"
      rowSubtitles.personalInfo = "Name, email, gender, goals"
      rowSubtitles.units = "Weight: KG • Distance: KM"
      return
    }

    let firstName = profile.firstname.trimmingCharacters(in: .whitespacesAndNewlines)
    let lastName = profile.lastname.trimmingCharacters(in: .whitespacesAndNewlines)
    let fullName = [firstName, lastName].filter { !$0.isEmpty }.joined(separator: " ")
    let resolvedName = fullName.isEmpty ? "Your Profile" : fullName
    let resolvedEmail =
      profile.email.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      ? "No email on file" : profile.email

    displayName = resolvedName
    email = resolvedEmail

    rowSubtitles.personalInfo =
      "\(resolvedEmail), \(profile.gender.representation), \(profile.goal.representation) goal"
    rowSubtitles.units =
      "Weight: \(profile.preferredWeightUnit.rawValue) • Distance: \(profile.preferredDistanceUnit.rawValue)"
  }

  private func applyWorkoutStats(from workouts: [WorkoutSessionResponse]) {
    let completedWorkouts = workouts.filter { $0.endTime != nil }
    let streakWeeks = WeeklyStreakCalculator.calculate(workoutDates: completedWorkouts.map(\.startTime))

    headerStats = HeaderStats(
      workoutsCount: formatInteger(completedWorkouts.count),
      streakWeeks: "\(streakWeeks) w"
    )
  }

  private func applyLocationSummary(_ count: Int) {
    if count <= 0 {
      rowSubtitles.locations = "No saved locations yet"
      return
    }

    let pluralSuffix = count == 1 ? "" : "s"
    rowSubtitles.locations = "\(formatInteger(count)) saved location\(pluralSuffix)"
  }

  private func formatInteger(_ value: Int) -> String {
    if let formatted = Self.groupedIntegerFormatter.string(from: NSNumber(value: value)) {
      return formatted
    }
    return "\(value)"
  }
}
