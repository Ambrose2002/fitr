//
//  UserResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a response to a user request.
struct UserResponse: Codable, Identifiable {
  /// The ID of the user
  let id: Int64

  /// The first name of the user
  let firstname: String

  /// The last name of the user
  let lastname: String

  /// The email address of the user
  let email: String

  /// Timestamp when the user was created
  let createdAt: Date

  /// Whether the user is active
  let isActive: Bool

  enum CodingKeys: String, CodingKey {
    case id, firstname, lastname, email, createdAt, isActive
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    firstname = try container.decode(String.self, forKey: .firstname)
    lastname = try container.decode(String.self, forKey: .lastname)
    email = try container.decode(String.self, forKey: .email)
    isActive = try container.decode(Bool.self, forKey: .isActive)

    // Handle date decoding - supports both ISO 8601 string and timestamp
    let dateFormatter = ISO8601DateFormatter()
    if let dateString = try container.decodeIfPresent(String.self, forKey: .createdAt),
      let date = dateFormatter.date(from: dateString)
    {
      createdAt = date
    } else if let timestamp = try container.decodeIfPresent(Double.self, forKey: .createdAt) {
      createdAt = Date(timeIntervalSince1970: timestamp)
    } else {
      throw DecodingError.dataCorruptedError(
        forKey: .createdAt,
        in: container,
        debugDescription: "Cannot decode createdAt")
    }
  }
}
