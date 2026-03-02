//
//  WorkoutsView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

struct WorkoutsView: View {
  @StateObject private var viewModel: WorkoutsViewModel

  init(sessionStore: SessionStore) {
    _viewModel = StateObject(wrappedValue: WorkoutsViewModel(sessionStore: sessionStore))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        Color(.systemBackground)
          .ignoresSafeArea()

        if viewModel.isLoading && !viewModel.hasWorkouts {
          loadingState
        } else if let errorMessage = viewModel.errorMessage, !viewModel.hasWorkouts {
          errorState(message: errorMessage)
        } else {
          content
        }
      }
      .navigationBarHidden(true)
      .safeAreaInset(edge: .top) {
        topBar
      }
      .navigationDestination(for: Int64.self) { workoutId in
        WorkoutDetailView(
          sessionStore: viewModel.sessionStore,
          workoutId: workoutId,
          mode: .completed,
          initialWorkout: viewModel.workoutSession(id: workoutId),
          onWorkoutUpdated: viewModel.applyUpdatedWorkout
        )
      }
    }
    .sheet(isPresented: $viewModel.showFilterSheet, onDismiss: viewModel.resetDraftFiltersAfterDismiss) {
      WorkoutHistoryFilterSheet(
        filters: $viewModel.draftFilters,
        monthOptions: viewModel.availableMonthOptions,
        locationOptions: viewModel.availableLocations,
        onCancel: viewModel.cancelFilterSheet,
        onClearAll: viewModel.clearDraftFilters,
        onApply: viewModel.applyDraftFilters
      )
      .presentationDetents([.medium, .large])
    }
    .task {
      await viewModel.loadWorkoutHistory()
    }
  }

  private var content: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        WorkoutHistorySummaryCard(
          label: viewModel.summaryLabel,
          countText: viewModel.summaryCountText
        )
        .padding(.horizontal, 16)

        if !viewModel.hasWorkouts {
          emptyState(
            iconName: "figure.strengthtraining.traditional",
            title: "No workout history yet",
            message: "Finish your first session and it will show up here."
          )
          .padding(.horizontal, 16)
        } else if !viewModel.hasFilteredResults {
          emptyState(
            iconName: "line.3.horizontal.decrease.circle",
            title: "No workouts match your filters",
            message: "Try broadening your filters to see more sessions.",
            actionTitle: "Clear Filters",
            action: viewModel.clearAppliedFilters
          )
          .padding(.horizontal, 16)
        } else {
          VStack(alignment: .leading, spacing: 20) {
            ForEach(viewModel.sections) { section in
              WorkoutHistorySectionView(section: section)
            }
          }
          .padding(.horizontal, 16)

          if let footerText = viewModel.historyFooterText {
            Text(footerText)
              .font(.system(size: 14, weight: .medium))
              .foregroundColor(AppColors.textSecondary)
              .italic()
              .padding(.horizontal, 16)
          }
        }

        Spacer(minLength: 92)
      }
      .padding(.top, 16)
      .padding(.bottom, 8)
    }
    .refreshable {
      await viewModel.loadWorkoutHistory()
    }
  }

  private var loadingState: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 24) {
        RoundedRectangle(cornerRadius: 18)
          .fill(Color(.systemGray6))
          .frame(height: 92)
          .padding(.horizontal, 16)
          .redacted(reason: .placeholder)

        VStack(alignment: .leading, spacing: 16) {
          RoundedRectangle(cornerRadius: 6)
            .fill(Color(.systemGray6))
            .frame(width: 140, height: 12)

          ForEach(0..<3, id: \.self) { _ in
            VStack(alignment: .leading, spacing: 12) {
              RoundedRectangle(cornerRadius: 4)
                .fill(Color(.systemGray6))
                .frame(width: 110, height: 10)

              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 24)

              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 14)

              RoundedRectangle(cornerRadius: 8)
                .fill(Color(.systemGray6))
                .frame(height: 50)
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(16)
          }
        }
        .padding(.horizontal, 16)

        Spacer(minLength: 92)
      }
      .padding(.top, 16)
      .redacted(reason: .placeholder)
      .shimmer()
    }
  }

  private func errorState(message: String) -> some View {
    VStack(spacing: 16) {
      Image(systemName: "exclamationmark.circle")
        .font(.system(size: 48))
        .foregroundColor(AppColors.errorRed)

      Text("Error loading workouts")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

      Text(message)
        .font(.system(size: 13))
        .foregroundColor(AppColors.textSecondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task {
          await viewModel.loadWorkoutHistory()
        }
      }
      .buttonStyle(.bordered)
      .tint(AppColors.accent)
    }
    .padding(24)
  }

  private func emptyState(
    iconName: String,
    title: String,
    message: String,
    actionTitle: String? = nil,
    action: (() -> Void)? = nil
  ) -> some View {
    VStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 30, weight: .semibold))
        .foregroundColor(AppColors.accent)

      Text(title)
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

      Text(message)
        .font(.system(size: 13))
        .foregroundColor(AppColors.textSecondary)
        .multilineTextAlignment(.center)

      if let actionTitle, let action {
        Button(actionTitle) {
          action()
        }
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(AppColors.accent)
        .padding(.top, 4)
      }
    }
    .frame(maxWidth: .infinity)
    .padding(24)
    .background(Color(.systemGray6))
    .cornerRadius(16)
  }

  private var topBar: some View {
    VStack(spacing: 0) {
      HStack(spacing: 12) {
        Image(systemName: "bolt.fill")
          .font(.system(size: 20, weight: .bold))
          .foregroundColor(.white)
          .frame(width: 40, height: 40)
          .background(Color.black)
          .cornerRadius(10)

        Spacer()

        Text("WORKOUT HISTORY")
          .font(.system(size: 18, weight: .bold))
          .foregroundColor(AppColors.textPrimary)

        Spacer()

        Button {
          viewModel.presentFilterSheet()
        } label: {
          ZStack(alignment: .topTrailing) {
            Image(systemName: "line.3.horizontal.decrease.circle")
              .font(.system(size: 20, weight: .semibold))
              .foregroundColor(
                viewModel.activeFilterCount > 0 ? AppColors.accent : AppColors.textPrimary
              )
              .frame(width: 40, height: 40)

            if viewModel.activeFilterCount > 0 {
              Text("\(viewModel.activeFilterCount)")
                .font(.system(size: 9, weight: .bold))
                .foregroundColor(.white)
                .frame(minWidth: 16, minHeight: 16)
                .background(AppColors.accent)
                .clipShape(Capsule())
                .offset(x: 3, y: -1)
            }
          }
        }
        .buttonStyle(.plain)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(.systemBackground))

      Divider()
    }
  }
}

