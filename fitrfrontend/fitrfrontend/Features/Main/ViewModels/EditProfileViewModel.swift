//
//  EditProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/7/26.
//

import Foundation
internal import Combine

struct EditProfileSnapshot {
  let profile: UserProfileResponse
}

@MainActor
final class EditProfileViewModel: ObservableObject {
  enum SaveResult {
    case saved
    case noChanges
    case failed
  }

  @Published var firstName: String = ""
  @Published var lastName: String = ""
  @Published private(set) var email: String = ""
  @Published var selectedGender: Gender? = .male
  @Published var selectedExperience: ExperienceLevel? = .beginner
  @Published var selectedGoal: Goal? = .strength
  @Published var selectedWeightUnit: WeightUnit = .kg {
    didSet {
      convertWeightForUnitChange(from: oldValue, to: selectedWeightUnit)
    }
  }
  @Published var selectedDistanceUnit: DistanceUnit = .km
  @Published var height: Float = 180
  @Published var weight: Float = 75
  @Published private(set) var isLoading = false
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published private(set) var isSaving = false
  @Published var errorMessage: String?

  var isDirty: Bool {
    guard let baseline else {
      return false
    }

    guard let current = currentSnapshot() else {
      return true
    }

    return current != baseline
  }

  private let sessionStore: SessionStore
  private let profileService: ProfileService
  private var baseline: FormSnapshot?
  private var latestProfile: UserProfileResponse?
  private var isApplyingProfile = false
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(
    sessionStore: SessionStore,
    profileService: ProfileService
  ) {
    self.sessionStore = sessionStore
    self.profileService = profileService

    if let cachedSnapshot = restoreSnapshotIfAvailable() {
      applyProfile(cachedSnapshot.value.profile)
      hasLoadedSnapshot = true
      lastLoadedAt = cachedSnapshot.lastLoadedAt
    } else if let cachedProfile = sessionStore.userProfile {
      applyProfile(cachedProfile)
      let loadedAt = Date()
      hasLoadedSnapshot = true
      lastLoadedAt = loadedAt
      persistSnapshot(profile: cachedProfile, loadedAt: loadedAt)
    }
  }

  convenience init(sessionStore: SessionStore) {
    self.init(sessionStore: sessionStore, profileService: ProfileService())
  }

  func loadLatestProfile(forceRefresh: Bool = false) async {
    if isFetching {
      return
    }

    restoreSnapshotIfNewer()

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
    defer {
      isFetching = false
      if shouldBlockUI {
        isLoading = false
      } else {
        isRefreshing = false
      }
    }

    do {
      let profile = try await profileService.getProfile()
      sessionStore.updateUserProfile(profile)
      applyProfile(profile)
      let loadedAt = Date()
      hasLoadedSnapshot = true
      lastLoadedAt = loadedAt
      persistSnapshot(profile: profile, loadedAt: loadedAt)
    } catch let apiError as APIErrorResponse {
      if !hasLoadedSnapshot {
        errorMessage = apiError.message
      } else {
        errorMessage = "Couldn't refresh profile details."
      }
    } catch {
      if error.isCancellation {
        return
      }
      if !hasLoadedSnapshot {
        errorMessage = "Failed to load profile details."
      } else {
        errorMessage = "Couldn't refresh profile details."
      }
    }
  }

