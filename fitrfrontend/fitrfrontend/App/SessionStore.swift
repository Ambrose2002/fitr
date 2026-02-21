//
//  SessionStore.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/9/26.
//

internal import Combine
import Foundation
import KeychainSwift

final class SessionStore: ObservableObject {
  enum AuthState {
    case loading
    case authenticated
    case unauthenticated
  }

  private let keychain = KeychainSwift()
  private let profileService = ProfileService()

  @Published private(set) var authState: AuthState = .loading
  @Published var hasCreatedProfile: Bool = false
  @Published var isCheckingProfile: Bool = false
  @Published var userProfile: UserProfileResponse? = nil

  @Published var accessToken: String? = nil {
    didSet {
      if let token = accessToken {
        keychain.set(token, forKey: "userAccessToken")
      } else {
        keychain.delete("userAccessToken")
      }
    }
  }

  init(skipRestore: Bool = false) {
    if !skipRestore {
      restoreSession()
    }
  }

  func restoreSession() {
    if let token = keychain.get("userAccessToken") {
      accessToken = token
      authState = .authenticated
      // Check if profile exists on the backend
      checkProfileOnBackend()
    } else {
      authState = .unauthenticated
    }
  }

  func login(_ loginResponse: LoginResponse) {
    self.accessToken = loginResponse.token
    authState = .authenticated
    // Check if profile exists on the backend
    checkProfileOnBackend()
  }

  func logout() {
    accessToken = nil
    hasCreatedProfile = false
    isCheckingProfile = false
    userProfile = nil
    authState = .unauthenticated
  }

  private func checkProfileOnBackend() {
    isCheckingProfile = true
    Task {
      do {
        let userResponse = try await profileService.getCurrentUser()
        // Check if user has created profile from backend response
        await MainActor.run {
          self.hasCreatedProfile = userResponse.isProfileCreated
          self.isCheckingProfile = false
          // If profile exists, fetch it
          if userResponse.isProfileCreated {
            Task {
              await self.fetchUserProfile()
            }
          }
        }
      } catch {
        // Token expired or other error - logout user
        await MainActor.run {
          self.logout()
        }
      }
    }
  }

  /// Fetches the user's profile from the backend and stores it in SessionStore
  private func fetchUserProfile() async {
    do {
      let profile = try await profileService.getProfile()
      await MainActor.run {
        self.userProfile = profile
      }
    } catch {
      // Log error but don't logout - profile fetch failure is not critical
      print("Failed to fetch user profile: \(error)")
    }
  }

  /// Updates the stored user profile in SessionStore after a successful API update
  /// - Parameter profile: The updated user profile from the API response
  func updateUserProfile(_ profile: UserProfileResponse) {
    self.userProfile = profile
  }
}

#if DEBUG
extension SessionStore {
  static func mock(userProfile: UserProfileResponse? = nil) -> SessionStore {
    let store = SessionStore(skipRestore: true)
    store.hasCreatedProfile = userProfile != nil
    store.userProfile = userProfile
    return store
  }
}
#endif
