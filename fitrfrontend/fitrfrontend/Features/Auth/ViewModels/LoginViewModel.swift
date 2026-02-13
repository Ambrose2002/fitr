//
//  LoginViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//
import SwiftUI
internal import Combine

final class LoginViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    
    // Expose ways to set email/password from your UI
    public func setEmail(_ value: String) { email = value }
    public func setPassword(_ value: String) { password = value }

    public func login() {
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
        // Proceed with your async login call...
        // On completion, set isLoading = false and handle any errors by setting errorMessage
    }

    // Simple email validation (good enough for UI-level checks)
    private func isValidEmail(_ value: String) -> Bool {
        // A commonly used lightweight regex for emails (not perfect, but practical)
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}
