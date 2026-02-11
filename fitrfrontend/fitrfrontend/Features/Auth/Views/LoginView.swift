//
//  LoginView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/11/26.
//

import SwiftUI

struct LoginView: View {
    @State private var email: String = ""
    @State private var password: String = ""

    var body: some View {
        
        VStack(spacing: 16) {
            Text("Login")
                .font(.largeTitle)
                .bold()

            // Email field
            TextField("Email", text: $email)
                .textContentType(.emailAddress)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .textInputAutocapitalization(.never) // iOS 15+
                .disableAutocorrection(true)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            // Password field
            SecureField("Password", text: $password)
                .textContentType(.password)
                .padding()
                .background(Color(.secondarySystemBackground))
                .cornerRadius(8)

            Button("Sign In") {
                // Handle login action
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
    }
}

#Preview {
    LoginView()
}
