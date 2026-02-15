//
//  LoginView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct LoginView: View {
    @StateObject var loginViewModel: LoginViewModel = LoginViewModel()

    var body: some View {
        
        ZStack{
            VStack(spacing: 16) {
                Text("Login")
                    .font(.largeTitle)
                    .bold()

                // Email field
                TextField("Email", text: $loginViewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never) // iOS 15+
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Password field
                SecureField("Password", text: $loginViewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if let error = loginViewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                
                Button("Sign In") {
                    // Handle login action
                    Task {
                        await loginViewModel.login()
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(Color.accentColor)
                .foregroundColor(.white)
                .cornerRadius(8)

                Spacer()
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
            .padding()
            .overlay {
                // Loading overlay
                if loginViewModel.isLoading {
                    ZStack {
                        Color.black.opacity(0.2).ignoresSafeArea()
                        ProgressView("Signing in…")
                            .padding(24)
                            .background(.ultraThinMaterial)
                            .cornerRadius(12)
                    }
                }
            }
            .animation(.default, value: loginViewModel.isLoading)
        }
    }
}

#Preview {
    LoginView()
}

