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
    print(
      "🎯 [RootView] Rendering: authState=\(sessionStore.authState), isCheckingProfile=\(sessionStore.isCheckingProfile), hasCreatedProfile=\(sessionStore.hasCreatedProfile)"
    )

    switch sessionStore.authState {
    case .loading:
      print("🎯 [RootView] Showing: Loading")
      return AnyView(ProgressView())
    case .authenticated:
      if sessionStore.isCheckingProfile {
        print("🎯 [RootView] Showing: Profile Setup Loading")
        return AnyView(ProgressView("Setting up your profile..."))
      } else if sessionStore.hasCreatedProfile {
        print("🎯 [RootView] Showing: MainAppView")
        return AnyView(MainAppView())
      } else {
        print("🎯 [RootView] Showing: CreateProfileView")
        return AnyView(CreateProfileView(sessionStore: sessionStore))
      }
    case .unauthenticated:
      print("🎯 [RootView] Showing: Login")
      return AnyView(
        NavigationStack {
          WelcomeView(sessionStore: sessionStore)
        })
    }
  }
}
