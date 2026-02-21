//
//  CreateProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//
internal import Combine

class CreateProfileViewModel: ObservableObject {

  @Published var isLoading: Bool = false
  @Published var profileCreated: Bool = false
  @Published var selectedGender: Gender? = .male
  @Published var selectedExperience: ExperienceLevel? = .beginner
  @Published var selectedGoal: Goal? = .strength
  @Published var selectedWeightUnit: WeightUnit = .kg
  @Published var selectedDistanceUnit: DistanceUnit = .km
  @Published var errorMessage: String?

  @Published var height = 180
  @Published var weight = 75

  let sessionStore: SessionStore
  let profileService: ProfileService = ProfileService()

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
  }

  public func createProfile() async {
    errorMessage = nil

    // Validate height and weight
    guard height > 0 else {
      errorMessage = "Height must be greater than 0"
      return
    }

    guard weight > 0 else {
      errorMessage = "Weight must be greater than 0"
      return
    }

    // Validate all required fields are selected
    guard let gender = selectedGender else {
      errorMessage = "Please select a gender"
      return
    }

    guard let experienceLevel = selectedExperience else {
      errorMessage = "Please select an experience level"
      return
    }

    guard let goal = selectedGoal else {
      errorMessage = "Please select a fitness goal"
      return
    }

    // Convert WeightUnit and DistanceUnit abbreviations to Unit enum
    guard let preferredWeightUnit = Unit(rawValue: selectedWeightUnit.abbreviation) else {
      errorMessage = "Invalid weight unit"
      return
    }

    guard let preferredDistanceUnit = Unit(rawValue: selectedDistanceUnit.abbreviation) else {
      errorMessage = "Invalid distance unit"
      return
    }

    isLoading = true

    do {
      defer { self.isLoading = false }

      let profileRequest = CreateUserProfileRequest(
        gender: gender,
        height: Float(height),
        weight: Float(weight),
        experienceLevel: experienceLevel,
        goal: goal,
        preferredWeightUnit: preferredWeightUnit,
        preferredDistanceUnit: preferredDistanceUnit
      )

      let profileResponse = try await profileService.createProfile(profileRequest)
      // Profile created successfully - update SessionStore with the new profile
      self.sessionStore.updateUserProfile(profileResponse)
      // Show success overlay
      self.profileCreated = true
      // Wait 1.5 seconds to show the success message, then navigate
      try? await Task.sleep(nanoseconds: 1_500_000_000)
      self.sessionStore.hasCreatedProfile = true
    } catch let apiError as APIErrorResponse {
      self.errorMessage = apiError.message
    } catch {
      self.errorMessage = "Failed to create profile. Please try again."
    }
  }
}
