//
//  WelcomeView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/17/26.
//

import SwiftUI

struct WelcomeView: View {
    
    var sessionStore: SessionStore
    
    var body: some View {
        VStack(spacing: 0) {
            Spacer()
            
            // Logo and branding section
            VStack(spacing: 24) {
                // App icon/logo
                Text("Fitr")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                AppIcons.appIcon
                    .font(.system(size: 80))
                    .foregroundColor(.white)
                    .frame(width: 120, height: 120)
                    .background(Color.black)
                    .cornerRadius(28)
                
                // Title
                Text("Elevate Your Gains")
                    .font(.system(size: 32, weight: .bold))
                    .multilineTextAlignment(.center)
                
                // Subtitle
                Text("The ultimate companion for tracking workouts, monitoring progress, and crushing your fitness goals.")
                    .font(.system(size: 17))
                    .foregroundColor(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 40)
            }
            
            Spacer()
            
            // Buttons section
            VStack(spacing: 16) {
                // Login button
                NavigationLink(value: "login") {
                    HStack {
                        AppIcons.loginIcon
                        Text("Log In to Account")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(AppColors.primaryTeal)
                    .cornerRadius(16)
                }
                
                // Sign up button
                NavigationLink(value: "signup") {
                    HStack {
                        AppIcons.signupIcon
                        Text("New to Fitr? Sign Up")
                    }
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundColor(.primary)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(Color(.systemGray6))
                    .cornerRadius(16)
                }
                
                // Terms text
                let terms: AttributedString = {
                    var base = AttributedString("By continuing, you agree to our ")
                    base.font = .system(size: 13)
                    base.foregroundColor = .secondary

                    var tos = AttributedString("Terms of Service")
                    tos.font = .system(size: 13)
                    tos.foregroundColor = .secondary
                    tos.underlineStyle = .single

                    var andText = AttributedString(" and ")
                    andText.font = .system(size: 13)
                    andText.foregroundColor = .secondary

                    var privacy = AttributedString("Privacy Policy")
                    privacy.font = .system(size: 13)
                    privacy.foregroundColor = .secondary
                    privacy.underlineStyle = .single

                    return base + tos + andText + privacy
                }()
                Text(terms)
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 40)
        }
        .background(AppColors.backgroundLight)
        .navigationDestination(for: String.self) {destination in
            switch destination {
            case "login":
                LoginView(sessionStore: sessionStore)
            case "signup":
                SignUpView(sessionStore: sessionStore)
            default:
                EmptyView()
            }
        }
    }
}

//#Preview {
//    WelcomeView(sessionStore: SessionStore())
//}

