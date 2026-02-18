//
//  LoginView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject private var loginViewModel: LoginViewModel
    
    init(sessionStore: SessionStore) {
        _loginViewModel = StateObject(wrappedValue: LoginViewModel( sessionStore: sessionStore))
    }

    var body: some View {
        
        VStack(spacing: 0) {
            Spacer()
            
            VStack(spacing: 16) {
                AppIcons.appIcon
                    .font(.system(size: 40))
                    .foregroundColor(.white)
                    .frame(width: 80, height: 80)
                    .background(Color.black)
                    .cornerRadius(11)
                Text("Fitr")
                    .font(.system(size: 22, weight: .bold))
                    .multilineTextAlignment(.center)
                
                Text("Welcome back, athlete.")
                    .font(.system(size: 14, weight: .medium))
                    .multilineTextAlignment(.center)
            }
            
            Spacer()
            
            VStack(spacing: 10) {
                Text("EMAIL ADDRESS")
                
                TextField("name@example.com", text: $loginViewModel.email)
                    .padding(.leading, 40)
                    .overlay(
                        AppIcons.email
                            .foregroundColor(.gray)
                            .padding(.leading, 12),
                        alignment: .leading
                    )
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .foregroundColor(AppColors.textPrimary)

            }
            
            Spacer()
            
            Button {
                Task {
                    await loginViewModel.login()
                }
            } label: {
                HStack {
                    AppIcons.loginIcon
                    Text("Sign In")
                        
                }
                .font(.system(size: 18, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 56)
                .background(AppColors.primaryTeal)
                .cornerRadius(16)
            }
            
        }
        .padding(.horizontal, 15)
        .padding(.bottom, 40)
    }
}

#Preview {
    LoginView(sessionStore: SessionStore())
}

