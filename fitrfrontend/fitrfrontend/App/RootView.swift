//
//  RootView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/10/26.
//

import SwiftUI

struct RootView: View {
  @EnvironmentObject var sessionStore: SessionStore
  @EnvironmentObject var activeWorkoutCoordinator: ActiveWorkoutCoordinator

  var body: some View {
    let content: AnyView

    switch sessionStore.authState {
    case .loading:
      content = AnyView(ProgressView())

    case .authenticated:
      if sessionStore.isCheckingProfile {
        content = AnyView(
          VStack(spacing: 16) {
            ProgressView()
            Text("Setting up your profile...")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding()
        )
      } else if sessionStore.hasCreatedProfile {
        content = AnyView(MainAppView(sessionStore: sessionStore))
      } else {
        content = AnyView(CreateProfileView(sessionStore: sessionStore))
      }

    case .unauthenticated:
      content = AnyView(
        NavigationStack {
          WelcomeView(sessionStore: sessionStore)
        })
    }

    return content
      .onChange(of: sessionStore.authState) { _, authState in
        if case .unauthenticated = authState {
          activeWorkoutCoordinator.resetLocalState()
        }
      }
  }
}
