//
//  MainAppView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/15/26.
//

import SwiftUI

struct MainAppView: View {
    @State private var selectedTab: AppTab = .home
    @EnvironmentObject var sessionStore: SessionStore
    
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
            case .profile: return Image(systemName:"person")
            }
        }
    }
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main content area
            Group {
                switch selectedTab {
                case .home:
                    HomeView(sessionStore: sessionStore)
                case .plans:
                    PlansView()
                case .workouts:
                    WorkoutsView()
                case .progress:
                    ProgressMainView()
                case .profile:
                    ProfileView()
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
    }
}

//#Preview {
//    MainAppView()
//}

