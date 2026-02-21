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
}
