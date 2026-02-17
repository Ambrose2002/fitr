//
//  CreateUserRequest.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import Foundation

struct CreateUserRequest: Codable {
    let email: String
    let password: String
    let firstname: String
    let lastname: String
}
