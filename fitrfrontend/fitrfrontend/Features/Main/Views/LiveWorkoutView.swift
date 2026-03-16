//
//  LiveWorkoutView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/2/26.
//

import SwiftUI

struct LiveWorkoutView: View {
  @Environment(\.colorScheme) private var colorScheme
  @EnvironmentObject private var sessionStore: SessionStore
  @EnvironmentObject private var activeWorkoutCoordinator: ActiveWorkoutCoordinator
  @StateObject private var viewModel: LiveWorkoutViewModel
  @State private var showDiscardConfirmation = false
  @State private var showExerciseRemovalConfirmation = false
  @State private var pendingExerciseRemoval: LiveWorkoutExerciseState?
  @State private var showPlanSheet = false
  @State private var isFinishingWorkout = false
  @State private var shouldDismissLiveWorkoutAfterFinish = false

  init(context: ActiveWorkoutContext, sessionStore: SessionStore) {
    _viewModel = StateObject(
      wrappedValue: LiveWorkoutViewModel(context: context, sessionStore: sessionStore))
  }

  var body: some View {
    ZStack {
      liveBackgroundColor
        .ignoresSafeArea()

      if viewModel.isLoading && viewModel.workout == nil {
        ProgressView()
          .tint(AppColors.accent)
      } else {
        content
      }
    }
    .task {
      viewModel.attachCoordinator(activeWorkoutCoordinator)
      await viewModel.load()
    }
    .onChange(of: viewModel.restTimerEndsAt) { _, newValue in
      activeWorkoutCoordinator.updateRestTimer(endDate: newValue)
    }
    .onChange(of: viewModel.activeSetEditor?.id) { oldValue, newValue in
      guard oldValue != nil, newValue == nil else {
        return
      }

      viewModel.handleSetEditorDismissed()
    }
    .onChange(of: viewModel.showFinishSheet) { _, isPresented in
      guard !isPresented, shouldDismissLiveWorkoutAfterFinish else {
        return
      }

      shouldDismissLiveWorkoutAfterFinish = false

      Task {
        await Task.yield()
        activeWorkoutCoordinator.completeFinishedWorkout()
      }
    }
    .sheet(item: $viewModel.activeSetEditor) { editor in
      LiveWorkoutSetEditorSheet(
        editor: editor,
        isSubmitting: viewModel.isSubmitting,
        canDeleteLog: editor.setLogId != nil,
        isDeletingLog: viewModel.isDeletingSetLog,
        deleteErrorMessage: viewModel.setEditorMutationErrorMessage
      ) { editorId, draft in
        Task {
          await viewModel.saveSet(editorId: editorId, draft: draft)
        }
      } onDelete: { editorId in
        Task {
          await viewModel.deleteLoggedSet(editorId: editorId)
        }
      }
      .presentationDetents([.medium])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $viewModel.showEditSessionSheet) {
      WorkoutSessionEditSheet(
        draft: $viewModel.sessionEditDraft,
        initialDraft: viewModel.sessionEditBaselineDraft,
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
              activeWorkoutCoordinator.applyEditedSession(updatedWorkout)
            }
          }
        }
      )
    }
    .sheet(isPresented: $viewModel.showAddExerciseSheet) {
      LiveWorkoutExercisePickerSheet(
        exercises: viewModel.availableExercises,
        existingExerciseIds: Set(viewModel.exerciseStates.map(\.exercise.id))
      ) { exercise in
        await viewModel.addExercise(exercise)
      }
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $viewModel.showFinishSheet) {
      LiveWorkoutFinishSheet(
        title: viewModel.titleText,
        initialNotes: viewModel.finishSheetInitialNotes,
        initialLocationId: viewModel.finishSheetSelectedLocationId,
        completedExerciseCount: viewModel.completedExerciseCount,
        skippedPlannedSetCount: viewModel.skippedPlannedSetCount,
        addedExerciseCount: viewModel.addedExerciseCount,
        availableLocations: viewModel.availableLocations,
        isLoadingLocations: viewModel.isLoadingLocations,
        locationLoadErrorMessage: viewModel.locationLoadErrorMessage,
        isSubmitting: isFinishingWorkout
      ) { submittedTitle, submittedNotes, selectedLocationId in
        guard !isFinishingWorkout else {
          return
        }

        isFinishingWorkout = true

        Task {
          do {
            try await viewModel.pruneIncompleteExercisesBeforeFinish()
          } catch let apiError as APIErrorResponse {
            isFinishingWorkout = false
            viewModel.errorMessage = "Failed to clean up incomplete exercises: \(apiError.message)"
            return
          } catch {
            isFinishingWorkout = false
            viewModel.errorMessage = "Failed to clean up incomplete exercises before finishing."
            return
          }

          do {
            _ = try await activeWorkoutCoordinator.finishActiveWorkout(
              notes: submittedNotes,
              title: submittedTitle,
              locationId: selectedLocationId
            )
            shouldDismissLiveWorkoutAfterFinish = true
            isFinishingWorkout = false
            viewModel.showFinishSheet = false
          } catch let apiError as APIErrorResponse {
            isFinishingWorkout = false
            viewModel.errorMessage = apiError.message
          } catch {
            isFinishingWorkout = false
            viewModel.errorMessage = "Failed to finish the workout."
          }
        }
      }
      .presentationDetents([.medium, .large])
    }
    .sheet(isPresented: $showPlanSheet) {
      if let planId = viewModel.context.origin.planId {
        NavigationStack {
          PlanDetailView(planId: planId)
        }
        .environmentObject(sessionStore)
      }
    }
    .confirmationDialog(
      "Discard this workout?",
      isPresented: $showDiscardConfirmation
    ) {
      Button("Discard Workout", role: .destructive) {
        Task {
          do {
            try await activeWorkoutCoordinator.discardActiveWorkout()
          } catch let apiError as APIErrorResponse {
            viewModel.errorMessage = apiError.message
          } catch {
            viewModel.errorMessage = "Failed to discard the workout."
          }
        }
      }
      Button("Cancel", role: .cancel) {}
    } message: {
      Text("Your logged sets will be removed.")
    }
    .confirmationDialog(
      "Remove exercise?",
      isPresented: Binding(
        get: { showExerciseRemovalConfirmation },
        set: { isPresented in
          showExerciseRemovalConfirmation = isPresented
          if !isPresented {
            pendingExerciseRemoval = nil
          }
        }
      ),
      presenting: pendingExerciseRemoval
    ) { exerciseState in
      Button("Remove Exercise", role: .destructive) {
        pendingExerciseRemoval = nil
        showExerciseRemovalConfirmation = false
        Task {
          await viewModel.removeExercise(exerciseState)
        }
      }
      Button("Cancel", role: .cancel) {
        pendingExerciseRemoval = nil
        showExerciseRemovalConfirmation = false
      }
    } message: { exerciseState in
      Text("Remove \(exerciseState.exercise.name) from this workout? This cannot be undone.")
    }
  }

  private var content: some View {
    VStack(spacing: 0) {
      topBar

      ScrollViewReader { proxy in
        ScrollView {
          VStack(alignment: .leading, spacing: 18) {
            timerPanel

            if let errorMessage = viewModel.errorMessage {
              errorBanner(message: errorMessage)
            }

            planStrip

            VStack(spacing: 14) {
              ForEach(viewModel.exerciseStates) { state in
                LiveWorkoutExerciseCard(
                  exerciseState: state,
                  preferredWeightUnit: viewModel.preferredWeightUnit,
                  preferredDistanceUnit: viewModel.preferredDistanceUnit,
                  onSelectRow: { row in
                    viewModel.presentSetEditor(exerciseId: state.id, rowId: row.id)
                  },
                  onAddSet: {
                    viewModel.presentExtraSetEditor(for: state.id)
                  },
                  onRemove: {
                    pendingExerciseRemoval = state
                    showExerciseRemovalConfirmation = true
                  }
                )
                .id(state.id)
              }
            }

            Color.clear.frame(height: 170)
          }
          .padding(.horizontal, 16)
          .padding(.top, 16)
        }
        .onChange(of: viewModel.requestedScrollToExerciseId) { _, exerciseId in
          guard let exerciseId else {
            return
          }

          withAnimation(.easeInOut(duration: 0.2)) {
            proxy.scrollTo(exerciseId, anchor: .center)
          }

          viewModel.requestedScrollToExerciseId = nil
        }
      }
    }
    .safeAreaInset(edge: .bottom) {
      footer
    }
  }

  private var topBar: some View {
    VStack(spacing: 0) {
      HStack {
        Button {
          activeWorkoutCoordinator.dismissPresentedWorkout()
        } label: {
          Image(systemName: "chevron.left")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(chromePrimaryTextColor)
            .frame(width: 40, height: 40)
        }
        .buttonStyle(.plain)

        Spacer()

        Text("ACTIVE WORKOUT")
          .font(.system(size: 16, weight: .black))
          .foregroundColor(chromeSecondaryTextColor)

        Spacer()

        Menu {
          Button {
            viewModel.presentEditSession()
          } label: {
            Label("Edit Session Details", systemImage: "pencil")
          }

          Button(role: .destructive) {
            showDiscardConfirmation = true
          } label: {
            Label("Discard Workout", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(chromePrimaryTextColor)
            .frame(width: 40, height: 40)
        }
      }
      .padding(.horizontal, 16)
      .padding(.vertical, 12)
      .background(chromeBackgroundColor)

      Divider()
        .overlay(AppColors.borderGray.opacity(0.7))
    }
  }

  private var timerPanel: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("SESSION DURATION")
        .font(.system(size: 12, weight: .black))
        .foregroundColor(AppColors.accent)
        .kerning(0.8)

      Text(viewModel.elapsedText)
        .font(.system(size: 52, weight: .black))
        .foregroundColor(.white)

      HStack(spacing: 10) {
        Button {
          viewModel.toggleSessionTimerPause()
        } label: {
          HStack(spacing: 6) {
            Image(systemName: viewModel.isTimerPaused ? "play.fill" : "pause.fill")
              .font(.system(size: 12, weight: .semibold))
            Text(viewModel.isTimerPaused ? "Resume Workout Timer" : "Pause Workout Timer")
              .font(.system(size: 13, weight: .semibold))
          }
          .foregroundColor(Color.white.opacity(0.9))
          .padding(.horizontal, 12)
          .padding(.vertical, 8)
          .background(Color.white.opacity(0.08))
          .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        Spacer()
      }

      if viewModel.hasActiveRestTimer {
        VStack(alignment: .leading, spacing: 10) {
          HStack(alignment: .center) {
            HStack(spacing: 8) {
              Image(systemName: "timer")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppColors.accent)
              Text(viewModel.isTimerPaused ? "Rest Paused" : "Resting")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.white.opacity(0.86))
            }

            Spacer()

            Text(viewModel.restCountdownText)
              .font(.system(size: 28, weight: .black))
              .foregroundColor(.white)
              .monospacedDigit()
          }

          HStack(spacing: 10) {
            Button {
              viewModel.skipRestTimer()
            } label: {
              Label("Skip", systemImage: "forward.fill")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)

            Button {
              viewModel.extendRestTimer(seconds: 60)
            } label: {
              Text("+1:00")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(Color.white.opacity(0.9))
                .padding(.horizontal, 12)
                .padding(.vertical, 8)
                .background(Color.white.opacity(0.08))
                .clipShape(Capsule())
            }
            .buttonStyle(.plain)
          }
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.06))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.12), lineWidth: 1)
        )
        .cornerRadius(14)
      } else {
        VStack(alignment: .leading, spacing: 4) {
          Text("Rest Ready")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color.white.opacity(0.86))

          Text("Logging a set starts a 1:00 rest.")
            .font(.system(size: 12, weight: .medium))
            .foregroundColor(Color.white.opacity(0.64))
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color.white.opacity(0.04))
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(Color.white.opacity(0.08), lineWidth: 1)
        )
        .cornerRadius(14)
      }
    }
    .padding(18)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(
      LinearGradient(
        colors: [Color(red: 0.02, green: 0.06, blue: 0.18), Color(red: 0.04, green: 0.1, blue: 0.24)],
        startPoint: .topLeading,
        endPoint: .bottomTrailing
      )
    )
    .overlay(
      RoundedRectangle(cornerRadius: 22)
        .stroke(Color.white.opacity(0.08), lineWidth: 1)
    )
    .cornerRadius(22)
  }

  private var planStrip: some View {
    HStack(alignment: .center, spacing: 12) {
      VStack(alignment: .leading, spacing: 4) {
        Text(viewModel.planSummaryTitle)
          .font(.system(size: 24, weight: .black))
          .foregroundColor(AppColors.textPrimary)
          .lineLimit(2)

        Text(viewModel.planSummarySubtitle)
          .font(.system(size: 13, weight: .medium))
          .foregroundColor(AppColors.textSecondary)
      }

      Spacer()

      if viewModel.canViewPlan {
        Button("View Plan") {
          showPlanSheet = true
        }
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(chromePrimaryTextColor)
        .padding(.horizontal, 12)
        .padding(.vertical, 10)
        .background(chromeMutedBackgroundColor)
        .overlay(
          Capsule()
            .stroke(chromeMutedStrokeColor, lineWidth: 1)
        )
        .clipShape(Capsule())
      }
    }
  }

  private var footer: some View {
    VStack(spacing: 12) {
      Button {
        viewModel.presentAddExercisePicker()
      } label: {
        HStack(spacing: 8) {
          Image(systemName: "plus")
            .font(.system(size: 13, weight: .bold))
          Text("Add Exercise")
            .font(.system(size: 15, weight: .semibold))
        }
        .foregroundColor(chromePrimaryTextColor)
        .frame(maxWidth: .infinity)
        .frame(height: 52)
        .background(chromeMutedBackgroundColor)
        .overlay(
          RoundedRectangle(cornerRadius: 14)
            .stroke(chromeMutedStrokeColor, lineWidth: 1)
        )
        .cornerRadius(14)
      }
      .buttonStyle(.plain)

      Button {
        viewModel.presentFinishSheet()
      } label: {
        Text("Finish Workout")
          .font(.system(size: 18, weight: .black))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(Color(red: 0.95, green: 0.28, blue: 0.28))
          .cornerRadius(16)
      }
      .buttonStyle(.plain)
    }
    .padding(.horizontal, 16)
    .padding(.top, 12)
    .padding(.bottom, 12)
    .background(chromeBackgroundColor.opacity(colorScheme == .dark ? 0.96 : 1))
  }

  private func errorBanner(message: String) -> some View {
    HStack(spacing: 10) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 13, weight: .semibold))
        .foregroundColor(AppColors.errorRed)

      Text(message)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(AppColors.textPrimary)

      Spacer()
    }
    .padding(12)
    .background(errorBannerBackgroundColor)
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(errorBannerBorderColor, lineWidth: 1)
    )
    .cornerRadius(12)
  }

  private var liveBackgroundColor: Color {
    if colorScheme == .dark {
      return Color(red: 6.0 / 255.0, green: 10.0 / 255.0, blue: 16.0 / 255.0)
    }
    return AppColors.background
  }

  private var chromeBackgroundColor: Color {
    if colorScheme == .dark {
      return Color(red: 8.0 / 255.0, green: 13.0 / 255.0, blue: 21.0 / 255.0)
    }
    return AppColors.surface
  }

  private var chromePrimaryTextColor: Color {
    AppColors.textPrimary
  }

  private var chromeSecondaryTextColor: Color {
    AppColors.textSecondary
  }

  private var chromeMutedBackgroundColor: Color {
    colorScheme == .dark ? AppColors.surface.opacity(0.08) : AppColors.borderGray.opacity(0.25)
  }

  private var chromeMutedStrokeColor: Color {
    colorScheme == .dark ? AppColors.surface.opacity(0.2) : AppColors.borderGray
  }

  private var errorBannerBackgroundColor: Color {
    colorScheme == .dark ? AppColors.surface.opacity(0.06) : AppColors.errorRed.opacity(0.08)
  }

  private var errorBannerBorderColor: Color {
    colorScheme == .dark ? AppColors.surface.opacity(0.1) : AppColors.errorRed.opacity(0.24)
  }
}

