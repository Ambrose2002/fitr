//
//  CreateBodyMetricRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateBodyMetricRequest: Codable {
    let metricType: MetricType
    let value: Float
}
