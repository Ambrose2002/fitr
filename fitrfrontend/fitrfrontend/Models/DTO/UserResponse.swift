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
}