private struct LiveWorkoutExerciseCard: View {
  let exerciseState: LiveWorkoutExerciseState
  let preferredWeightUnit: Unit
  let preferredDistanceUnit: Unit
  let onSelectRow: (LiveWorkoutSetState) -> Void
  let onAddSet: () -> Void
  let onRemove: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top, spacing: 12) {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(exerciseState.exercise.name)
              .font(.system(size: 22, weight: .black))
              .foregroundColor(AppColors.textPrimary)
              .lineLimit(2)

            Text(exerciseState.source == .planned ? "PLAN" : "ADDED")
              .font(.system(size: 9, weight: .black))
              .foregroundColor(exerciseState.source == .planned ? AppColors.accent : AppColors.warningYellow)
              .padding(.horizontal, 6)
              .padding(.vertical, 3)
              .background(
                (exerciseState.source == .planned ? AppColors.accent : AppColors.warningYellow)
                  .opacity(0.12)
              )
              .clipShape(Capsule())
          }

          Text(exerciseState.exercise.measurementType.workoutDisplayLabel)
            .font(.system(size: 12, weight: .semibold))
            .foregroundColor(AppColors.textSecondary)

          Text("\(exerciseState.loggedSetCount) logged • \(max(exerciseState.targetSetCount, 1)) planned")
            .font(.system(size: 11, weight: .medium))
            .foregroundColor(AppColors.textSecondary)
        }

        Spacer()

        if exerciseState.canRemove {
          Button {
            onRemove()
          } label: {
            Image(systemName: "trash")
              .font(.system(size: 14, weight: .semibold))
              .foregroundColor(AppColors.errorRed)
              .frame(width: 32, height: 32)
              .background(Color(.systemGray6))
              .clipShape(Circle())
          }
          .buttonStyle(.plain)
        }
      }

      VStack(spacing: 10) {
        ForEach(exerciseState.rows) { row in
          Button {
            onSelectRow(row)
          } label: {
            HStack(spacing: 10) {
              Text("\(row.setNumber)")
                .font(.system(size: 15, weight: .black))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 28, alignment: .leading)

              let renderedMetricValues = metricValues(
                for: row.actualValues ?? row.targetValues ?? LiveWorkoutMetricSnapshot(),
                measurementType: exerciseState.exercise.measurementType
              )

              ForEach(Array(renderedMetricValues.enumerated()), id: \.offset) { _, value in
                Text(value)
                  .font(.system(size: 14, weight: .semibold))
                  .foregroundColor(AppColors.textPrimary)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }

              statusView(for: row.status)
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .cornerRadius(12)
          }
          .buttonStyle(.plain)
        }
      }

      Button {
        onAddSet()
      } label: {
        HStack(spacing: 6) {
          Image(systemName: "plus")
            .font(.system(size: 12, weight: .bold))
          Text("Add Set")
            .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 44)
        .background(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 12)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(12)
      }
      .buttonStyle(.plain)
    }
    .padding(16)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 18)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
    .cornerRadius(18)
  }

  private func metricValues(
    for snapshot: LiveWorkoutMetricSnapshot,
    measurementType: MeasurementType
  ) -> [String] {
    let repsValue = snapshot.reps.map { "\($0) reps" } ?? "--"
    let caloriesValue = snapshot.calories.map { "\(Int($0.rounded())) cal" } ?? "--"

    switch measurementType {
    case .reps:
      return [repsValue]
    case .time:
      return [formattedDuration(snapshot.durationSeconds)]
    case .repsAndTime:
      return [repsValue, formattedDuration(snapshot.durationSeconds)]
    case .repsAndWeight:
      return [formattedWeight(snapshot.weight), repsValue]
    case .timeAndWeight:
      return [formattedWeight(snapshot.weight), formattedDuration(snapshot.durationSeconds)]
    case .distanceAndTime:
      return [formattedDistance(snapshot.distance), formattedDuration(snapshot.durationSeconds)]
    case .caloriesAndTime:
      return [caloriesValue, formattedDuration(snapshot.durationSeconds)]
    }
  }

  private func formattedWeight(_ kg: Float?) -> String {
    guard let kg, kg > 0 else {
      return "--"
    }
    let displayWeight = WorkoutWeightNormalizer.displayWeight(
      fromKg: kg,
      preferredUnit: preferredWeightUnit
    )
    let weightText = WorkoutWeightNormalizer.formatDisplayWeight(displayWeight)
    return "\(weightText) \(preferredWeightUnit.abbreviation)"
  }

  private func formattedDistance(_ km: Float?) -> String {
    guard let km, km > 0 else {
      return "--"
    }
    return UnitFormatter.formatDistance(km, preferredUnit: preferredDistanceUnit)
  }

  private func formattedDuration(_ durationSeconds: Int?) -> String {
    guard let durationSeconds, durationSeconds > 0 else {
      return "--"
    }
    return "\(DurationFormatter.minutesString(from: durationSeconds)) min"
  }

  @ViewBuilder
  private func statusView(for status: LiveWorkoutSetStatus) -> some View {
    switch status {
    case .logged:
      Image(systemName: "checkmark.circle.fill")
        .font(.system(size: 18, weight: .semibold))
        .foregroundColor(AppColors.accent)
    case .planned:
      Text("Log")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(AppColors.accent)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.accent.opacity(0.08))
        .overlay(
          Capsule()
            .stroke(AppColors.accent, lineWidth: 1)
        )
        .clipShape(Capsule())
    case .extra:
      Text("Extra")
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(AppColors.warningYellow)
        .padding(.horizontal, 10)
        .padding(.vertical, 6)
        .background(AppColors.warningYellow.opacity(0.12))
        .clipShape(Capsule())
    }
  }
}

