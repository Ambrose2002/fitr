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

  @Published var accessToken: String? = nil {
    didSet {
      if let token = accessToken {
        keychain.set(token, forKey: "userAccessToken")
      } else {
        keychain.delete("userAccessToken")
      }
    }
  }

  init() {
    restoreSession()
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
    authState = .unauthenticated
  }

  private func checkProfileOnBackend() {
    isCheckingProfile = true
    Task {
      do {
        _ = try await profileService.getProfile()
        // Profile exists
        await MainActor.run {
          self.hasCreatedProfile = true
          self.isCheckingProfile = false
        }
      } catch {
        // Profile doesn't exist or error occurred
        await MainActor.run {
          self.hasCreatedProfile = false
          self.isCheckingProfile = false
        }
      }
    }
  }
}
