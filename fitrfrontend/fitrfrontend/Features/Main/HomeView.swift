//
//  HomeView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

//
//  HomeView.swift
//  fitrfrontend
//

import SwiftUI

struct HomeView: View {
    var body: some View {
        NavigationStack {
            VStack {
                Text("Home")
                    .font(.title)
            }
            .navigationTitle("HOME")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}

//#Preview {
//    HomeView()
//}