private struct LiveWorkoutExercisePickerSheet: View {
  @Environment(\.dismiss) private var dismiss

  let exercises: [ExerciseResponse]
  let existingExerciseIds: Set<Int64>
  let onAdd: @MainActor (ExerciseResponse) async -> Void

  @State private var searchText = ""
  @State private var selectedExercise: ExerciseResponse?

  private var filteredExercises: [ExerciseResponse] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return exercises.sorted { $0.name < $1.name }
    }
    return exercises
      .filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
      .sorted { $0.name < $1.name }
  }

  private var canContinue: Bool {
    guard let selectedExercise else { return false }
    return !existingExerciseIds.contains(selectedExercise.id)
  }

  private var hasSelectableExercises: Bool {
    exercises.contains { !existingExerciseIds.contains($0.id) }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          HStack(spacing: 8) {
            Image(systemName: "magnifyingglass")
              .foregroundColor(AppColors.textSecondary)
            TextField("Search exercises", text: $searchText)
              .textInputAutocapitalization(.never)
              .disableAutocorrection(true)
          }
          .padding(12)
          .background(Color(.systemGray6))
          .cornerRadius(12)

          if !exercises.isEmpty && !hasSelectableExercises {
            Text("Every available exercise is already in this workout.")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(AppColors.textSecondary)
          }

          VStack(spacing: 8) {
            ForEach(filteredExercises) { exercise in
              let isSelected = selectedExercise?.id == exercise.id
              let isExisting = existingExerciseIds.contains(exercise.id)

              Button {
                guard !isExisting else { return }

                if selectedExercise?.id == exercise.id {
                  selectedExercise = nil
                } else {
                  selectedExercise = exercise
                }
              } label: {
                HStack {
                  VStack(alignment: .leading, spacing: 6) {
                    Text(exercise.name)
                      .font(.system(size: 16, weight: .semibold))
                      .foregroundColor(isExisting ? AppColors.textSecondary : AppColors.textPrimary)

                    Text(
                      exercise.measurementType.workoutDisplayLabel
                    )
                    .font(.system(size: 11, weight: .bold))
                    .foregroundColor(isExisting ? AppColors.textSecondary : AppColors.accent)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(
                      isExisting ? Color(.systemGray5) : AppColors.accent.opacity(0.12)
                    )
                    .cornerRadius(999)
                  }

                  Spacer()

                  if isExisting {
                    HStack(spacing: 6) {
                      Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 12, weight: .semibold))
                      Text("Already Picked")
                        .font(.system(size: 12, weight: .semibold))
                    }
                    .foregroundColor(AppColors.textSecondary)
                  } else if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(AppColors.accent)
                  }
                }
                .padding(12)
                .background(
                  isExisting
                    ? Color(.systemGray6)
                    : (isSelected ? AppColors.accent.opacity(0.08) : Color(.systemBackground))
                )
                .overlay(
                  RoundedRectangle(cornerRadius: 12)
                    .stroke(Color(.systemGray4), lineWidth: 1)
                )
                .cornerRadius(12)
                .opacity(isExisting ? 0.6 : 1)
              }
              .buttonStyle(.plain)
              .disabled(isExisting)
            }
          }
        }
        .padding(16)
      }
      .navigationTitle("Add Exercise")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            guard let selectedExercise else {
              return
            }
            guard !existingExerciseIds.contains(selectedExercise.id) else {
              return
            }

            Task { @MainActor in
              await onAdd(selectedExercise)
              dismiss()
            }
          }
          .disabled(!canContinue)
        }
      }
    }
  }
}

