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

  init(sessionStore: SessionStore, initialData: HomeScreenData? = nil) {
    _viewModel = StateObject(
      wrappedValue: HomeViewModel(sessionStore: sessionStore, initialData: initialData))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.isLoading {
          ScrollView {
            VStack(spacing: 24) {
              // Skeleton greeting
              VStack(alignment: .leading, spacing: 4) {
                RoundedRectangle(cornerRadius: 8)
                  .fill(Color(.systemGray5))
                  .frame(height: 32)
                  .frame(maxWidth: 200, alignment: .leading)

                RoundedRectangle(cornerRadius: 4)
                  .fill(Color(.systemGray5))
                  .frame(height: 14)
                  .frame(maxWidth: .infinity)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)
              .redacted(reason: .placeholder)

              // Skeleton Next Session Card
              SkeletonCard()

              // Skeleton Quick Actions
              HStack(spacing: 12) {
                ForEach(0..<3, id: \.self) { _ in
                  RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray6))
                    .frame(height: 80)
                }
              }
              .padding(.horizontal, 16)
              .redacted(reason: .placeholder)

              // Skeleton Last Workout Card
              SkeletonCard()
            }
            .padding(.vertical, 16)
          }
          .shimmer()
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

                    Text(data.nextSessionTitle)
                      .font(.system(size: 24, weight: .bold))
                      .foregroundColor(AppColors.textPrimary)
                  }

                  HStack(spacing: 24) {
                    VStack(alignment: .leading, spacing: 2) {
                      Text("Exercises")
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                      Text(data.nextSessionExerciseCount)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    }

                    Spacer()
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
                  HStack(spacing: 4) {
                    Text("INSIGHTS")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundColor(AppColors.textPrimary)
                    Text("·")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundColor(.secondary)
                    Text("THIS WEEK")
                      .font(.system(size: 12, weight: .semibold))
                      .foregroundColor(.secondary)
                  }
                  Spacer()
                  NavigationLink("View All", destination: EmptyView())
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.accent)
                }
                .padding(.horizontal, 16)

                // Current Weight (Compact Inline)
                HStack(spacing: 12) {
                  Image(systemName: "scalemass")
                    .font(.system(size: 18))
                    .foregroundColor(AppColors.accent)
                    .frame(width: 40, height: 40)
                    .background(AppColors.accent.opacity(0.1))
                    .cornerRadius(10)

                  VStack(alignment: .leading, spacing: 2) {
                    Text("Weight")
                      .font(.system(size: 10, weight: .semibold))
                      .foregroundColor(.secondary)
                    HStack(spacing: 4) {
                      Text(data.currentWeight + " kg")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                      Image(
                        systemName: data.weightChange.contains("-")
                          ? "arrow.down.right" : "arrow.up.right"
                      )
                      .font(.system(size: 10, weight: .semibold))
                      .foregroundColor(data.weightChange.contains("-") ? .green : .red)
                    }
                  }
                  Spacer()
                }
                .padding(12)
                .background(AppColors.accent.opacity(0.05))
                .cornerRadius(10)
                .padding(.horizontal, 16)

                // Weekly Stats Row (4 Tiles)
                if data.weeklyWorkoutCount > 0 {
                  HStack(spacing: 10) {
                    StatTile(
                      icon: "dumbbell.fill",
                      value: String(data.weeklyWorkoutCount),
                      label: "Workouts",
                      color: AppColors.accent
                    )
                    StatTile(
                      icon: "flame.fill",
                      value: data.weeklyTotalVolume,
                      label: "Volume",
                      color: Color(red: 1.0, green: 0.6, blue: 0.2)
                    )
                    StatTile(
                      icon: "heart.fill",
                      value: data.weeklyCaloriesBurned,
                      label: "Calories",
                      color: .red
                    )
                    StatTile(
                      icon: "stopwatch.fill",
                      value: data.weeklyAvgDuration,
                      label: "Avg Time",
                      color: Color(red: 0.5, green: 0.8, blue: 1.0)
                    )
                  }
                  .padding(.horizontal, 16)
                }

                // Personal Records
                if !data.weeklyPersonalRecords.isEmpty {
                  VStack(alignment: .leading, spacing: 6) {
                    HStack {
                      Image(systemName: "star.fill")
                        .font(.system(size: 12))
                        .foregroundColor(.yellow)
                      Text("PRs")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    }
                    Text(data.personalRecordsDisplay)
                      .font(.system(size: 12))
                      .foregroundColor(.secondary)
                      .lineLimit(2)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(12)
                  .background(Color(.systemGray6))
                  .cornerRadius(10)
                  .padding(.horizontal, 16)
                }

                // Exercise Variety
                if data.weeklyExerciseVariety > 0 {
                  VStack(alignment: .leading, spacing: 6) {
                    HStack {
                      Image(systemName: "target")
                        .font(.system(size: 12))
                        .foregroundColor(AppColors.accent)
                      Text("Variety")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                    }
                    Text(
                      "\(data.weeklyExerciseVariety) unique exercise\(data.weeklyExerciseVariety != 1 ? "s" : "")"
                    )
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                  }
                  .frame(maxWidth: .infinity, alignment: .leading)
                  .padding(12)
                  .background(Color(.systemGray6))
                  .cornerRadius(10)
                  .padding(.horizontal, 16)
                }

                // Last Workout Card
                if let lastWorkout = data.lastWorkout {
                  VStack(alignment: .leading, spacing: 12) {
                    HStack {
                      Text("Last Workout")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                      Spacer()
                      Text(data.lastWorkoutRelativeDate)
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)
                    }

                    VStack(alignment: .leading, spacing: 8) {
                      HStack(spacing: 16) {
                        Image(systemName: "flame")
                          .font(.system(size: 24))
                          .foregroundColor(AppColors.accent)
                          .frame(width: 48, height: 48)
                          .background(AppColors.accent.opacity(0.1))
                          .cornerRadius(12)
                        VStack(alignment: .leading, spacing: 4) {
                          Text(lastWorkout.title ?? "Workout")
                            .font(.system(size: 16, weight: .semibold))
                            .foregroundColor(AppColors.textPrimary)
                          if let notes = lastWorkout.notes {
                            Text(notes)
                              .font(.system(size: 12))
                              .foregroundColor(.secondary)
                              .lineLimit(2)
                          }
                        }

                        Spacer()
                      }

                      HStack(spacing: 12) {
                        Text(
                          "\(lastWorkout.workoutExercises.count) Exercise\(lastWorkout.workoutExercises.count != 1 ? "s" : "")"
                        )
                        .font(.system(size: 12))
                        .foregroundColor(.secondary)

                        if let duration = data.lastWorkoutDuration {
                          Text("•")
                            .foregroundColor(.secondary)
                          Text(duration)
                            .font(.system(size: 12))
                            .foregroundColor(.secondary)
                        }

                        Spacer()
                      }
                    }
                  }
                  .padding(16)
                  .background(Color(.systemGray6))
                  .cornerRadius(12)
                  .padding(.horizontal, 16)
                } else {
                  // Empty state: No last workout
                  VStack(spacing: 12) {
                    HStack {
                      Text("Last Workout")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(AppColors.textPrimary)
                      Spacer()
                    }

                    VStack(spacing: 8) {
                      Image(systemName: "clock.badge.xmark")
                        .font(.system(size: 32))
                        .foregroundColor(.secondary)

                      Text("No previous workouts")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)

                      Text("Start your first session to see your history")
                        .font(.system(size: 11))
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
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

// MARK: - StatTile Component
struct StatTile: View {
  let icon: String
  let value: String
  let label: String
  let color: Color

  var body: some View {
    VStack(spacing: 8) {
      Image(systemName: icon)
        .font(.system(size: 20))
        .foregroundColor(color)

      Text(value)
        .font(.system(size: 14, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

      Text(label)
        .font(.system(size: 10))
        .foregroundColor(.secondary)
    }
    .frame(maxWidth: .infinity)
    .frame(height: 75)
    .background(Color(.systemGray6))
    .cornerRadius(10)
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

// MARK: - Preview

//#Preview("Full Data (Active User)") {
//  let mockStore = MockData.mockSessionStore()
//  HomeView(sessionStore: mockStore, initialData: MockData.fullData)
//}
