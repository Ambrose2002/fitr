//
//  Exercise.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents an exercise in the system.
struct Exercise: Codable, Identifiable {
    /// Unique identifier for the exercise
    let id: Int64
    
    /// The owner of a user-defined exercise (nil if system-defined)
    let userId: Int64?
    
    /// Name of the exercise
    var name: String
    
    /// Type of measurement for the exercise
    var measurementType: MeasurementType
    
    /// Whether the exercise is defined by the system
    var isSystemDefined: Bool
    
    /// Timestamp at which the exercise was created
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, measurementType, isSystemDefined, createdAt
    }
}
