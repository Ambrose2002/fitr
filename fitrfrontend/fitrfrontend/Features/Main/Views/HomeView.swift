//
//  HomeView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

// MARK: - HomeView
struct HomeView: View {
  @EnvironmentObject var sessionStore: SessionStore
  @StateObject private var viewModel: HomeViewModel

  init(sessionStore: SessionStore) {
    _viewModel = StateObject(wrappedValue: HomeViewModel(sessionStore: sessionStore))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.isLoading {
          ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
              .font(.system(size: 48))
              .foregroundColor(.red)
            Text("Error loading home screen")
              .font(.headline)
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.secondary)
            Button("Retry") {
              Task {
                await viewModel.loadHomeData()
              }
            }
            .buttonStyle(.bordered)
          }
          .padding()
        } else if let data = viewModel.homeData {
          ScrollView {
            VStack(spacing: 24) {
              // Greeting Section
              VStack(alignment: .leading, spacing: 4) {
                Text(data.greeting)
                  .font(.system(size: 28, weight: .bold))
                  .foregroundColor(.black)
                Text(data.weekProgress)
                  .font(.system(size: 14))
                  .foregroundColor(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)

              // Next Session Card
              if let nextSession = data.nextSession {
                VStack(alignment: .leading, spacing: 12) {
                  VStack(alignment: .leading, spacing: 4) {
                    Text("NEXT SESSION")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundColor(AppColors.accent)

                    Text(nextSession.title ?? "Workout")
                      .font(.system(size: 24, weight: .bold))
                      .foregroundColor(AppColors.textPrimary)

                    Text("Day 12")
                      .font(.system(size: 14))
                      .foregroundColor(.secondary)
                  }

                  HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                      Text("Exercises")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                      Text("7 Moves")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    }

                    VStack(alignment: .leading, spacing: 2) {
                      Text("Estimated")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                      Text("55 mins")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    }

                    Spacer()

                    Text("Intensity: 8/10")
                      .font(.system(size: 11, weight: .semibold))
                      .foregroundColor(AppColors.accent)
                      .padding(.horizontal, 12)
                      .padding(.vertical, 6)
                      .background(AppColors.accent.opacity(0.2))
                      .cornerRadius(8)
                  }

                  Button {
                    // Start workout action
                  } label: {
                    HStack {
                      Image(systemName: "play.fill")
                      Text("Start Session")
                    }
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.accent)
                    .cornerRadius(12)
                  }
                  .buttonStyle(.plain)
                }
                .padding(16)
                .background(AppColors.accent.opacity(0.15))
                .cornerRadius(16)
                .padding(.horizontal, 16)
              }

              // Quick Actions
              VStack(alignment: .leading, spacing: 12) {
                Text("QUICK ACTIONS")
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundColor(AppColors.textPrimary)
                  .padding(.horizontal, 16)

                HStack(spacing: 12) {
                  QuickActionButton(
                    icon: "chart.line.uptrend.xyaxis",
                    label: "Log Weight",
                    color: AppColors.accent,
                    action: {}
                  )

                  QuickActionButton(
                    icon: "plus",
                    label: "New Session",
                    color: AppColors.accent,
                    action: {}
                  )

                  QuickActionButton(
                    icon: "clipboard.fill",
                    label: "New Plan",
                    color: Color(red: 0.8, green: 0.7, blue: 1.0),
                    action: {}
                  )
                }
                .padding(.horizontal, 16)
              }

              // Insights Section
              VStack(alignment: .leading, spacing: 12) {
                HStack {
                  Text("INSIGHTS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                  Spacer()
                  NavigationLink("View All", destination: EmptyView())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal, 16)

                // Current Weight Card
                HStack(spacing: 16) {
                  Image(systemName: "scalemass")
                    .font(.system(size: 24))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 48, height: 48)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(12)

                  VStack(alignment: .leading, spacing: 2) {
                    Text("CURRENT WEIGHT")
                      .font(.system(size: 10, weight: .semibold))
                      .foregroundColor(.secondary)

                    HStack(spacing: 8) {
                      Text(data.currentWeight)
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)

                      VStack(alignment: .leading, spacing: 2) {
                        HStack(spacing: 2) {
                          Image(systemName: "arrow.down")
                            .font(.system(size: 10, weight: .semibold))
                          Text(data.weightChange + " KG")
                            .font(.system(size: 12, weight: .semibold))
                        }
                        .foregroundColor(.green)

                        Text("LAST 7 DAYS")
                          .font(.system(size: 10))
                          .foregroundColor(.secondary)
                      }
                    }
                  }

                  Spacer()
                }
                .padding(16)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)

                // Last Workout Card
                if let lastWorkout = data.lastWorkout {
                  VStack(alignment: .leading, spacing: 12) {
                    HStack {
                      Text("Last Workout")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                      Spacer()
                      Text("Yesterday")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }

                    HStack(spacing: 16) {
                      Image(systemName: "flame")
                        .font(.system(size: 24))
                        .foregroundColor(AppColors.accent)
                        .frame(width: 48, height: 48)
                        .background(AppColors.accent.opacity(0.1))
                        .cornerRadius(12)
                      VStack(alignment: .leading, spacing: 4) {
                        Text(lastWorkout.title ?? "Workout Title")
                          .font(.system(size: 16, weight: .semibold))
                          .foregroundColor(AppColors.textPrimary)
                        Text(lastWorkout.notes ?? "Workout Notes")
                          .font(.system(size: 12))
                          .foregroundColor(.secondary)
                      }

                      Spacer()
                    }
                  }
                  .padding(16)
                  .background(Color(.systemGray6))
                  .cornerRadius(12)
                  .padding(.horizontal, 16)
                }
              }
            }
            .padding(.vertical, 16)
          }
        } else {
          // Fallback empty state when no data
          VStack(spacing: 8) {
            Image(systemName: "house")
              .font(.system(size: 48))
              .foregroundColor(.secondary)
            Text("Welcome")
              .font(.headline)
            Text("No data to display yet.")
              .font(.caption)
              .foregroundColor(.secondary)
          }
          .padding()
        }
      }
      .navigationTitle("HOME")
      .navigationBarTitleDisplayMode(.inline)
      .task {
        await viewModel.loadHomeData()
      }
    }
  }
}

// MARK: - Supporting Views
struct QuickActionButton: View {
  let icon: String
  let label: String
  let color: Color
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        Image(systemName: icon)
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(color)
          .frame(width: 48, height: 48)
          .background(color.opacity(0.1))
          .cornerRadius(12)
        Text(label)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(AppColors.textPrimary)
      }
      .frame(maxWidth: .infinity)
      .padding(12)
      .background(Color(.systemGray6))
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
  }
}

//#Preview {
//  let mockProfile = UserProfileResponse(
//    id: 1,
//    userId: 1,
//    firstname: "Alex",
//    lastname: "Taylor",
//    email: "alex@example.com",
//    gender: .male,
//    height: 180,
//    weight: 82.4,
//    experience: .intermediate,
//    goal: .strength,
//    preferredWeightUnit: .kg,
//    preferredDistanceUnit: .km,
//    createdAt: Date()
//  )
//  let mock = SessionStore.mock(userProfile: mockProfile)
//  HomeView(sessionStore: mock)
//}
