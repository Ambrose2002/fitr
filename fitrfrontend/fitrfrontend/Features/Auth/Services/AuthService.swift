//
//  AuthService.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import Foundation

struct AuthService {
    
    func login(_ email: String, _ password: String) async throws -> LoginResponse {
        
        guard let url = URL(string: Constants.baseUrl + APIEndpoints.login) else {
            throw URLError(.badURL)
        }
        
        let loginRequest = LoginRequest(email: email, password: password)
        
        let encoder = JSONEncoder()
        let jsonData = try encoder.encode(loginRequest)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = jsonData
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            // Success: decode the token
            return try JSONDecoder().decode(LoginResponse.self, from: data)

        case 400...599:
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            }
            throw URLError(.unknown)

        default:
            throw URLError(.unknown)
        }
    }
    
    func signup(_ email: String, _ password: String, _ firstName: String, _ lastName: String) async throws -> LoginResponse{
        
        guard let url = URL(string: Constants.baseUrl + APIEndpoints.signup) else {
            throw URLError(.badURL)
        }
        
        let createRequest = CreateUserRequest(email: email, password: password, firstname: firstName, lastname: lastName)
        
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        
        request.httpBody = try JSONEncoder().encode(createRequest)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        switch httpResponse.statusCode {
        case 200...299:
            return try JSONDecoder().decode(LoginResponse.self, from: data)
            
        case 400...599:
            if let apiError = try? JSONDecoder().decode(APIErrorResponse.self, from: data) {
                throw apiError
            } else {
                throw URLError(.unknown)
            }

        default:
            throw URLError(.unknown)
        }
    }
}