  func saveChanges() async -> SaveResult {
    if isSaving {
      return .failed
    }

    errorMessage = nil

    guard let baseline else {
      errorMessage = "Profile details are unavailable right now."
      return .failed
    }

    let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedFirstName.isEmpty else {
      errorMessage = "First name cannot be empty."
      return .failed
    }

    guard !trimmedLastName.isEmpty else {
      errorMessage = "Last name cannot be empty."
      return .failed
    }

    guard let selectedGender else {
      errorMessage = "Please select a gender."
      return .failed
    }

    guard let selectedExperience else {
      errorMessage = "Please select an experience level."
      return .failed
    }

    guard let selectedGoal else {
      errorMessage = "Please select a fitness goal."
      return .failed
    }

    let preferredWeightUnit = mapWeightUnitToApi(selectedWeightUnit)
    let preferredDistanceUnit = mapDistanceUnitToApi(selectedDistanceUnit)

    let normalizedHeight = UnitConverter.round(height, decimalPlaces: 1)
    let normalizedWeight = UnitConverter.round(
      UnitConverter.convertWeight(weight, from: preferredWeightUnit, to: .kg),
      decimalPlaces: 1
    )

    guard normalizedHeight > 0 else {
      errorMessage = "Height must be greater than 0."
      return .failed
    }

    guard normalizedWeight > 0 else {
      errorMessage = "Weight must be greater than 0."
      return .failed
    }

    let nameChanged =
      trimmedFirstName != baseline.firstName || trimmedLastName != baseline.lastName
    let heightChanged = normalizedHeight != baseline.heightCm
    let weightChanged = normalizedWeight != baseline.weightKg
    let profileChanged =
      selectedGender != baseline.gender
      || selectedExperience != baseline.experience
      || selectedGoal != baseline.goal
      || selectedWeightUnit != baseline.weightUnit
      || selectedDistanceUnit != baseline.distanceUnit
      || heightChanged
      || weightChanged

    if !nameChanged && !profileChanged {
      return .noChanges
    }

    isSaving = true
    defer { isSaving = false }

    do {
      if nameChanged {
        _ = try await profileService.updateUser(
          UpdateUserRequest(firstname: trimmedFirstName, lastname: trimmedLastName)
        )
      }

      var updatedProfile: UserProfileResponse?

      if profileChanged {
        let profileRequest = CreateUserProfileRequest(
          gender: selectedGender,
          height: heightChanged ? normalizedHeight : 0,
          weight: weightChanged ? normalizedWeight : 0,
          experienceLevel: selectedExperience,
          goal: selectedGoal,
          preferredWeightUnit: preferredWeightUnit,
          preferredDistanceUnit: preferredDistanceUnit
        )
        updatedProfile = try await profileService.updateProfile(profileRequest)
      }

      let finalProfile: UserProfileResponse

      if let updatedProfile {
        finalProfile = updatedProfile
      } else {
        do {
          finalProfile = try await profileService.getProfile()
        } catch {
          if let fallbackProfile = makeNameUpdatedProfile(
            firstName: trimmedFirstName,
            lastName: trimmedLastName
          ) {
            finalProfile = fallbackProfile
          } else {
            throw error
          }
        }
      }

      sessionStore.updateUserProfile(finalProfile)
      applyProfile(finalProfile)
      let loadedAt = Date()
      hasLoadedSnapshot = true
      lastLoadedAt = loadedAt
      persistSnapshot(profile: finalProfile, loadedAt: loadedAt)
      return .saved
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
      return .failed
    } catch {
      errorMessage = "Failed to save changes. Please try again."
      return .failed
    }
  }

  private func applyProfile(_ profile: UserProfileResponse) {
    isApplyingProfile = true
    defer { isApplyingProfile = false }

    latestProfile = profile

    firstName = profile.firstname.trimmingCharacters(in: .whitespacesAndNewlines)
    lastName = profile.lastname.trimmingCharacters(in: .whitespacesAndNewlines)
    email = profile.email

    selectedGender = profile.gender
    selectedExperience = profile.experience
    selectedGoal = profile.goal

    let weightUnit = mapApiUnitToWeightUnit(profile.preferredWeightUnit)
    selectedWeightUnit = weightUnit
    selectedDistanceUnit = mapApiUnitToDistanceUnit(profile.preferredDistanceUnit)

    height = UnitConverter.round(profile.height, decimalPlaces: 1)
    let displayedWeight = UnitConverter.convertWeight(
      profile.weight,
      from: .kg,
      to: mapWeightUnitToApi(weightUnit)
    )
    weight = UnitConverter.round(displayedWeight, decimalPlaces: 1)

    baseline = currentSnapshot()
  }

