//
//  AuthService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import Foundation

struct Token: Codable {
    let token: String
}

struct AuthService {
    
    func login(_ email: String, _ password: String) async throws -> Token {
        
        guard let url = URL(string: Constants.baseUrl + APIEndpoints.login) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "password": password
        ]
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success: decode the token
            return try JSONDecoder().decode(Token.self, from: data)

        case 400...499:
            // Client error: try to decode server-provided error
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                // Throw a meaningful error
                throw apiError
            } else {
                throw URLError(.userAuthenticationRequired)
            }

        case 500...599:
            // Server error: decode error if possible
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            } else {
                throw URLError(.badServerResponse)
            }

        default:
            throw URLError(.unknown)
        }
    }
    
    func signup(_ email: String, _ password: String, _ firstName: String, _ lastName: String) async throws -> Token{
        
        guard let url = URL(string: Constants.baseUrl + APIEndpoints.signup) else {
            throw URLError(.badURL)
        }
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        let body: [String: String] = [
            "email": email,
            "firstname": firstName,
            "lastname": lastName,
            "password": password
        ]
        
        request.httpBody = try JSONEncoder().encode(body)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(Token.self, from: data)
            
        case 400...499:
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            } else {
                throw URLError(.userAuthenticationRequired)
            }
        case 500...599:
            // Server error: decode error if possible
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            } else {
                throw URLError(.badServerResponse)
            }

        default:
            throw URLError(.unknown)
        }
    }
}
