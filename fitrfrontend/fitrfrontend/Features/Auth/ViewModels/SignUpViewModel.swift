//
//  SignUpViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/13/26.
//
import SwiftUI

struct SignUpViewModel {
    private var email : String = ""
    private var password : String = ""
    private var firstName : String = ""
    private var lastName : String = ""
    private var isLoading : Bool = false
    private var errorMessage : String?
    
    // Expose ways to set email/password from your UI
    public mutating func setEmail(_ value: String) { email = value }
    public mutating func setPassword(_ value: String) { password = value }
    public mutating func setFirstName(_ value: String) { firstName = value }
    public mutating func setLastName(_ value: String) { lastName = value }

    public mutating func signUp() {
        errorMessage = nil

        let trimmedEmail = email.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedPassword = password.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedFirstName = firstName.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedLastName = lastName.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedEmail.isEmpty else {
            errorMessage = "Email cannot be empty."
            return
        }

        guard !trimmedPassword.isEmpty else {
            errorMessage = "Password cannot be empty."
            return
        }
        
        guard !trimmedFirstName.isEmpty else {
            errorMessage = "First name cannot be empty."
            return
        }
        
        guard !trimmedLastName.isEmpty else {
            errorMessage = "Last name cannot be empty."
            return
        }

        guard isValidEmail(trimmedEmail) else {
            errorMessage = "Please enter a valid email address."
            return
        }
        
        

        isLoading = true
        // Proceed with your async signup call...
        // On completion, set isLoading = false and handle any errors by setting errorMessage
    }

    // Simple email validation (good enough for UI-level checks)
    private func isValidEmail(_ value: String) -> Bool {
        // A commonly used lightweight regex for emails (not perfect, but practical)
        let pattern = #"^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$"#
        return value.range(of: pattern, options: [.regularExpression, .caseInsensitive]) != nil
    }
}

