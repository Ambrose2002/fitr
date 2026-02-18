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
                .frame(height: 60)
            
            VStack (spacing: 40){
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
                
                VStack(spacing: 10) {
                    Text("EMAIL ADDRESS")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("email", text: $loginViewModel.email)
                        .foregroundColor(AppColors.textPrimary)
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
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    HStack{
                        Text("PASSWORD")
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    
                    SecureField("password", text: $loginViewModel.password)
                        .padding(.leading, 40)
                        .overlay(
                            AppIcons.lock
                                .foregroundColor(.gray)
                                .padding(.leading, 12),
                            alignment: .leading
                        )
                        .frame(height: 44)
                        .textContentType(.password)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .foregroundColor(AppColors.textPrimary)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                .foregroundColor(AppColors.textPrimary)
                
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
                
                HStack(spacing: 12) {
                    Rectangle()
                        .frame(height: 0.5)
                            .frame(maxWidth: 100)
                            .foregroundColor(.gray)
                    
                    Text("SECURE AUTHENTICATION")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundColor(.gray)
                        .lineLimit(1)
                    
                    Rectangle()
                        .frame(height: 0.5)
                        .frame(maxWidth: 100)
                        .foregroundColor(.gray)
                }
                
                Spacer()
                
                HStack(spacing: 4) {
                    Text("Don't have an account?")
                        .foregroundColor(.black)
                    Button {
                        // Navigate to sign up or perform sign up action
                    } label: {
                        HStack(spacing: 4) {
                            Text("Join Fitr")
                                .foregroundColor(AppColors.primaryTeal)
                            Image(systemName: "arrow.right")
                                .foregroundColor(AppColors.primaryTeal)
                        }
                    }
                }
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

#Preview {
    LoginView(sessionStore: SessionStore())
}

