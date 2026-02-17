//
//  NetworkError.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

struct APIErrorResponse: Codable, Error {
    let message: String
    let timestamp: String
    let status: Int
}
