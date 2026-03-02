//
//  WorkoutDetailView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/1/26.
//

import SwiftUI

struct WorkoutDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: WorkoutDetailViewModel
  private let onWorkoutUpdated: ((WorkoutSessionResponse) -> Void)?

  init(
    sessionStore: SessionStore,
    workoutId: Int64,
    mode: WorkoutDetailMode,
    initialWorkout: WorkoutSessionResponse? = nil,
    onWorkoutUpdated: ((WorkoutSessionResponse) -> Void)? = nil
  ) {
    self.onWorkoutUpdated = onWorkoutUpdated
    _viewModel = StateObject(
      wrappedValue: WorkoutDetailViewModel(
        sessionStore: sessionStore,
        workoutId: workoutId,
        mode: mode,
        initialWorkout: initialWorkout
      )
    )
  }

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      if viewModel.isLoading && viewModel.workout == nil {
        loadingState
      } else if let errorMessage = viewModel.errorMessage, viewModel.workout == nil {
        errorState(message: errorMessage)
      } else {
        content
      }
    }
    .navigationBarBackButtonHidden(true)
    .navigationBarHidden(true)
    .safeAreaInset(edge: .top) {
      topBar
    }
    .task {
      await viewModel.loadIfNeeded()
    }
    .sheet(isPresented: $viewModel.showEditSessionSheet) {
      WorkoutSessionEditSheet(
        draft: $viewModel.editDraft,
        initialDraft: viewModel.editBaselineDraft,
        availableLocations: viewModel.availableLocations,
        isLoadingLocations: viewModel.isLoadingLocations,
        isSaving: viewModel.isSavingSessionEdits,
        locationLoadErrorMessage: viewModel.locationLoadErrorMessage,
        saveErrorMessage: viewModel.sessionEditErrorMessage,
        onCancel: {
          viewModel.dismissEditSession()
        },
        onSave: {
          Task {
            if let updatedWorkout = await viewModel.saveSessionEdits() {
              onWorkoutUpdated?(updatedWorkout)
            }
          }
        }
      )
    }
  }

  private var content: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 22) {
        if let errorMessage = viewModel.errorMessage, viewModel.workout != nil {
          inlineErrorBanner(message: errorMessage)
            .padding(.horizontal, 16)
        }

        headerContentCard
          .padding(.horizontal, 16)

        notesSection
          .padding(.horizontal, 16)

        exercisesSection
          .padding(.horizontal, 16)

        if viewModel.mode.isInProgress {
          inProgressFooter
            .padding(.horizontal, 16)
        }

        Spacer(minLength: 92)
      }
      .padding(.top, 16)
      .padding(.bottom, 8)
    }
    .refreshable {
      await viewModel.reload()
    }
  }

  private var topBar: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          dismiss()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .frame(width: 80, alignment: .leading)

        Spacer()

        Text("WORKOUT SUMMARY")
          .font(.system(size: 17, weight: .bold))
          .foregroundColor(AppColors.textPrimary)

        Spacer()

        topBarTrailingActions
          .frame(width: 80, alignment: .trailing)
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(Color(.systemBackground))

      Divider()
    }
  }

  private var topBarTrailingActions: some View {
    HStack(spacing: 0) {
      if viewModel.mode.isCompleted {
        Button {
          viewModel.presentEditSession()
        } label: {
          Image(systemName: "pencil")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)
        .disabled(viewModel.workout == nil)
      } else {
        Color.clear
          .frame(width: 40, height: 40)
      }

      if let sharePayload = viewModel.sharePayload {
        ShareLink(item: sharePayload.text) {
          Image(systemName: "square.and.arrow.up")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
            .frame(width: 40, height: 40)
        }
      } else {
        Color.clear
          .frame(width: 40, height: 40)
      }
    }
  }

  private var headerContentCard: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(spacing: 8) {
        Text(viewModel.badgeText)
          .font(.system(size: 11, weight: .black))
          .foregroundColor(viewModel.workoutType.accentColor)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(viewModel.workoutType.accentColor.opacity(0.12))
          .clipShape(Capsule())

        Text(viewModel.sessionLabelText)
          .font(.system(size: 12, weight: .semibold))
          .foregroundColor(AppColors.textSecondary)
      }

      Text(viewModel.titleText)
        .font(.system(size: 30, weight: .black))
        .foregroundColor(AppColors.textPrimary)
        .lineLimit(2)

      HStack(spacing: 12) {
        ForEach(viewModel.summaryItems) { item in
          WorkoutDetailSummaryTile(item: item)
        }
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

  private var notesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(spacing: 8) {
        AppIcons.note
          .font(.system(size: 14, weight: .semibold))
          .foregroundColor(AppColors.accent)

        Text("WORKOUT NOTES")
          .font(.system(size: 13, weight: .black))
          .foregroundColor(AppColors.textPrimary)
          .kerning(0.7)
      }

      Text(viewModel.notesText)
        .font(.system(size: 14, weight: viewModel.hasNotes ? .medium : .regular))
        .foregroundColor(viewModel.hasNotes ? AppColors.textPrimary : AppColors.textSecondary)
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(14)
        .background(Color(.systemGray6))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(AppColors.borderGray, lineWidth: 1)
        )
        .cornerRadius(14)
    }
  }

  private var exercisesSection: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack {
        Text("EXERCISES LOG")
          .font(.system(size: 13, weight: .black))
          .foregroundColor(AppColors.textPrimary)
          .kerning(0.7)

        Spacer()

        Text(viewModel.exerciseCountText)
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(AppColors.textSecondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(Color(.systemGray6))
          .clipShape(Capsule())
      }

      VStack(spacing: 14) {
        ForEach(viewModel.exerciseCards) { card in
          WorkoutDetailExerciseCardView(
            card: card,
            showsOverflowAction: viewModel.mode.isInProgress
          )
        }
      }
    }
  }

  private var inProgressFooter: some View {
    VStack(spacing: 16) {
      Button {
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus")
            .font(.system(size: 13, weight: .bold))
          Text("Add Exercise")
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(AppColors.textPrimary, lineWidth: 1.5)
        )
        .cornerRadius(14)
      }
      .buttonStyle(.plain)
      .disabled(true)

      HStack {
        Spacer()

        Circle()
          .fill(AppColors.accent)
          .frame(width: 54, height: 54)
          .overlay(
            Image(systemName: "checkmark")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(.white)
          )
      }
    }
  }

  private var loadingState: some View {
    ScrollView {
      VStack(alignment: .leading, spacing: 20) {
        RoundedRectangle(cornerRadius: 18)
          .fill(Color(.systemGray6))
          .frame(height: 180)

        RoundedRectangle(cornerRadius: 18)
          .fill(Color(.systemGray6))
          .frame(height: 120)

        ForEach(0..<2, id: \.self) { _ in
          RoundedRectangle(cornerRadius: 18)
            .fill(Color(.systemGray6))
            .frame(height: 240)
        }

        Spacer(minLength: 92)
      }
      .padding(.horizontal, 16)
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

      Text("Error loading workout")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

      Text(message)
        .font(.system(size: 13))
        .foregroundColor(AppColors.textSecondary)
        .multilineTextAlignment(.center)

      Button("Retry") {
        Task {
          await viewModel.reload()
        }
      }
      .buttonStyle(.bordered)
      .tint(AppColors.accent)
    }
    .padding(24)
  }

  private func inlineErrorBanner(message: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 14, weight: .semibold))
        .foregroundColor(AppColors.errorRed)

      Text(message)
        .font(.system(size: 12, weight: .medium))
        .foregroundColor(AppColors.textPrimary)
        .lineLimit(2)

      Spacer()

      Button("Retry") {
        Task {
          await viewModel.reload()
        }
      }
      .font(.system(size: 12, weight: .semibold))
      .foregroundColor(AppColors.accent)
    }
    .padding(12)
    .background(Color(.systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

private struct WorkoutDetailSummaryTile: View {
  let item: WorkoutDetailSummaryItem

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 5) {
        Image(systemName: item.iconName)
          .font(.system(size: 11, weight: .semibold))
        Text(item.label)
          .font(.system(size: 10, weight: .black))
      }
      .foregroundColor(AppColors.textSecondary)

      Text(item.value)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(AppColors.textPrimary)
        .lineLimit(2)
        .minimumScaleFactor(0.75)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(12)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(14)
  }
}

