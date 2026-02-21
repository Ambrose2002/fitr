//
//  MetricType.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a type of metric used to measure a user's progress.
enum MetricType: String, Codable, CaseIterable {
    case weight = "WEIGHT"
    case height = "HEIGHT"
}
