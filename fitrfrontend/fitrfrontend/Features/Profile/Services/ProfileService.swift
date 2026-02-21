//
//  ProfileService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/19/26.
//

import Foundation
import KeychainSwift

struct ProfileService {

  private var authToken: String? {
    KeychainSwift().get("userAccessToken")
  }

  private func addAuthHeaders(_ request: inout URLRequest) {
    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .iso8601
    return decoder
  }

  // MARK: - User Profile

  /// Fetches the current user's profile
  func getProfile() async throws -> UserProfileResponse {

    guard let url = URL(string: Constants.baseUrl + APIEndpoints.userProfile) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(UserProfileResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Creates a new user profile
  func createProfile(_ profileRequest: CreateUserProfileRequest) async throws -> UserProfileResponse
  {

    guard let url = URL(string: Constants.baseUrl + APIEndpoints.userProfile) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(profileRequest)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(UserProfileResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Updates the current user's profile
  func updateProfile(_ profileRequest: CreateUserProfileRequest) async throws -> UserProfileResponse
  {

    guard let url = URL(string: Constants.baseUrl + APIEndpoints.userProfile) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(profileRequest)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(UserProfileResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  // MARK: - User

  /// Fetches the current user's information
  func getCurrentUser() async throws -> UserResponse {

    guard let url = URL(string: Constants.baseUrl + APIEndpoints.currentUser) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "GET"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(UserResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }

  /// Updates the current user's basic information (firstname, lastname)
  func updateUser(_ userRequest: UpdateUserRequest) async throws -> UserResponse {

    guard let url = URL(string: Constants.baseUrl + APIEndpoints.currentUser) else {
      throw URLError(.badURL)
    }

    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(userRequest)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try JSONDecoder().decode(UserResponse.self, from: data)

    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.unknown)

    default:
      throw URLError(.unknown)
    }
  }
}
