//
//  MainAppView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/15/26.
//

import SwiftUI

struct MainAppView: View {
  @State private var selectedTab: AppTab = .home
  @State private var pendingPlansLaunchAction: PlansLaunchAction?
  @State private var pendingWorkoutsLaunchAction: WorkoutsLaunchAction?
  @EnvironmentObject var sessionStore: SessionStore
  @EnvironmentObject private var activeWorkoutCoordinator: ActiveWorkoutCoordinator

  enum AppTab: String, CaseIterable, Identifiable {
    case home = "Home"
    case plans = "Plans"
    case workouts = "Workouts"
    case progress = "Progress"
    case profile = "Profile"

    var id: String { rawValue }

    var systemImage: Image {
      switch self {
      case .home: return AppIcons.home
      case .plans: return AppIcons.plans
      case .workouts: return AppIcons.workouts
      case .progress: return Image(systemName: "chart.line.uptrend.xyaxis")
      case .profile: return Image(systemName: "person")
      }
    }
  }

  var body: some View {
    ZStack(alignment: .bottom) {
      // Main content area
      Group {
        switch selectedTab {
        case .home:
          HomeView(
            sessionStore: sessionStore,
            onNewPlanTap: {
              pendingPlansLaunchAction = .createPlan
              selectedTab = .plans
            },
            onLastWorkoutTap: { workoutId in
              pendingWorkoutsLaunchAction = .openWorkout(workoutId)
              selectedTab = .workouts
            }
          )
        case .plans:
          PlansView(
            sessionStore: sessionStore,
            launchAction: $pendingPlansLaunchAction
          )
        case .workouts:
          WorkoutsView(
            sessionStore: sessionStore,
            launchAction: $pendingWorkoutsLaunchAction
          )
        case .progress:
          ProgressMainView(
            sessionStore: sessionStore,
            onSeeFullHistoryTap: {
              selectedTab = .workouts
            }
          )
        case .profile:
          ProfileView()
        }
      }

      if
        activeWorkoutCoordinator.activeContext != nil,
        activeWorkoutCoordinator.presentedContext == nil
      {
        VStack {
          Spacer()

          Button {
            activeWorkoutCoordinator.presentActiveWorkout()
          } label: {
            HStack(spacing: 8) {
              Image(systemName: "timer")
                .font(.system(size: 13, weight: .bold))
              Text("Resume Active Workout")
                .font(.system(size: 14, weight: .bold))
            }
            .foregroundColor(.white)
            .padding(.horizontal, 14)
            .frame(height: 44)
            .background(AppColors.accent)
            .clipShape(Capsule())
            .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
          }
          .buttonStyle(.plain)
          .padding(.bottom, 76)
        }
      }

      // Custom bottom tab bar
      VStack(spacing: 0) {
        Divider()

        HStack(spacing: 0) {
          ForEach(AppTab.allCases) { tab in
            Button {
              selectedTab = tab
            } label: {
              VStack(spacing: 4) {
                tab.systemImage
                  .font(.system(size: 20, weight: .semibold))
                Text(tab.rawValue)
                  .font(.system(size: 10, weight: .semibold))
              }
              .foregroundColor(selectedTab == tab ? AppColors.accent : Color.gray)
              .frame(maxWidth: .infinity)
              .frame(height: 60)
            }
            .buttonStyle(.plain)
          }
        }
        .background(Color(.systemBackground))
        .safeAreaInset(edge: .bottom, spacing: 0) {
          Color.clear.frame(height: 0)
        }
      }
    }
    .task {
      await activeWorkoutCoordinator.restoreRemoteActiveWorkoutIfNeeded()
    }
    .fullScreenCover(item: $activeWorkoutCoordinator.presentedContext) { context in
      LiveWorkoutView(context: context, sessionStore: sessionStore)
        .environmentObject(sessionStore)
        .environmentObject(activeWorkoutCoordinator)
    }
  }
}

//#Preview {
//    MainAppView()
//}
