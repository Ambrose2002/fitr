//
//  LocationResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct LocationResponse: Codable, Identifiable {
    let id: Int64
    let userId: Int64
    let name: String
    let address: String
    
    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case address
    }
}
