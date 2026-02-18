//
//  SignUpView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject var signUpViewModel: SignUpViewModel
    @State private var isPasswordVisible: Bool = false
    
    init(sessionStore: SessionStore) {
        _signUpViewModel = StateObject(wrappedValue: SignUpViewModel(sessionStore: sessionStore))
    }
    
    private var isPasswordLongEnough: Bool { signUpViewModel.password.count >= 8 }
    private var hasUppercase: Bool { signUpViewModel.password.range(of: "[A-Z]", options: .regularExpression) != nil }
    private var hasNumber: Bool { signUpViewModel.password.range(of: "[0-9]", options: .regularExpression) != nil }
    private var allPasswordRulesPass: Bool { isPasswordLongEnough && hasUppercase && hasNumber }

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
                    
                    HStack {
                        VStack {
                            Text("First Name")
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("John", text: $signUpViewModel.firstName)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.leading, 40)
                                .overlay(
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12),
                                    alignment: .leading
                                )
                                .frame(height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        
                        VStack {
                            Text("Last Name")
                                .font(.system(size: 16))
                                .frame(maxWidth: .infinity, alignment: .leading)
                            
                            TextField("Doe", text: $signUpViewModel.lastName)
                                .foregroundColor(AppColors.textPrimary)
                                .padding(.leading, 40)
                                .overlay(
                                    Image(systemName: "person")
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12),
                                    alignment: .leading
                                )
                                .frame(height: 44)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                .foregroundColor(AppColors.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                    }
                    
                    Text("Email Address")
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
                        Text("Password")
                            .font(.system(size: 16))
                            .frame(maxWidth: .infinity, alignment: .leading)
                        
                    }
                    
                    HStack {
                        if isPasswordVisible {
                            TextField("password", text: $signUpViewModel.password)
                                .textContentType(.password)
                                .autocapitalization(.none)
                                .textInputAutocapitalization(.never)
                                .disableAutocorrection(true)
                                .padding(.leading, 40)
                                .overlay(
                                    AppIcons.lock
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12),
                                    alignment: .leading
                                )
                        } else {
                            SecureField("password", text: $signUpViewModel.password)
                                .textContentType(.password)
                                .padding(.leading, 40)
                                .overlay(
                                    AppIcons.lock
                                        .foregroundColor(.gray)
                                        .padding(.leading, 12),
                                    alignment: .leading
                                )
                        }
                        Button {
                            isPasswordVisible.toggle()
                        } label: {
                            Image(systemName: isPasswordVisible ? "eye.slash" : "eye")
                                .foregroundColor(.gray)
                                .padding(.trailing, 12)
                        }
                    }
                    .frame(height: 44)
                    .background(Color(.systemGray6))
                    .cornerRadius(12)
                    .foregroundColor(AppColors.textPrimary)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    
                    // Password rules checklist
                    HStack(spacing: 8) {
                        HStack(spacing: 8) {
                            Image(systemName: isPasswordLongEnough ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(isPasswordLongEnough ? AppColors.primaryTeal : .gray)
                            Text("8+ Characters")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.subheadline)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: hasUppercase ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(hasUppercase ? AppColors.primaryTeal : .gray)
                            Text("1 Upper case")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.subheadline)
                        }
                        HStack(spacing: 8) {
                            Image(systemName: hasNumber ? "checkmark.circle.fill" : "checkmark.circle")
                                .foregroundColor(hasNumber ? AppColors.primaryTeal : .gray)
                            Text("1 Number")
                                .foregroundColor(AppColors.textPrimary)
                                .font(.subheadline)
                        }
                    }
                    .padding(.top, 4)
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
                    .background(allPasswordRulesPass ? AppColors.primaryTeal : AppColors.primaryTeal.opacity(0.5))
                    .cornerRadius(16)
                }
                .disabled(!allPasswordRulesPass)
                
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

//#Preview {
//    SignUpView(sessionStore: SessionStore())
//}

