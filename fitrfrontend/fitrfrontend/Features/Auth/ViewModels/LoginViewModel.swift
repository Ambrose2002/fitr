//
//  LoginViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//
import SwiftUI
internal import Combine

@MainActor
final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    let authService : AuthService = AuthService()
    let sessionStore : SessionStore
    
    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }
    
    // Expose ways to set email/password from your UI
    public func setEmail(_ value: String) { email = value }
    public func setPassword(_ value: String) { password = value }

    public func login() async {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return
        }

        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }

        isLoading = true

        do {
            defer { self.isLoading = false }
            let loginResponse = try await self.authService.login(self.email.lowercased(), self.password)
            sessionStore.login(loginResponse)
        } catch let apiError as APIErrorResponse {
            self.errorMessage = apiError.message
        } catch {
            self.errorMessage = "Something went wrong. Please try again."
        }
    }

    // Simple email validation (good enough for UI-level checks)
    private func isValidEmail(_ value: String) -> Bool {
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

