//
//  BodyMetricsService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/3/26.
//

import Foundation
import KeychainSwift

final class BodyMetricsService {
  private var authToken: String? {
    KeychainSwift().get("userAccessToken")
  }

  private static let fractionalSecondsDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
    return formatter
  }()

  private static let standardDateFormatter: ISO8601DateFormatter = {
    let formatter = ISO8601DateFormatter()
    formatter.formatOptions = [.withInternetDateTime]
    return formatter
  }()

  private func addAuthHeaders(_ request: inout URLRequest) {
    if let token = authToken {
      request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
    }
  }

  private func createDecoder() -> JSONDecoder {
    let decoder = JSONDecoder()
    decoder.dateDecodingStrategy = .custom { decoder in
      let container = try decoder.singleValueContainer()
      let dateString = try container.decode(String.self)

      if let date = Self.fractionalSecondsDateFormatter.date(from: dateString)
        ?? Self.standardDateFormatter.date(from: dateString)
      {
        return date
      }

      throw DecodingError.dataCorruptedError(
        in: container,
        debugDescription: "Invalid date format: \(dateString)"
      )
    }
    return decoder
  }

  private func makeURL(path: String, queryItems: [URLQueryItem] = []) throws -> URL {
    guard var components = URLComponents(string: Constants.baseUrl + path) else {
      throw URLError(.badURL)
    }

    if !queryItems.isEmpty {
      components.queryItems = queryItems
    }

    guard let url = components.url else {
      throw URLError(.badURL)
    }

    return url
  }

  private func performRequest<T: Decodable>(_ url: URL) async throws -> T {
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
      return try createDecoder().decode(T.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  private func performRequest<T: Decodable, B: Encodable>(
    _ url: URL,
    method: String,
    body: B
  ) async throws -> T {
    var request = URLRequest(url: url)
    request.httpMethod = method
    request.setValue("application/json", forHTTPHeaderField: "Content-Type")
    addAuthHeaders(&request)
    request.httpBody = try JSONEncoder().encode(body)

    let (data, response) = try await URLSession.shared.data(for: request)

    guard let httpResponse = response as? HTTPURLResponse else {
      throw URLError(.badServerResponse)
    }

    switch httpResponse.statusCode {
    case 200...299:
      return try createDecoder().decode(T.self, from: data)
    case 400...599:
      if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
        throw apiError
      }
      throw URLError(.badServerResponse)
    default:
      throw URLError(.unknown)
    }
  }

  func fetchBodyMetrics(
    metricType: MetricType? = nil,
    limit: Int? = nil,
    fromDate: Date? = nil,
    toDate: Date? = nil
  ) async throws -> [BodyMetricResponse] {
    var queryItems: [URLQueryItem] = []

    if let metricType {
      queryItems.append(URLQueryItem(name: "metricType", value: metricType.rawValue))
    }

    if let limit {
      queryItems.append(URLQueryItem(name: "limit", value: "\(limit)"))
    }

    if let fromDate {
      queryItems.append(
        URLQueryItem(
          name: "fromDate",
          value: Self.standardDateFormatter.string(from: fromDate)
        )
      )
    }

    if let toDate {
      queryItems.append(
        URLQueryItem(
          name: "toDate",
          value: Self.standardDateFormatter.string(from: toDate)
        )
      )
    }

    let url = try makeURL(path: APIEndpoints.bodyMetrics, queryItems: queryItems)
    return try await performRequest(url)
  }

  func fetchLatestBodyMetrics(metricType: MetricType? = nil) async throws -> [BodyMetricResponse] {
    var queryItems: [URLQueryItem] = []

    if let metricType {
      queryItems.append(URLQueryItem(name: "metricType", value: metricType.rawValue))
    }

    let url = try makeURL(
      path: APIEndpoints.bodyMetrics + "/latest",
      queryItems: queryItems
    )

    return try await performRequest(url)
  }

  func createBodyMetric(_ request: CreateBodyMetricRequest) async throws -> BodyMetricResponse {
    let url = try makeURL(path: APIEndpoints.bodyMetrics)
    return try await performRequest(url, method: "POST", body: request)
  }
}
