//
//  User.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a user in the system.
struct User: Codable, Identifiable {
  /// Unique identifier for the user
  let id: Int64

  /// First name of the user
  var firstname: String

  /// Last name of the user
  var lastname: String

  /// Email of the user (must be unique)
  var email: String

  /// Hash of the user's password
  var passwordHash: String?

  /// Timestamp when the user was created
  let createdAt: Date

  /// Timestamp when the user last logged in
  var lastLoginAt: Date?

  /// Whether the user is active or not
  var isActive: Bool

  enum CodingKeys: String, CodingKey {
    case id, firstname, lastname, email, passwordHash, createdAt, lastLoginAt, isActive
  }

  init(from decoder: Decoder) throws {
    let container = try decoder.container(keyedBy: CodingKeys.self)
    id = try container.decode(Int64.self, forKey: .id)
    firstname = try container.decode(String.self, forKey: .firstname)
    lastname = try container.decode(String.self, forKey: .lastname)
    email = try container.decode(String.self, forKey: .email)
    passwordHash = try container.decodeIfPresent(String.self, forKey: .passwordHash)
    isActive = try container.decode(Bool.self, forKey: .isActive)

    // Handle createdAt date decoding
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

    // Handle lastLoginAt date decoding (optional)
    if let dateString = try container.decodeIfPresent(String.self, forKey: .lastLoginAt),
      let date = dateFormatter.date(from: dateString)
    {
      lastLoginAt = date
    } else if let timestamp = try container.decodeIfPresent(Double.self, forKey: .lastLoginAt) {
      lastLoginAt = Date(timeIntervalSince1970: timestamp)
    }
  }
}