  private func convertWeightForUnitChange(from oldValue: WeightUnit, to newValue: WeightUnit) {
    if isApplyingProfile || oldValue == newValue {
      return
    }

    let convertedWeight = UnitConverter.convertWeight(
      weight,
      from: mapWeightUnitToApi(oldValue),
      to: mapWeightUnitToApi(newValue)
    )

    if convertedWeight > 0 {
      weight = UnitConverter.round(convertedWeight, decimalPlaces: 1)
    }
  }

  private func currentSnapshot() -> FormSnapshot? {
    guard let selectedGender, let selectedExperience, let selectedGoal else {
      return nil
    }

    let preferredWeightUnit = mapWeightUnitToApi(selectedWeightUnit)
    let normalizedWeight = UnitConverter.round(
      UnitConverter.convertWeight(weight, from: preferredWeightUnit, to: .kg),
      decimalPlaces: 1
    )
    let normalizedHeight = UnitConverter.round(height, decimalPlaces: 1)

    return FormSnapshot(
      firstName: firstName.trimmingCharacters(in: .whitespacesAndNewlines),
      lastName: lastName.trimmingCharacters(in: .whitespacesAndNewlines),
      gender: selectedGender,
      heightCm: normalizedHeight,
      weightKg: normalizedWeight,
      experience: selectedExperience,
      goal: selectedGoal,
      weightUnit: selectedWeightUnit,
      distanceUnit: selectedDistanceUnit
    )
  }

  private func mapApiUnitToWeightUnit(_ unit: Unit) -> WeightUnit {
    unit == .lb ? .lb : .kg
  }

  private func mapApiUnitToDistanceUnit(_ unit: Unit) -> DistanceUnit {
    unit == .mi ? .mi : .km
  }

  private func mapWeightUnitToApi(_ unit: WeightUnit) -> Unit {
    unit == .lb ? .lb : .kg
  }

  private func mapDistanceUnitToApi(_ unit: DistanceUnit) -> Unit {
    unit == .mi ? .mi : .km
  }

  private func makeNameUpdatedProfile(firstName: String, lastName: String) -> UserProfileResponse? {
    guard let latestProfile else {
      return nil
    }

    return UserProfileResponse(
      id: latestProfile.id,
      userId: latestProfile.userId,
      firstname: firstName,
      lastname: lastName,
      email: latestProfile.email,
      gender: latestProfile.gender,
      height: latestProfile.height,
      weight: latestProfile.weight,
      experience: latestProfile.experience,
      goal: latestProfile.goal,
      preferredWeightUnit: latestProfile.preferredWeightUnit,
      preferredDistanceUnit: latestProfile.preferredDistanceUnit,
      createdAt: latestProfile.createdAt
    )
  }

  private func persistSnapshot(profile: UserProfileResponse, loadedAt: Date) {
    sessionStore.runtimeViewCache.store(
      EditProfileSnapshot(profile: profile),
      for: .editProfile,
      at: loadedAt
    )
  }

  private func restoreSnapshotIfAvailable() -> RuntimeViewCacheSnapshot<EditProfileSnapshot>? {
    sessionStore.runtimeViewCache.snapshot(for: .editProfile, as: EditProfileSnapshot.self)
  }

  private func restoreSnapshotIfNewer() {
    guard let cachedSnapshot = restoreSnapshotIfAvailable() else {
      return
    }

    if let lastLoadedAt, cachedSnapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    applyProfile(cachedSnapshot.value.profile)
    hasLoadedSnapshot = true
    lastLoadedAt = cachedSnapshot.lastLoadedAt
  }
}

private struct FormSnapshot: Equatable {
  let firstName: String
  let lastName: String
  let gender: Gender
  let heightCm: Float
  let weightKg: Float
  let experience: ExperienceLevel
  let goal: Goal
  let weightUnit: WeightUnit
  let distanceUnit: DistanceUnit
}
