//
//  ErrorResponse.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct ErrorResponse: Codable {
    let message: String
    let status: Int
    let timestamp: Date
}
