//
//  MainAppView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/15/26.
//

import SwiftUI

struct MainAppView: View {
  @Environment(\.scenePhase) private var scenePhase
  @EnvironmentObject private var activeWorkoutCoordinator: ActiveWorkoutCoordinator
  private let sessionStore: SessionStore

  @State private var selectedTab: AppTab = .home
  @State private var mountedTabs: Set<AppTab> = [.home]
  @State private var pendingPlansLaunchAction: PlansLaunchAction?
  @State private var pendingWorkoutsLaunchAction: WorkoutsLaunchAction?
  @StateObject private var homeViewModel: HomeViewModel
  @StateObject private var plansViewModel: WorkoutPlanViewModel
  @StateObject private var workoutsViewModel: WorkoutsViewModel
  @StateObject private var progressViewModel: ProgressViewModel
  @StateObject private var profileViewModel: ProfileViewModel

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
    _homeViewModel = StateObject(wrappedValue: HomeViewModel(sessionStore: sessionStore))
    _plansViewModel = StateObject(wrappedValue: WorkoutPlanViewModel(sessionStore: sessionStore))
    _workoutsViewModel = StateObject(wrappedValue: WorkoutsViewModel(sessionStore: sessionStore))
    _progressViewModel = StateObject(wrappedValue: ProgressViewModel(sessionStore: sessionStore))
    _profileViewModel = StateObject(wrappedValue: ProfileViewModel(sessionStore: sessionStore))
  }

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
      ZStack {
        mountedTab(.home) {
          HomeView(
            sessionStore: sessionStore,
            viewModel: homeViewModel,
            onNewPlanTap: {
              pendingPlansLaunchAction = .createPlan
              activateTab(.plans)
            },
            onLastWorkoutTap: { workoutId in
              pendingWorkoutsLaunchAction = .openWorkout(workoutId)
              activateTab(.workouts)
            }
          )
        }

        mountedTab(.plans) {
          PlansView(
            sessionStore: sessionStore,
            viewModel: plansViewModel,
            launchAction: $pendingPlansLaunchAction
          )
        }

        mountedTab(.workouts) {
          WorkoutsView(
            sessionStore: sessionStore,
            viewModel: workoutsViewModel,
            launchAction: $pendingWorkoutsLaunchAction
          )
        }

        mountedTab(.progress) {
          ProgressMainView(
            sessionStore: sessionStore,
            viewModel: progressViewModel,
            onSeeFullHistoryTap: {
              activateTab(.workouts)
            }
          )
        }

        mountedTab(.profile) {
          ProfileView(
            sessionStore: sessionStore,
            viewModel: profileViewModel
          )
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
              activateTab(tab)
            } label: {
              VStack(spacing: 4) {
                tab.systemImage
                  .font(.system(size: 20, weight: .semibold))
                Text(tab.rawValue)
                  .font(.system(size: 10, weight: .semibold))
              }
              .foregroundColor(selectedTab == tab ? AppColors.accent : AppColors.textSecondary)
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
      await loadSelectedTabDataIfNeeded()
    }
    .onChange(of: selectedTab) { _, newTab in
      mountedTabs.insert(newTab)
      Task {
        await loadDataIfNeeded(for: newTab)
      }
    }
    .onChange(of: scenePhase) { _, phase in
      guard phase == .active else { return }
      Task {
        await loadSelectedTabDataIfNeeded()
      }
    }
    .fullScreenCover(item: $activeWorkoutCoordinator.presentedContext) { context in
      LiveWorkoutView(context: context, sessionStore: sessionStore)
        .environmentObject(sessionStore)
        .environmentObject(activeWorkoutCoordinator)
    }
  }

  @ViewBuilder
  private func mountedTab<Content: View>(
    _ tab: AppTab,
    @ViewBuilder content: () -> Content
  ) -> some View {
    if mountedTabs.contains(tab) {
      content()
        .opacity(selectedTab == tab ? 1 : 0)
        .allowsHitTesting(selectedTab == tab)
        .accessibilityHidden(selectedTab != tab)
        .zIndex(selectedTab == tab ? 1 : 0)
    }
  }

  @MainActor
  private func loadSelectedTabDataIfNeeded() async {
    await loadDataIfNeeded(for: selectedTab)
  }

  @MainActor
  private func loadDataIfNeeded(for tab: AppTab) async {
    switch tab {
    case .home:
      await homeViewModel.loadHomeData()
    case .plans:
      await plansViewModel.loadPlans()
    case .workouts:
      await workoutsViewModel.loadWorkoutHistory()
    case .progress:
      await progressViewModel.loadDashboard()
    case .profile:
      await profileViewModel.load()
    }
  }

  private func activateTab(_ tab: AppTab) {
    mountedTabs.insert(tab)
    selectedTab = tab
  }
}

//#Preview {
//    MainAppView()
//}
