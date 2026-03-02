//
//  fitrfrontendApp.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/8/26.
//

import SwiftUI

@main
struct fitrfrontendApp: App {
    
    @StateObject private var sessionStore = SessionStore()
    @StateObject private var activeWorkoutCoordinator = ActiveWorkoutCoordinator()
    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(sessionStore)
                .environmentObject(activeWorkoutCoordinator)
        }
    }
}
