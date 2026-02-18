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
            
            VStack (spacing: 38){
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
                
                
            }
            
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 40)
    }
}

#Preview {
    LoginView(sessionStore: SessionStore())
}

