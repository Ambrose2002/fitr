//
//  BodyMetricResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct BodyMetricResponse: Codable, Identifiable {
    let id: Int64
    let userId: Int64
    let metricType: MetricType
    let value: Float
    let updatedAt: Date
    let createdAt: Date
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case metricType
        case value
        case updatedAt
        case createdAt
    }
}