private struct LiveWorkoutFinishSheet: View {
  @Environment(\.dismiss) private var dismiss

  let title: String
  let completedExerciseCount: Int
  let skippedPlannedSetCount: Int
  let addedExerciseCount: Int
  let availableLocations: [LocationResponse]
  let isLoadingLocations: Bool
  let locationLoadErrorMessage: String?
  let isSubmitting: Bool
  let onFinish: (String, String?, Int64?) -> Void

  @State private var editedTitle: String
  @State private var notes: String
  @State private var selectedLocationId: Int64?

  init(
    title: String,
    initialNotes: String,
    initialLocationId: Int64?,
    completedExerciseCount: Int,
    skippedPlannedSetCount: Int,
    addedExerciseCount: Int,
    availableLocations: [LocationResponse],
    isLoadingLocations: Bool,
    locationLoadErrorMessage: String?,
    isSubmitting: Bool,
    onFinish: @escaping (String, String?, Int64?) -> Void
  ) {
    self.title = title
    self.completedExerciseCount = completedExerciseCount
    self.skippedPlannedSetCount = skippedPlannedSetCount
    self.addedExerciseCount = addedExerciseCount
    self.availableLocations = availableLocations
    self.isLoadingLocations = isLoadingLocations
    self.locationLoadErrorMessage = locationLoadErrorMessage
    self.isSubmitting = isSubmitting
    self.onFinish = onFinish
    _editedTitle = State(initialValue: title)
    _notes = State(initialValue: initialNotes)
    _selectedLocationId = State(initialValue: initialLocationId)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text("Finish Workout")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(AppColors.textPrimary)

          summaryRow(label: "Completed Exercises", value: "\(completedExerciseCount)")
          summaryRow(label: "Unfinished Planned Sets", value: "\(skippedPlannedSetCount)")
          summaryRow(label: "Added Exercises", value: "\(addedExerciseCount)")

          VStack(alignment: .leading, spacing: 8) {
            Text("Workout Title")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)
            TextField("Workout Title", text: $editedTitle)
              .textInputAutocapitalization(.words)
              .padding(12)
              .background(Color(.systemGray6))
              .cornerRadius(12)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)
            TextEditor(text: $notes)
              .disabled(isSubmitting)
              .frame(minHeight: 120)
              .padding(8)
              .background(Color(.systemGray6))
              .cornerRadius(12)
          }

          VStack(alignment: .leading, spacing: 10) {
            HStack {
              Text("Location")
                .font(.system(size: 13, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

              if isLoadingLocations {
                Spacer()

                ProgressView()
                  .controlSize(.small)
              }
            }

            if let locationLoadErrorMessage {
              inlineMessage(
                message: locationLoadErrorMessage,
                tint: AppColors.warningYellow
              )
            }

            if !isLoadingLocations && availableLocations.isEmpty {
              Text("No saved locations yet.")
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.textSecondary)
                .padding(.vertical, 4)
            }

            if !availableLocations.isEmpty {
              VStack(spacing: 8) {
                locationOptionRow(
                  title: "No location",
                  subtitle: nil,
                  isSelected: selectedLocationId == nil
                ) {
                  selectedLocationId = nil
                }

                ForEach(availableLocations) { location in
                  locationOptionRow(
                    title: location.name,
                    subtitle: location.address.trimmingCharacters(in: .whitespacesAndNewlines)
                      .isEmpty ? nil : location.address,
                    isSelected: selectedLocationId == location.id
                  ) {
                    selectedLocationId = location.id
                  }
                }
              }
            }
          }
        }
        .padding(16)
      }
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            dismiss()
          }
          .disabled(isSubmitting)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Finish") {
            let trimmedTitle = editedTitle.trimmingCharacters(in: .whitespacesAndNewlines)
            let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)
            onFinish(
              trimmedTitle,
              trimmedNotes.isEmpty ? nil : trimmedNotes,
              selectedLocationId
            )
          }
          .disabled(isSubmitting || editedTitle.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
        }
      }
    }
  }

  private func summaryRow(label: String, value: String) -> some View {
    HStack {
      Text(label)
        .font(.system(size: 14, weight: .medium))
        .foregroundColor(AppColors.textSecondary)

      Spacer()

      Text(value)
        .font(.system(size: 15, weight: .bold))
        .foregroundColor(AppColors.textPrimary)
    }
    .padding(.vertical, 4)
  }

  private func inlineMessage(message: String, tint: Color) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(tint)

      Text(message)
        .font(.system(size: 12, weight: .semibold))
        .foregroundColor(AppColors.textPrimary)
        .frame(maxWidth: .infinity, alignment: .leading)
    }
    .padding(12)
    .background(tint.opacity(0.08))
    .cornerRadius(12)
  }

  @ViewBuilder
  private func locationOptionRow(
    title: String,
    subtitle: String?,
    isSelected: Bool,
    action: @escaping () -> Void
  ) -> some View {
    Button {
      guard !isSubmitting else {
        return
      }

      action()
    } label: {
      HStack(spacing: 12) {
        Image(systemName: isSelected ? "largecircle.fill.circle" : "circle")
          .font(.system(size: 16, weight: .semibold))
          .foregroundColor(isSelected ? AppColors.accent : AppColors.textSecondary)

        VStack(alignment: .leading, spacing: 4) {
          Text(title)
            .font(.system(size: 15, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)

          if let subtitle {
            Text(subtitle)
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(AppColors.textSecondary)
              .multilineTextAlignment(.leading)
          }
        }

        Spacer()
      }
      .padding(12)
      .background(Color(.systemGray6))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(isSelected ? AppColors.accent : Color(.systemGray4), lineWidth: 1)
      )
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
    .disabled(isSubmitting)
  }
}

