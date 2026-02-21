//
//  CurrentMetricsDTO.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation

struct CurrentMetricsDTO: Codable {
  let weight: Double
  let lastUpdated: String
  let change: Double
}
