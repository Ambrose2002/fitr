//
//  CreateProfileView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//

import SwiftUI

struct CreateProfileView: View {
    
    @StateObject private var viewModel: CreateProfileViewModel
    var body: some View {
        VStack {
            Text("CreateProfileView")
        }
        .animation(.default, value: viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("LOG IN")
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
