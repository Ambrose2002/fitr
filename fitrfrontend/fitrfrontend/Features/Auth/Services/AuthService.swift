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
    
    var baseUrl = "http://127.0.0.1:8080/auth"
    
    func login(_ email: String, _ password: String) async throws -> Token {
        
        guard let url = URL(string: baseUrl + "/login") else {
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
        guard (200...299).contains(httpResponse.statusCode) else {
            throw URLError(.userAuthenticationRequired)
        }
        
        let token = try JSONDecoder().decode(Token.self, from: data)
        return token
    }
}
