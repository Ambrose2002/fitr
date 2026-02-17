//
//  BodyMetric.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a measurement of a user's body metrics.
struct BodyMetric: Codable, Identifiable {
    /// The unique identifier for the body metric
    let id: Int64
    
    /// The user ID associated with the body metric
    let userId: Int64
    
    /// The type of metric associated with the body metric
    var metricType: MetricType
    
    /// The value of the body metric
    var value: Float
    
    /// The time at which the body metric was recorded
    var recordedAt: Date
    
    /// The time at which the body metric was last updated
    var updatedAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", metricType, value, recordedAt, updatedAt
    }
}
