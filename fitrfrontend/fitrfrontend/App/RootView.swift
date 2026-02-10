//
//  RootView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/10/26.
//


import SwiftUI

struct RootView : View {
    @EnvironmentObject var sessionStore: SessionStore
    
    var body : some View {
        switch sessionStore.authState {
        case .loading:
            ProgressView()
        case .authenticated:
            MainAppView()
        case .unauthenticated:
            AuthRootView()
        }
    }
}
