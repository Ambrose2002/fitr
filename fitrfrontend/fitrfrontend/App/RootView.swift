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
      ProgressView()
    case .authenticated:
      if sessionStore.isCheckingProfile {
        ProgressView("Setting up your profile...")
      } else if sessionStore.hasCreatedProfile {
        MainAppView()
      } else {
        CreateProfileView(sessionStore: sessionStore)
      }
    case .unauthenticated:
      NavigationStack {
        WelcomeView(sessionStore: sessionStore)
      }
    }
  }
}
