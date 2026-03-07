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
  struct HeaderStats {
    var workoutsCount: String
    var streakWeeks: String
  }

  struct RowSubtitles {
    var personalInfo: String
    var locations: String
    var units: String
    var appVersion: String
  }

  @Published private(set) var isLoading = false
  @Published private(set) var errorMessage: String?
  @Published private(set) var displayName = "Your Profile"
  @Published private(set) var email = "No email on file"
  @Published private(set) var profile: UserProfileResponse?
  @Published private(set) var headerStats = HeaderStats(workoutsCount: "0", streakWeeks: "0 w")
  @Published private(set) var rowSubtitles = RowSubtitles(
    personalInfo: "Name, email, gender, goals",
    locations: "No saved locations yet",
    units: "Weight: KG • Distance: KM",
    appVersion: ProfileViewModel.appVersionString
  )

  private let sessionStore: SessionStore
  private let profileService: ProfileService
  private let workoutsService: WorkoutsService
  private let locationsService: LocationsService
  private var hasLoaded = false
  private var cancellables = Set<AnyCancellable>()

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
      }
      .store(in: &cancellables)
    applyProfile(sessionStore.userProfile)
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
    if isLoading {
      return
    }

    if hasLoaded && !forceRefresh {
      return
    }

    isLoading = true
    errorMessage = nil
    hasLoaded = true

    if let cachedProfile = sessionStore.userProfile {
      applyProfile(cachedProfile)
    }

    async let profileRequest = fetchProfile()
    async let workoutsRequest = fetchWorkouts()
    async let locationsRequest = fetchLocations()

    let (profileResult, workoutsResult, locationsResult) = await (
      profileRequest, workoutsRequest, locationsRequest)

    var encounteredError = false

    switch profileResult {
    case .success(let profile):
      sessionStore.updateUserProfile(profile)
      applyProfile(profile)
    case .failure:
      encounteredError = true
      if sessionStore.userProfile == nil {
        applyProfile(nil)
      }
    }

    switch workoutsResult {
    case .success(let workouts):
      applyWorkoutStats(from: workouts)
    case .failure:
      encounteredError = true
    }

    switch locationsResult {
    case .success(let locations):
      applyLocationSummary(locations.count)
    case .failure:
      encounteredError = true
    }

    if encounteredError {
      errorMessage = "Some profile details couldn't be refreshed."
    }

    isLoading = false
  }

  func logout() {
    sessionStore.logout()
  }

  private func fetchProfile() async -> Result<UserProfileResponse, Error> {
    do {
      return .success(try await profileService.getProfile())
    } catch {
      return .failure(error)
    }
  }

  private func fetchWorkouts() async -> Result<[WorkoutSessionResponse], Error> {
    do {
      return .success(try await workoutsService.fetchWorkoutHistory())
    } catch {
      return .failure(error)
    }
  }

  private func fetchLocations() async -> Result<[LocationResponse], Error> {
    do {
      return .success(try await locationsService.fetchLocations())
    } catch {
      return .failure(error)
    }
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
