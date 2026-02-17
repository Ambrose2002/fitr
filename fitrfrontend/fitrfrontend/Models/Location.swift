//
//  Location.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

/// Represents a physical location.
struct Location: Codable, Identifiable {
    /// Unique identifier for this location
    let id: Int64
    
    /// The user ID associated with this location
    let userId: Int64
    
    /// The name of the location
    var name: String
    
    /// The address of the location
    var address: String
    
    enum CodingKeys: String, CodingKey {
        case id, userId = "user_id", name, address
    }
}
