//
//  LocationsService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/2/26.
//

import Foundation
import KeychainSwift

final class LocationsService {
  private var authToken: String? {
    KeychainSwift().get("userAccessToken")
  }

  private func addAuthHeaders(_ request: inout URLRequest) {
    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func makeURL(path: String) throws -> URL {
    guard let url = URL(string: Constants.baseUrl + path) else {
      throw URLError(.badURL)
    }

    return url
  }

  func fetchLocations() async throws -> [LocationResponse] {
    let url = try makeURL(path: APIEndpoints.locations)
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
      return try JSONDecoder().decode([LocationResponse].self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func createLocation(_ payload: CreateLocationRequest) async throws -> LocationResponse {
    let url = try makeURL(path: APIEndpoints.locations)
    var request = URLRequest(url: url)
    request.httpMethod = "POST"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try JSONDecoder().decode(LocationResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func updateLocation(id: Int64, request payload: CreateLocationRequest) async throws
    -> LocationResponse
  {
    guard let locationId = Int(exactly: id) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.location(id: locationId))
    var request = URLRequest(url: url)
    request.httpMethod = "PUT"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(payload)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try JSONDecoder().decode(LocationResponse.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func deleteLocation(id: Int64) async throws {
    guard let locationId = Int(exactly: id) else {
      throw URLError(.badURL)
    }

    let url = try makeURL(path: APIEndpoints.location(id: locationId))
    var request = URLRequest(url: url)
    request.httpMethod = "DELETE"
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }
}