private struct LiveWorkoutSetEditorSheet: View {
  @EnvironmentObject private var sessionStore: SessionStore

  let editor: LiveWorkoutSetEditorContext
  let isSubmitting: Bool
  let canDeleteLog: Bool
  let isDeletingLog: Bool
  let deleteErrorMessage: String?
  let onSave: (String, LiveWorkoutSetDraft) -> Void
  let onDelete: (String) -> Void

  @State private var reps = ""
  @State private var weight = ""
  @State private var duration = ""
  @State private var distance = ""
  @State private var calories = ""
  @State private var localErrorMessage: String?
  @State private var didHydrateDisplayInputs = false
  @State private var initialCanonicalWeightKg: Float?
  @State private var initialNormalizedDisplayWeight: Float?
  @State private var isWeightInputDirty = false

  init(
    editor: LiveWorkoutSetEditorContext,
    isSubmitting: Bool,
    canDeleteLog: Bool,
    isDeletingLog: Bool,
    deleteErrorMessage: String?,
    onSave: @escaping (String, LiveWorkoutSetDraft) -> Void,
    onDelete: @escaping (String) -> Void
  ) {
    self.editor = editor
    self.isSubmitting = isSubmitting
    self.canDeleteLog = canDeleteLog
    self.isDeletingLog = isDeletingLog
    self.deleteErrorMessage = deleteErrorMessage
    self.onSave = onSave
    self.onDelete = onDelete
    _initialCanonicalWeightKg = State(initialValue: editor.suggestedValues.weight)
    _reps = State(initialValue: editor.suggestedValues.reps.map(String.init) ?? "")
    _weight = State(initialValue: "")
    _duration = State(
      initialValue: editor.suggestedValues.durationSeconds.map {
        DurationFormatter.minutesString(from: $0)
      } ?? ""
    )
    _distance = State(initialValue: "")
    _calories = State(initialValue: Self.displayValue(for: editor.suggestedValues.calories))
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text(editor.exercise.name)
            .font(.system(size: 22, weight: .black))
            .foregroundColor(AppColors.textPrimary)

          Text("Set \(editor.setNumber)\(editor.isExtra ? " • Extra" : "")")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppColors.accent)

