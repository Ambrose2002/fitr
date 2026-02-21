//
//  RootView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/10/26.
//

import SwiftUI

struct RootView: View {
  @EnvironmentObject var sessionStore: SessionStore

  var body: some View {

    switch sessionStore.authState {
    case .loading:
      return AnyView(ProgressView())

    case .authenticated:
      if sessionStore.isCheckingProfile {
        return AnyView(ProgressView("Setting up your profile..."))
      } else if sessionStore.hasCreatedProfile {
        return AnyView(MainAppView())
      } else {
        return AnyView(CreateProfileView(sessionStore: sessionStore))
      }
      
    case .unauthenticated:
      return AnyView(
        NavigationStack {
          WelcomeView(sessionStore: sessionStore)
        })
    }
  }
}