private struct WorkoutHistorySummaryCard: View {
  let label: String
  let countText: String

  var body: some View {
    HStack(spacing: 12) {
      VStack(alignment: .leading, spacing: 6) {
        Text(label)
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(AppColors.textSecondary)

        Text(countText)
          .font(.system(size: 32, weight: .black))
          .foregroundColor(AppColors.textPrimary)
      }

      Spacer()

      ZStack {
        Circle()
          .fill(AppColors.accent.opacity(0.2))
          .frame(width: 44, height: 44)

        AppIcons.workouts
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(AppColors.accent)
      }
    }
    .padding(16)
    .background(
      LinearGradient(
        colors: [AppColors.accent.opacity(0.12), AppColors.infoBlue.opacity(0.08)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(18)
  }
}

private struct WorkoutHistorySectionView: View {
  let section: WorkoutHistorySection

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      Text(section.title)
        .font(.system(size: 12, weight: .black))
        .kerning(1.4)
        .foregroundColor(AppColors.textSecondary)

      VStack(spacing: 0) {
        ForEach(Array(section.rows.enumerated()), id: \.element.id) { index, row in
          NavigationLink(value: row.id) {
            WorkoutHistoryRowView(row: row)
              .contentShape(Rectangle())
          }
          .buttonStyle(.plain)

          if index != section.rows.count - 1 {
            Divider()
              .padding(.leading, 16)
          }
        }
      }
      .background(Color(.systemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 18)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
      .cornerRadius(18)
    }
  }
}

private struct WorkoutHistoryRowView: View {
  let row: WorkoutHistoryRow

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top, spacing: 8) {
        Text(row.timestampLabel)
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(AppColors.textSecondary)

        Spacer()

        if row.hasPersonalRecord {
          HStack(spacing: 4) {
            Image(systemName: "trophy")
              .font(.system(size: 10, weight: .semibold))
            Text("PR")
              .font(.system(size: 10, weight: .bold))
          }
          .foregroundColor(AppColors.textPrimary)
        }
      }

      Text(row.title)
        .font(.system(size: 22, weight: .black))
        .foregroundColor(AppColors.textPrimary)
        .lineLimit(2)

      HStack(spacing: 10) {
        HStack(spacing: 5) {
          AppIcons.location
            .font(.system(size: 11, weight: .semibold))
            .foregroundColor(AppColors.infoBlue)
          Text(row.locationLabel)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
            .lineLimit(1)
        }

        Text(row.type.badgeLabel)
          .font(.system(size: 11, weight: .black))
          .foregroundColor(row.type.accentColor)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(row.type.accentColor.opacity(0.12))
          .clipShape(Capsule())
      }

      HStack(spacing: 0) {
        statColumn(label: "DURATION", value: row.durationText, icon: "clock")
        statColumn(label: "EXERCISES", value: row.exerciseCountText, icon: "square.stack.3d.up")
        statColumn(label: "VOLUME", value: row.volumeText, icon: "arrow.up.forward")
      }
      .padding(.top, 4)
    }
    .padding(16)
  }

  private func statColumn(label: String, value: String, icon: String) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack(spacing: 4) {
        Image(systemName: icon)
          .font(.system(size: 10, weight: .semibold))
        Text(label)
          .font(.system(size: 10, weight: .bold))
      }
      .foregroundColor(AppColors.textSecondary)

      Text(value)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(AppColors.textPrimary)
        .lineLimit(1)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct WorkoutHistoryFilterSheet: View {
  @Environment(\.dismiss) private var dismiss
  @Binding var filters: WorkoutHistoryFilters

  let monthOptions: [WorkoutHistoryMonthOption]
  let locationOptions: [String]
  let onCancel: () -> Void
  let onClearAll: () -> Void
  let onApply: () -> Void

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        ScrollView {
          VStack(alignment: .leading, spacing: 20) {
            Text("Filter your workout history by month, workout type, or location.")
              .font(.system(size: 14))
              .foregroundColor(AppColors.textSecondary)

            filterSection(title: "MONTH") {
              optionButton(
                title: "All Months",
                isSelected: filters.selectedMonthKey == nil
              ) {
                filters.selectedMonthKey = nil
              }

              ForEach(monthOptions) { monthOption in
                optionButton(
                  title: monthOption.label,
                  isSelected: filters.selectedMonthKey == monthOption.id
                ) {
                  filters.selectedMonthKey = monthOption.id
                }
              }
            }

            filterSection(title: "WORKOUT TYPE") {
              optionButton(
                title: "All Types",
                isSelected: filters.selectedWorkoutType == nil
              ) {
                filters.selectedWorkoutType = nil
              }

              ForEach(WorkoutHistoryType.allCases) { workoutType in
                optionButton(
                  title: workoutType.displayLabel,
                  subtitle: workoutType.badgeLabel,
                  isSelected: filters.selectedWorkoutType == workoutType
                ) {
                  filters.selectedWorkoutType = workoutType
                }
              }
            }

            filterSection(title: "LOCATION") {
              optionButton(
                title: "All Locations",
                isSelected: filters.selectedLocation == nil
              ) {
                filters.selectedLocation = nil
              }

              ForEach(locationOptions, id: \.self) { location in
                optionButton(
                  title: location,
                  isSelected: filters.selectedLocation == location
                ) {
                  filters.selectedLocation = location
                }
              }
            }
          }
          .padding(16)
        }

        HStack(spacing: 12) {
          Button("Clear All") {
            onClearAll()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .foregroundColor(AppColors.accent)
          .background(Color(.systemGray6))
          .cornerRadius(12)

          Button("Apply Filters") {
            onApply()
            dismiss()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .foregroundColor(.white)
          .background(AppColors.accent)
          .cornerRadius(12)
        }
        .padding(.horizontal, 16)
        .padding(.bottom, 12)
      }
      .navigationTitle("Filters")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
            dismiss()
          }
        }
      }
    }
  }

  private func filterSection<Content: View>(title: String, @ViewBuilder content: () -> Content)
    -> some View
  {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .black))
        .kerning(1.2)
        .foregroundColor(AppColors.textSecondary)

      VStack(spacing: 8) {
        content()
      }
    }
  }

  private func optionButton(
    title: String,
    subtitle: String? = nil,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button(action: action) {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 3) {
          Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)

          if let subtitle {
            Text(subtitle)
              .font(.system(size: 10, weight: .black))
              .foregroundColor(AppColors.textSecondary)
              .kerning(0.8)
          }
        }

        Spacer()

        Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
          .font(.system(size: 18, weight: .semibold))
          .foregroundColor(isSelected ? AppColors.accent : AppColors.borderGray)
      }
      .padding(14)
      .background(isSelected ? AppColors.accent.opacity(0.08) : Color(.systemGray6))
      .overlay(
        RoundedRectangle(cornerRadius: 14)
          .stroke(isSelected ? AppColors.accent : AppColors.borderGray, lineWidth: 1)
      )
      .cornerRadius(14)
    }
    .buttonStyle(.plain)
  }
}
