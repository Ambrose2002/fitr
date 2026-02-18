//
//  SignUpView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject var signUpViewModel: SignUpViewModel
    
    init(sessionStore: SessionStore) {
        _signUpViewModel = StateObject(wrappedValue: SignUpViewModel(sessionStore: sessionStore))
    }

    var body: some View {
        
        VStack(spacing: 0) {
            
            Spacer()
                .frame(height: 60)
            
            VStack (spacing: 40){
                VStack(spacing: 16) {
                    AppIcons.appIcon
                        .circularIcon(backgroundColor: .black)
//                        .font(.system(size: 40))
//                        .foregroundColor(.white)
//                        .frame(width: 80, height: 80)
//                        .background(Color.black)
//                        .cornerRadius(11)
                    
                    Text("Fitr")
                        .font(.system(size: 22, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Create your account")
                        .font(.system(size: 24, weight: .bold))
                        .multilineTextAlignment(.center)
                    
                    Text("Start your fitness journey with Fitr today.")
                        .font(.system(size: 14, weight: .medium))
                        .multilineTextAlignment(.center)
                }
                
                VStack(spacing: 15) {
                    Text("EMAIL ADDRESS")
                        .font(.system(size: 16))
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    TextField("email", text: $signUpViewModel.email)
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
                    
                    SecureField("password", text: $signUpViewModel.password)
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
                
                if let error = signUpViewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(AppColors.errorRed)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                
                Button {
                    Task {
                        await signUpViewModel.signUp()
                    }
                } label: {
                    HStack {
                        
                        Text("Create Account")
                        AppIcons.signupIcon
                            
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
                    Text("Already have an account?")
                        .foregroundColor(.black)
                    NavigationLink {
                        LoginView(sessionStore: signUpViewModel.sessionStore)
                    } label: {
                        HStack(spacing: 4) {
                            Text("Log in")
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
        .overlay {
            // Loading overlay
            if signUpViewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Signing up…")
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .animation(.default, value: signUpViewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("SIGN UP")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Color.clear.frame(height: proxy.safeAreaInsets.top)
                    Divider()
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}

#Preview {
    SignUpView(sessionStore: SessionStore())
}

