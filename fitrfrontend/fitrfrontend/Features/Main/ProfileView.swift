//
//  ProfileView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

struct ProfileView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Profile")
                    .font(.title)
            }
            .navigationTitle("PROFILE")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview {
//    ProfileView()
//}