private struct WorkoutDetailExerciseCardView: View {
  let card: WorkoutDetailExerciseCard
  let showsOverflowAction: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .center, spacing: 12) {
        avatar

        VStack(alignment: .leading, spacing: 4) {
          Text(card.title)
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(2)

          Text(card.subtitle)
            .font(.system(size: 13, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
        }

        Spacer()

        if showsOverflowAction {
          Image(systemName: "ellipsis")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.textSecondary)
            .frame(width: 32, height: 32)
        }
      }

      tableHeader

      VStack(spacing: 0) {
        ForEach(Array(card.rows.enumerated()), id: \.element.id) { index, row in
          WorkoutDetailSetRowView(row: row)

          if index != card.rows.count - 1 {
            Divider()
              .padding(.leading, 12)
          }
        }
      }
    }
    .padding(14)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(18)
  }

  private var avatar: some View {
    let backgroundOpacity = WorkoutHistoryType.modality(for: card.measurementType) == .hybrid ? 0.16 : 0.14

    return ZStack {
      Circle()
        .fill(card.avatarTint.opacity(backgroundOpacity))
        .frame(width: 42, height: 42)

      if card.avatarText.isEmpty {
        AppIcons.workouts
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(card.avatarTint)
      } else {
        Text(card.avatarText)
          .font(.system(size: 14, weight: .black))
          .foregroundColor(card.avatarTint)
      }
    }
  }

  private var tableHeader: some View {
    HStack(spacing: 0) {
      headerCell("SET")

      ForEach(card.columnHeaders, id: \.self) { header in
        headerCell(header)
      }

      headerCell("STATUS")
    }
    .padding(.vertical, 4)
  }

  private func headerCell(_ text: String) -> some View {
    Text(text)
      .font(.system(size: 10, weight: .black))
      .foregroundColor(AppColors.textSecondary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}

private struct WorkoutDetailSetRowView: View {
  let row: WorkoutDetailSetRow

  var body: some View {
    HStack(spacing: 0) {
      valueCell(row.setLabel)

      ForEach(Array(row.metricValues.enumerated()), id: \.offset) { _, value in
        valueCell(value)
      }

      statusCell
    }
    .padding(.vertical, 11)
  }

  private var statusCell: some View {
    Group {
      switch row.statusStyle {
      case .done:
        HStack(spacing: 4) {
          Image(systemName: "checkmark.circle")
            .font(.system(size: 11, weight: .semibold))
          Text(row.statusText)
            .font(.system(size: 11, weight: .bold))
        }
        .foregroundColor(AppColors.textSecondary)
      case .pending:
        Text(row.statusText)
          .font(.system(size: 11, weight: .semibold))
          .foregroundColor(AppColors.textSecondary)
      case .actionable:
        Text(row.statusText)
          .font(.system(size: 11, weight: .bold))
          .foregroundColor(AppColors.accent)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(AppColors.accent.opacity(0.1))
          .overlay(
            Capsule()
              .stroke(AppColors.accent, lineWidth: 1)
          )
          .clipShape(Capsule())
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  private func valueCell(_ value: String) -> some View {
    Text(value)
      .font(.system(size: 14, weight: .semibold))
      .foregroundColor(AppColors.textPrimary)
      .frame(maxWidth: .infinity, alignment: .leading)
  }
}