          if let targetValues = editor.targetValues {
            Text(targetSummary(targetValues))
              .font(.system(size: 12, weight: .medium))
              .foregroundColor(AppColors.textSecondary)
          }

          if let localErrorMessage {
            Text(localErrorMessage)
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(AppColors.errorRed)
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(AppColors.errorRed.opacity(0.08))
              .cornerRadius(12)
          }

          if let deleteErrorMessage {
            Text(deleteErrorMessage)
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(AppColors.errorRed)
              .padding(.horizontal, 12)
              .padding(.vertical, 10)
              .frame(maxWidth: .infinity, alignment: .leading)
              .background(AppColors.errorRed.opacity(0.08))
              .cornerRadius(12)
          }

          form

          if canDeleteLog {
            Button(role: .destructive) {
              guard !isSubmitting, !isDeletingLog else {
                return
              }

              localErrorMessage = nil
              onDelete(editor.id)
            } label: {
              HStack(spacing: 8) {
                Image(systemName: "trash")
                  .font(.system(size: 13, weight: .bold))
                Text("Delete Log")
                  .font(.system(size: 15, weight: .bold))
              }
              .frame(maxWidth: .infinity)
              .padding(.vertical, 12)
            }
            .disabled(isSubmitting || isDeletingLog)
          }
        }
        .padding(16)
      }
      .navigationTitle("Log Set")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .confirmationAction) {
          Button(editor.setLogId == nil ? "Log" : "Save") {
            guard !isSubmitting, !isDeletingLog else {
              return
            }

            guard let draft = buildDraft() else {
              localErrorMessage = "Enter valid values for this set before logging."
              return
            }

            localErrorMessage = nil
            onSave(editor.id, draft)
          }
          .disabled(isSubmitting || isDeletingLog)
        }
      }
      .onAppear {
        hydrateDisplayInputsIfNeeded()
      }
      .onChange(of: reps) { _, _ in
        localErrorMessage = nil
      }
      .onChange(of: weight) { _, _ in
        localErrorMessage = nil
        updateWeightInputDirtyState()
      }
      .onChange(of: duration) { _, _ in
        localErrorMessage = nil
      }
      .onChange(of: distance) { _, _ in
        localErrorMessage = nil
      }
      .onChange(of: calories) { _, _ in
        localErrorMessage = nil
      }
      .onChange(of: deleteErrorMessage) { _, _ in
        localErrorMessage = nil
      }
    }
  }

  private var form: some View {
    VStack(alignment: .leading, spacing: 12) {
      switch editor.exercise.measurementType {
      case .reps:
        numberField("Reps", text: $reps)
      case .time:
        numberField("Duration (min)", text: $duration)
      case .repsAndTime:
        numberField("Reps", text: $reps)
        numberField("Duration (min)", text: $duration)
      case .repsAndWeight:
        numberField("Weight (\(preferredWeightUnit.abbreviation))", text: $weight)
        numberField("Reps", text: $reps)
      case .timeAndWeight:
        numberField("Weight (\(preferredWeightUnit.abbreviation))", text: $weight)
        numberField("Duration (min)", text: $duration)
      case .distanceAndTime:
        numberField("Distance (\(preferredDistanceUnit.abbreviation))", text: $distance)
        numberField("Duration (min)", text: $duration)
      case .caloriesAndTime:
        numberField("Calories", text: $calories)
        numberField("Duration (min)", text: $duration)
      }
    }
  }

  private func targetSummary(_ values: LiveWorkoutMetricSnapshot) -> String {
    switch editor.exercise.measurementType {
    case .reps:
      return "Target: \(values.reps ?? 0) reps"
    case .time:
      return "Target: \(DurationFormatter.minutesString(from: values.durationSeconds ?? 0)) min"
    case .repsAndTime:
      return "Target: \(values.reps ?? 0) reps • \(DurationFormatter.minutesString(from: values.durationSeconds ?? 0)) min"
    case .repsAndWeight:
      let targetWeight = formatWeight(values.weight)
      return "Target: \(targetWeight) • \(values.reps ?? 0) reps"
    case .timeAndWeight:
      let targetWeight = formatWeight(values.weight)
      return "Target: \(targetWeight) • \(DurationFormatter.minutesString(from: values.durationSeconds ?? 0)) min"
    case .distanceAndTime:
      let targetDistance = formatDistance(values.distance)
      return "Target: \(targetDistance) • \(DurationFormatter.minutesString(from: values.durationSeconds ?? 0)) min"
    case .caloriesAndTime:
      return "Target: \(Int((values.calories ?? 0).rounded())) cal • \(DurationFormatter.minutesString(from: values.durationSeconds ?? 0)) min"
    }
  }

  private func numberField(_ title: String, text: Binding<String>) -> some View {
    VStack(alignment: .leading, spacing: 8) {
      Text(title)
        .font(.system(size: 13, weight: .bold))
        .foregroundColor(AppColors.textPrimary)
      TextField(title, text: text)
        .keyboardType(.decimalPad)
        .padding(12)
        .background(Color(.systemGray6))
        .cornerRadius(12)
    }
  }

  private func buildDraft() -> LiveWorkoutSetDraft? {
    let maxReps = 1000
    let maxDurationSeconds = 21_600
    let maxWeight: Float = 10_000
    let maxDistance: Float = 1_000
    let maxCalories: Float = 50_000

    let repsValue = intValue(reps)
    let weightValue = backendWeight(from: floatValue(weight))
    let durationValue = DurationFormatter.seconds(fromMinutesText: duration)
    let distanceValue = backendDistance(from: floatValue(distance))
    let caloriesValue = floatValue(calories)

    switch editor.exercise.measurementType {
    case .reps:
      guard let repsValue, (1...maxReps).contains(repsValue) else { return nil }
      return LiveWorkoutSetDraft(
        reps: repsValue,
        weight: nil,
        durationSeconds: nil,
        distance: nil,
        calories: nil
      )
    case .time:
      guard let durationValue, (1...maxDurationSeconds).contains(durationValue) else { return nil }
      return LiveWorkoutSetDraft(
        reps: nil,
        weight: nil,
        durationSeconds: Int64(durationValue),
        distance: nil,
        calories: nil
      )
    case .repsAndTime:
      guard
        let repsValue, (1...maxReps).contains(repsValue),
        let durationValue, (1...maxDurationSeconds).contains(durationValue)
      else { return nil }
      return LiveWorkoutSetDraft(
        reps: repsValue,
        weight: nil,
        durationSeconds: Int64(durationValue),
        distance: nil,
        calories: nil
      )
    case .repsAndWeight:
      guard
        let repsValue, (1...maxReps).contains(repsValue),
        let weightValue, weightValue > 0, weightValue <= maxWeight
      else { return nil }
      return LiveWorkoutSetDraft(
        reps: repsValue,
        weight: weightValue,
        durationSeconds: nil,
        distance: nil,
        calories: nil
      )
    case .timeAndWeight:
      guard
        let durationValue, (1...maxDurationSeconds).contains(durationValue),
        let weightValue, weightValue > 0, weightValue <= maxWeight
      else {
        return nil
      }
      return LiveWorkoutSetDraft(
        reps: nil,
        weight: weightValue,
        durationSeconds: Int64(durationValue),
        distance: nil,
        calories: nil
      )
    case .distanceAndTime:
      guard
        let durationValue, (1...maxDurationSeconds).contains(durationValue),
        let distanceValue, distanceValue > 0, distanceValue <= maxDistance
      else {
        return nil
      }
      return LiveWorkoutSetDraft(
        reps: nil,
        weight: nil,
        durationSeconds: Int64(durationValue),
        distance: distanceValue,
        calories: nil
      )
    case .caloriesAndTime:
      guard
        let durationValue, (1...maxDurationSeconds).contains(durationValue),
        let caloriesValue, caloriesValue > 0, caloriesValue <= maxCalories
      else {
        return nil
      }
      return LiveWorkoutSetDraft(
        reps: nil,
        weight: nil,
        durationSeconds: Int64(durationValue),
        distance: nil,
        calories: caloriesValue
      )
    }
  }

  private func intValue(_ text: String) -> Int? {
    Int(text.trimmingCharacters(in: .whitespacesAndNewlines))
  }

  private func floatValue(_ text: String) -> Float? {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value = Float(trimmed), value.isFinite else {
      return nil
    }
    return value
  }

  private func backendWeight(from displayValue: Float?) -> Float? {
    guard let displayValue else {
      return nil
    }

    let normalizedDisplayWeight = WorkoutWeightNormalizer.snapToStep(displayValue)

    if !isWeightInputDirty,
      let initialCanonicalWeightKg,
      let initialNormalizedDisplayWeight,
      WorkoutWeightNormalizer.isEffectivelyEqual(normalizedDisplayWeight, initialNormalizedDisplayWeight)
    {
      return initialCanonicalWeightKg
    }

    return WorkoutWeightNormalizer.backendKg(
      fromDisplayWeight: normalizedDisplayWeight,
      preferredUnit: preferredWeightUnit
    )
  }

  private func backendDistance(from displayValue: Float?) -> Float? {
    guard let displayValue else {
      return nil
    }

    if preferredDistanceUnit == .km {
      return displayValue
    }
    return UnitConverter.miToKm(displayValue)
  }

  private func formatWeight(_ kg: Float?) -> String {
    guard let kg else {
      return "--"
    }
    let displayWeight = WorkoutWeightNormalizer.displayWeight(
      fromKg: kg,
      preferredUnit: preferredWeightUnit
    )
    let valueText = WorkoutWeightNormalizer.formatDisplayWeight(displayWeight)
    return "\(valueText) \(preferredWeightUnit.abbreviation)"
  }

  private func formatDistance(_ km: Float?) -> String {
    guard let km else {
      return "--"
    }
    return UnitFormatter.formatDistance(km, preferredUnit: preferredDistanceUnit)
  }

  private func hydrateDisplayInputsIfNeeded() {
    guard !didHydrateDisplayInputs else {
      return
    }

    if let weightValue = editor.suggestedValues.weight {
      let displayWeight = WorkoutWeightNormalizer.displayWeight(
        fromKg: weightValue,
        preferredUnit: preferredWeightUnit
      )
      initialCanonicalWeightKg = weightValue
      initialNormalizedDisplayWeight = displayWeight
      weight = WorkoutWeightNormalizer.formatDisplayWeight(displayWeight)
      isWeightInputDirty = false
    } else {
      initialCanonicalWeightKg = nil
      initialNormalizedDisplayWeight = nil
      isWeightInputDirty = false
    }

    if let distanceValue = editor.suggestedValues.distance {
      let displayDistance = preferredDistanceUnit == .km
        ? distanceValue
        : UnitConverter.kmToMi(distanceValue)
      distance = Self.displayValue(for: displayDistance)
    }

    didHydrateDisplayInputs = true
  }

  private func updateWeightInputDirtyState() {
    guard didHydrateDisplayInputs else {
      return
    }

    let trimmedWeight = weight.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let initialNormalizedDisplayWeight else {
      isWeightInputDirty = !trimmedWeight.isEmpty
      return
    }

    guard let parsedWeight = Float(trimmedWeight), parsedWeight.isFinite else {
      isWeightInputDirty = !trimmedWeight.isEmpty
      return
    }

    let normalizedWeight = WorkoutWeightNormalizer.snapToStep(parsedWeight)
    isWeightInputDirty = !WorkoutWeightNormalizer.isEffectivelyEqual(
      normalizedWeight,
      initialNormalizedDisplayWeight
    )
  }

  private static func displayValue(for value: Float?) -> String {
    guard let value else {
      return ""
    }
    return UnitFormatter.formatValue(value, decimalPlaces: value.rounded() == value ? 0 : 1)
  }
}
