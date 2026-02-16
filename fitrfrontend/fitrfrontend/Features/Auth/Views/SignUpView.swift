//
//  SignUpView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct SignUpView: View {
    @StateObject var signUpViewModel: SignUpViewModel = SignUpViewModel()

    var body: some View {
        
        ZStack{
            VStack(spacing: 16) {
                Text("Sign up")
                    .font(.largeTitle)
                    .bold()

                // Email field
                TextField("Email", text: $signUpViewModel.email)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never) // iOS 15+
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                // First name field
                TextField("First Name", text: $signUpViewModel.firstName)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)
                
                
                // Last name field
                TextField("Last Name", text: $signUpViewModel.lastName)
                    .textContentType(.emailAddress)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .textInputAutocapitalization(.never)
                    .disableAutocorrection(true)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                // Password field
                SecureField("Password", text: $signUpViewModel.password)
                    .textContentType(.password)
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .cornerRadius(8)

                if let error = signUpViewModel.errorMessage, !error.isEmpty {
                    Text(error)
                        .foregroundColor(.red)
                        .font(.callout)
                        .multilineTextAlignment(.center)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .padding(.top, 4)
                }
                
                Button("Sign Up") {
                    // Handle login action
                    Task {
                        await signUpViewModel.signUp()
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
        }
    }
}

//#Preview {
//    SignUpView()
//}

