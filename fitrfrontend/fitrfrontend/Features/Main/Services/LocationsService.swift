//
//  LocationsService.swift
//  fitrfrontend
//
//  Created by Codex on 3/2/26.
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
}
