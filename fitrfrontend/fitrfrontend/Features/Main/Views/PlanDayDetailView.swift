//
//  PlanDayDetailView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/25/26.
//

import SwiftUI

struct PlanDayDetailView: View {
  @Environment(\.dismiss) private var dismiss
  @State private var orderedDays: [EnrichedPlanDay]
  @State private var selectedDayId: Int64

  let planId: Int64
  let planName: String
  private let onDayDeleted: (Int64) -> Void

  init(
    planId: Int64,
    planName: String,
    days: [EnrichedPlanDay],
    initialDayId: Int64,
    onDayDeleted: @escaping (Int64) -> Void
  ) {
    let sortedDays = days.sorted { $0.dayNumber < $1.dayNumber }
    let resolvedDayId = sortedDays.contains(where: { $0.id == initialDayId })
      ? initialDayId
      : (sortedDays.first?.id ?? initialDayId)

    self.planId = planId
    self.planName = planName
    self.onDayDeleted = onDayDeleted
    _orderedDays = State(initialValue: sortedDays)
    _selectedDayId = State(initialValue: resolvedDayId)
  }

  var body: some View {
    ZStack {
      Color(.systemBackground).ignoresSafeArea()

      if !orderedDays.isEmpty {
        TabView(selection: $selectedDayId) {
          ForEach(Array(orderedDays.enumerated()), id: \.element.id) { index, day in
            PlanDayDetailPageView(
              planId: planId,
              planName: planName,
              day: day,
              pageIndex: index,
              pageCount: orderedDays.count,
              isActive: selectedDayId == day.id,
              onBack: { dismiss() },
              onDeleteDay: handleDeletedDay
            )
            .tag(day.id)
          }
        }
        .tabViewStyle(.page(indexDisplayMode: .never))
      }
    }
    .navigationBarBackButtonHidden(true)
  }

  private func handleDeletedDay(_ dayId: Int64) {
    guard let deletedIndex = orderedDays.firstIndex(where: { $0.id == dayId }) else {
      return
    }

    orderedDays.remove(at: deletedIndex)
    onDayDeleted(dayId)

    guard !orderedDays.isEmpty else {
      dismiss()
      return
    }

    let nextIndex = min(deletedIndex, orderedDays.count - 1)
    selectedDayId = orderedDays[nextIndex].id
  }
}

private struct PlanDayDetailPageView: View {
  @StateObject private var viewModel: PlanDayDetailViewModel

  let planName: String
  let day: EnrichedPlanDay
  let pageIndex: Int
  let pageCount: Int
  let isActive: Bool
  let onBack: () -> Void
  let onDeleteDay: (Int64) -> Void

  @State private var editingExercise: EnrichedPlanExercise?
  @State private var hasLoaded = false

  init(
    planId: Int64,
    planName: String,
    day: EnrichedPlanDay,
    pageIndex: Int,
    pageCount: Int,
    isActive: Bool,
    onBack: @escaping () -> Void,
    onDeleteDay: @escaping (Int64) -> Void
  ) {
    _viewModel = StateObject(
      wrappedValue: PlanDayDetailViewModel(
        planId: planId,
        dayId: day.id,
        dayName: day.name,
        dayNumber: day.dayNumber
      ))

    self.planName = planName
    self.day = day
    self.pageIndex = pageIndex
    self.pageCount = pageCount
    self.isActive = isActive
    self.onBack = onBack
    self.onDeleteDay = onDeleteDay
  }

  private var estimatedMinutesText: String {
    "\(viewModel.estimatedMinutes) min"
  }

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 14) {
          VStack(alignment: .leading, spacing: 8) {
            HStack(alignment: .top, spacing: 12) {
              Text(viewModel.dayName)
                .font(.system(size: 34, weight: .black))
                .foregroundColor(AppColors.textPrimary)
                .frame(maxWidth: .infinity, alignment: .leading)

              PlanDayPagerIndicator(pageCount: pageCount, currentIndex: pageIndex)
                .padding(.top, 10)
            }

            Text("\(viewModel.weekdayName) • Part of the \"\(planName)\" plan.")
              .font(.system(size: 16))
              .foregroundColor(AppColors.textSecondary)
          }

          HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 6) {
              Label {
                Text("EST. TIME")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "clock")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text(estimatedMinutesText)
                .font(.system(size: 28, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
              .frame(height: 58)
              .padding(.horizontal, 14)

            VStack(alignment: .leading, spacing: 6) {
              Label {
                Text("EXERCISES")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "flame")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text("\(viewModel.exerciseCount)")
                .font(.system(size: 28, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(Color(.systemGray6))
          .overlay(
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color(.systemGray4), lineWidth: 1)
          )
          .cornerRadius(14)

          HStack {
            Text("ROUTINE")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button("ADD EXERCISE") {
              viewModel.showAddExerciseSheet = true
            }
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 6)
            .background(AppColors.accent.opacity(0.08))
            .clipShape(Capsule())
          }

          if viewModel.isLoading {
            HStack {
              Spacer()
              ProgressView()
              Spacer()
            }
            .padding(.vertical, 24)
          } else if viewModel.exercises.isEmpty {
            VStack(spacing: 12) {
              Image(systemName: "dumbbell")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
              Text("No exercises yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(Color(.systemGray6))
            .cornerRadius(12)
          } else {
            VStack(spacing: 12) {
              ForEach(viewModel.exercises) { exercise in
                PlanDayExerciseCard(
                  exercise: exercise,
                  onEdit: {
                    editingExercise = exercise
                  },
                  onRemove: {
                    viewModel.requestRemove(exercise)
                  }
                )
              }
            }
          }

          Spacer(minLength: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
      }
    }
    .navigationBarBackButtonHidden(true)
    .safeAreaInset(edge: .top) {
      VStack(spacing: 0) {
        HStack {
          Button {
            onBack()
          } label: {
            Image(systemName: "chevron.left")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(AppColors.textPrimary)
          }
          .frame(width: 44, alignment: .leading)

          Spacer()

          Text("PLAN DAY")
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          Spacer()

          Menu {
            Button("Add Exercise") {
              viewModel.showAddExerciseSheet = true
            }
            Button(role: .destructive) {
              viewModel.showDeleteDayConfirmation = true
            } label: {
              Label("Delete Day", systemImage: "trash")
            }
          } label: {
            Text("Edit")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(AppColors.accent)
              .frame(width: 44, alignment: .trailing)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))

        Divider()
      }
    }
    .safeAreaInset(edge: .bottom) {
      Button {
      } label: {
        HStack {
          Text("Start This Workout")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.leading, 18)
          Spacer()
        }
        .frame(height: 56)
        .background(AppColors.accent)
        .cornerRadius(14)
        .overlay(alignment: .trailing) {
          Circle()
            .fill(AppColors.accent)
            .frame(width: 44, height: 44)
            .shadow(color: AppColors.accent.opacity(0.28), radius: 4, x: 0, y: 3)
            .overlay {
              Image(systemName: "plus")
                .font(.system(size: 20, weight: .semibold))
                .foregroundColor(.white)
            }
            .padding(.trailing, 6)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.vertical, 8)
      .padding(.bottom, 56)
      .background(Color(.systemBackground))
    }
    .onAppear {
      loadIfNeeded()
    }
    .onChange(of: isActive) { _, active in
      if active {
        loadIfNeeded()
      }
    }
    .onChange(of: viewModel.didDeleteDay) { _, didDeleteDay in
      if didDeleteDay {
        onDeleteDay(day.id)
        viewModel.didDeleteDay = false
      }
    }
    .alert(
      "Error",
      isPresented: Binding(
        get: { viewModel.errorMessage != nil },
        set: { _ in viewModel.errorMessage = nil }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(viewModel.errorMessage ?? "")
    }
    .confirmationDialog(
      "Remove exercise?",
      isPresented: $viewModel.showRemoveConfirmation
    ) {
      Button("Remove", role: .destructive) {
        Task {
          await viewModel.confirmRemove()
        }
      }
      Button("Cancel", role: .cancel) {}
    }
    .confirmationDialog(
      "Delete workout day?",
      isPresented: $viewModel.showDeleteDayConfirmation
    ) {
      Button("Delete", role: .destructive) {
        Task {
          await viewModel.deleteDay()
        }
      }
      Button("Cancel", role: .cancel) {}
    }
    .sheet(isPresented: $viewModel.showAddExerciseSheet) {
      AddPlanDayExerciseSheet(
        exercises: viewModel.availableExercises,
        unavailableExerciseIds: viewModel.existingExerciseIds
      ) { exercise, targets in
        await viewModel.addExercise(exercise: exercise, targets: targets)
      }
    }
    .sheet(item: $editingExercise) { exercise in
      let planExerciseId = exercise.id
      let catalogExerciseId = exercise.exerciseId
      EditPlanDayExerciseTargetsSheet(exercise: exercise) {
        sets,
        reps,
        durationSeconds,
        distance,
        calories,
        weight in
        Task {
          await viewModel.updateExercise(
            planExerciseId: planExerciseId,
            catalogExerciseId: catalogExerciseId,
            targetSets: sets,
            targetReps: reps,
            targetDurationSeconds: durationSeconds,
            targetDistance: distance,
            targetCalories: calories,
            targetWeight: weight
          )
        }
      }
    }
  }

  private func loadIfNeeded() {
    guard isActive, !hasLoaded else { return }
    hasLoaded = true
    Task {
      await viewModel.load()
    }
  }
}

private struct PlanDayPagerIndicator: View {
  let pageCount: Int
  let currentIndex: Int

  var body: some View {
    if pageCount > 1 {
      HStack(spacing: 6) {
        ForEach(0..<pageCount, id: \.self) { index in
          if index == currentIndex {
            Capsule()
              .fill(AppColors.accent)
              .frame(width: 14, height: 4)
          } else {
            Circle()
              .fill(AppColors.borderGray.opacity(0.85))
              .frame(width: 4, height: 4)
          }
        }
      }
    }
  }
}

struct PlanDayExerciseCard: View {
  @EnvironmentObject private var sessionStore: SessionStore

  let exercise: EnrichedPlanExercise
  let onEdit: () -> Void
  let onRemove: () -> Void
  private let maxVisibleSets = 30
  private let setColumnWidth: CGFloat = 40
  private let rowHeight: CGFloat = 42

  private var setCount: Int {
    min(max(exercise.targetSets, 1), maxVisibleSets)
  }

  private var hasTruncatedSetList: Bool {
    exercise.targetSets > maxVisibleSets
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  private var columns: [ExerciseColumn] {
    switch exercise.measurementType {
    case .reps:
      return [
        ExerciseColumn(header: "REPS") { "\($0.targetReps > 0 ? "\($0.targetReps)" : "--")" }
      ]

    case .time:
      return [
        ExerciseColumn(header: "TIME (sec)") {
          "\($0.targetDurationSeconds > 0 ? "\($0.targetDurationSeconds)" : "--")"
        }
      ]

    case .repsAndTime:
      return [
        ExerciseColumn(header: "REPS") { "\($0.targetReps > 0 ? "\($0.targetReps)" : "--")" },
        ExerciseColumn(header: "TIME (sec)") {
          "\($0.targetDurationSeconds > 0 ? "\($0.targetDurationSeconds)" : "--")"
        },
      ]

    case .timeAndWeight:
      return [
        ExerciseColumn(header: "TIME (sec)") {
          "\($0.targetDurationSeconds > 0 ? "\($0.targetDurationSeconds)" : "--")"
        },
        ExerciseColumn(header: "WEIGHT (\(preferredWeightUnit.abbreviation))") {
          $0.targetWeight > 0 ? formattedWeight($0.targetWeight) : "--"
        },
      ]

    case .repsAndWeight:
      return [
        ExerciseColumn(header: "REPS") { "\($0.targetReps > 0 ? "\($0.targetReps)" : "--")" },
        ExerciseColumn(header: "WEIGHT (\(preferredWeightUnit.abbreviation))") {
          $0.targetWeight > 0 ? formattedWeight($0.targetWeight) : "--"
        },
      ]

    case .distanceAndTime:
      return [
        ExerciseColumn(header: "DISTANCE (\(preferredDistanceUnit.abbreviation))") {
          $0.targetDistance > 0 ? formattedDistance($0.targetDistance) : "--"
        },
        ExerciseColumn(header: "TIME (sec)") {
          "\($0.targetDurationSeconds > 0 ? "\($0.targetDurationSeconds)" : "--")"
        },
      ]

    case .caloriesAndTime:
      return [
        ExerciseColumn(header: "CALORIES") {
          "\($0.targetCalories > 0 ? "\(Int($0.targetCalories))" : "--")"
        },
        ExerciseColumn(header: "TIME (sec)") {
          "\($0.targetDurationSeconds > 0 ? "\($0.targetDurationSeconds)" : "--")"
        },
      ]

    case .none:
      return [
        ExerciseColumn(header: "TARGET") { _ in "--" }
      ]
    }
  }

  private func formattedWeight(_ kg: Float) -> String {
    let displayValue = preferredWeightUnit == .kg ? kg : UnitConverter.kgToLb(kg)
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
  }

  private func formattedDistance(_ km: Float) -> String {
    let displayValue = preferredDistanceUnit == .km ? km : UnitConverter.kmToMi(km)
    return UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 6) {
          Text(exercise.measurementBadge)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 3)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          Text(exercise.name)
            .font(.system(size: 28, weight: .black))
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(2)
        }

        Spacer()

        Menu {
          Button {
            onEdit()
          } label: {
            Label("Edit", systemImage: "pencil")
          }

          Button(role: .destructive) {
            onRemove()
          } label: {
            Label("Remove from day", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 13, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 20, height: 20)
        }
      }

      VStack(spacing: 0) {
        HStack(spacing: 8) {
          Text("SET")
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(.secondary)
            .frame(width: setColumnWidth, alignment: .leading)

          ForEach(Array(columns.enumerated()), id: \.offset) { _, column in
            Text(column.header)
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        .padding(.horizontal, 10)
        .padding(.bottom, 6)

        VStack(spacing: 0) {
          ForEach(1...setCount, id: \.self) { setIndex in
            HStack(spacing: 8) {
              Text("\(setIndex)")
                .font(.system(size: 18, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: setColumnWidth, alignment: .leading)

              ForEach(Array(columns.enumerated()), id: \.offset) { index, column in
                Text(column.getValue(exercise))
                  .font(.system(size: 18, weight: .bold))
                  .foregroundColor(index == 0 ? AppColors.textPrimary : AppColors.accent)
                  .frame(maxWidth: .infinity, alignment: .center)
              }
            }
            .frame(height: rowHeight)
            .padding(.horizontal, 10)

            if setIndex != setCount {
              Divider()
            }
          }
        }
        .background(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(10)
      }

      if hasTruncatedSetList {
        Text("Showing first \(maxVisibleSets) sets")
          .font(.system(size: 10, weight: .semibold))
          .foregroundColor(.secondary)
      }
    }
    .padding(12)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

struct AddPlanDayExerciseSheet: View {
  @Environment(\.dismiss) private var dismiss

  let exercises: [ExerciseResponse]
  let unavailableExerciseIds: Set<Int64>
  let onAdd: (ExerciseResponse, PlanExerciseTargets) async -> Void

  @State private var searchText = ""
  @State private var selectedExercise: ExerciseResponse?
  @State private var showTargetsSheet = false

  private var filteredExercises: [ExerciseResponse] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return exercises.sorted { $0.name < $1.name }
    }
    return exercises.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
      .sorted { $0.name < $1.name }
  }

  private var canContinue: Bool {
    guard let selectedExercise else { return false }
    return !unavailableExerciseIds.contains(selectedExercise.id)
  }

  private var hasSelectableExercises: Bool {
    exercises.contains { !unavailableExerciseIds.contains($0.id) }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Choose Exercise")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          searchField

          if !exercises.isEmpty && !hasSelectableExercises {
            Text("Every available exercise is already in this workout day.")
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(AppColors.textSecondary)
          }

          VStack(spacing: 8) {
            ForEach(filteredExercises) { exercise in
              exerciseRow(exercise)
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
            showTargetsSheet = true
          }
          .disabled(!canContinue)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .sheet(isPresented: $showTargetsSheet) {
      if let exercise = selectedExercise {
        AddPlanDayExerciseTargetsSheet(exercise: exercise) { targets in
          await onAdd(exercise, targets)
          dismiss()
        }
        .presentationDetents([.medium])
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: 8) {
      Image(systemName: "magnifyingglass")
        .foregroundColor(.secondary)
      TextField("Search exercises", text: $searchText)
        .textInputAutocapitalization(.never)
        .disableAutocorrection(true)
    }
    .padding(12)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private func exerciseRow(_ exercise: ExerciseResponse) -> some View {
    let isSelected = selectedExercise?.id == exercise.id
    let isUnavailable = unavailableExerciseIds.contains(exercise.id)

    return Button {
      guard !isUnavailable else { return }

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
            .foregroundColor(isUnavailable ? AppColors.textSecondary : AppColors.textPrimary)

          Text(exercise.measurementType.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(isUnavailable ? AppColors.textSecondary : AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(
              isUnavailable ? Color(.systemGray5) : AppColors.accent.opacity(0.12)
            )
            .cornerRadius(999)
        }

        Spacer()

        if isUnavailable {
          HStack(spacing: 6) {
            Image(systemName: "checkmark.circle.fill")
              .font(.system(size: 12, weight: .semibold))
            Text("Already Added")
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
        isUnavailable
          ? Color(.systemGray6)
          : (isSelected ? AppColors.accent.opacity(0.08) : Color(.systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.systemGray4), lineWidth: 1)
      )
      .cornerRadius(12)
      .opacity(isUnavailable ? 0.6 : 1)
    }
    .buttonStyle(.plain)
    .disabled(isUnavailable)
  }

}

struct AddPlanDayExerciseTargetsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var sessionStore: SessionStore

  let exercise: ExerciseResponse
  let onAdd: (PlanExerciseTargets) async -> Void

  @State private var targetSets = ""
  @State private var targetReps = ""
  @State private var targetDuration = ""
  @State private var targetDistance = ""
  @State private var targetCalories = ""
  @State private var targetWeight = ""
  private let maxSets = 30
  private let maxReps = 200
  private let maxDurationSeconds = 21_600
  private let maxDistance = Float(1_000)
  private let maxCalories = Float(10_000)
  private let maxWeight = Float(1_000)

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  private var isFormValid: Bool {
    let sets = intValue(targetSets, minimum: 1, maximum: maxSets)
    if sets <= 0 { return false }

    switch exercise.measurementType {
    case .reps:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
    case .time:
      return intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .repsAndTime:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .repsAndWeight:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
        && floatValue(targetWeight, maximum: maxWeight) > 0
    case .timeAndWeight:
      return intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
        && floatValue(targetWeight, maximum: maxWeight) > 0
    case .distanceAndTime:
      return floatValue(targetDistance, maximum: maxDistance) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .caloriesAndTime:
      return floatValue(targetCalories, maximum: maxCalories) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text(exercise.name)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          Text(exercise.measurementType.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          targetForm
        }
        .padding(16)
      }
      .navigationTitle("Targets")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Back") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Add") {
            let weightValue = backendWeight(from: floatValue(targetWeight, maximum: maxWeight))
            let distanceValue = backendDistance(from: floatValue(targetDistance, maximum: maxDistance))
            let targets = PlanExerciseTargets(
              sets: intValue(targetSets, minimum: 1, maximum: maxSets),
              reps: intValue(targetReps, minimum: 0, maximum: maxReps),
              durationSeconds: intValue(targetDuration, minimum: 0, maximum: maxDurationSeconds),
              distance: distanceValue,
              calories: floatValue(targetCalories, maximum: maxCalories),
              weight: weightValue
            )
            Task {
              await onAdd(targets)
              dismiss()
            }
          }
          .disabled(!isFormValid)
        }
      }
    }
  }

  private var targetForm: some View {
    VStack(alignment: .leading, spacing: 12) {
      inputField(title: "Sets", text: $targetSets, placeholder: "3")

      switch exercise.measurementType {
      case .reps:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
      case .time:
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .repsAndTime:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .repsAndWeight:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
        inputField(
          title: "Target Weight (\(preferredWeightUnit.abbreviation))", text: $targetWeight,
          placeholder: "50", keyboard: .decimalPad
        )
      case .timeAndWeight:
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
        inputField(
          title: "Target Weight (\(preferredWeightUnit.abbreviation))", text: $targetWeight,
          placeholder: "50", keyboard: .decimalPad
        )
      case .distanceAndTime:
        inputField(
          title: "Target Distance (\(preferredDistanceUnit.abbreviation))", text: $targetDistance,
          placeholder: "1.0",
          keyboard: .decimalPad)
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .caloriesAndTime:
        inputField(
          title: "Target Calories", text: $targetCalories, placeholder: "200", keyboard: .decimalPad
        )
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      }
    }
    .padding(12)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private func inputField(
    title: String,
    text: Binding<String>,
    placeholder: String,
    keyboard: UIKeyboardType = .numberPad
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title.uppercased())
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(.secondary)
      TextField(placeholder, text: text)
        .keyboardType(keyboard)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
  }

  private func intValue(_ text: String, minimum: Int = 0, maximum: Int) -> Int {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value = Int(trimmed), value >= minimum, value <= maximum else { return 0 }
    return value
  }

  private func floatValue(_ text: String, maximum: Float) -> Float {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value = Float(trimmed), value.isFinite, value >= 0, value <= maximum else {
      return 0
    }
    return value
  }

  private func backendWeight(from value: Float) -> Float {
    let kgValue = preferredWeightUnit == .kg ? value : UnitConverter.lbToKg(value)
    return UnitConverter.round(kgValue, decimalPlaces: 1)
  }

  private func backendDistance(from value: Float) -> Float {
    let kmValue = preferredDistanceUnit == .km ? value : UnitConverter.miToKm(value)
    return UnitConverter.round(kmValue, decimalPlaces: 1)
  }
}

struct EditPlanDayExerciseTargetsSheet: View {
  @Environment(\.dismiss) private var dismiss
  @EnvironmentObject private var sessionStore: SessionStore

  let exercise: EnrichedPlanExercise
  let onUpdate: (Int, Int, Int, Float, Float, Float) -> Void

  @State private var targetSets: String
  @State private var targetReps: String
  @State private var targetDuration: String
  @State private var targetDistance: String
  @State private var targetCalories: String
  @State private var targetWeight: String
  private let maxSets = 30
  private let maxReps = 200
  private let maxDurationSeconds = 21_600
  private let maxDistance = Float(1_000)
  private let maxCalories = Float(10_000)
  private let maxWeight = Float(1_000)

  init(
    exercise: EnrichedPlanExercise,
    onUpdate: @escaping (Int, Int, Int, Float, Float, Float) -> Void
  ) {
    self.exercise = exercise
    self.onUpdate = onUpdate
    _targetSets = State(initialValue: "\(exercise.targetSets)")
    _targetReps = State(initialValue: exercise.targetReps > 0 ? "\(exercise.targetReps)" : "")
    _targetDuration = State(
      initialValue: exercise.targetDurationSeconds > 0 ? "\(exercise.targetDurationSeconds)" : ""
    )
    _targetDistance = State(initialValue: "")
    _targetCalories = State(initialValue: "")
    _targetWeight = State(initialValue: "")
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private var preferredDistanceUnit: Unit {
    sessionStore.userProfile?.preferredDistanceUnit ?? .km
  }

  private var isFormValid: Bool {
    let sets = intValue(targetSets, minimum: 1, maximum: maxSets)
    if sets <= 0 { return false }

    switch exercise.measurementType {
    case .reps:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
    case .time:
      return intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .repsAndTime:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .repsAndWeight:
      return intValue(targetReps, minimum: 1, maximum: maxReps) > 0
        && floatValue(targetWeight, maximum: maxWeight) > 0
    case .timeAndWeight:
      return intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
        && floatValue(targetWeight, maximum: maxWeight) > 0
    case .distanceAndTime:
      return floatValue(targetDistance, maximum: maxDistance) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .caloriesAndTime:
      return floatValue(targetCalories, maximum: maxCalories) > 0
        && intValue(targetDuration, minimum: 1, maximum: maxDurationSeconds) > 0
    case .none:
      return false
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 12) {
          Text(exercise.name)
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          Text(exercise.measurementBadge)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          targetForm
        }
        .padding(16)
      }
      .navigationTitle("Edit Targets")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        prefillTargets()
      }
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Back") {
            dismiss()
          }
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Update") {
            let sets = intValue(targetSets, minimum: 1, maximum: maxSets)
            let reps = intValue(targetReps, minimum: 0, maximum: maxReps)
            let durationSeconds = intValue(targetDuration, minimum: 0, maximum: maxDurationSeconds)
            let distance = backendDistance(from: floatValue(targetDistance, maximum: maxDistance))
            let calories = floatValue(targetCalories, maximum: maxCalories)
            let weight = backendWeight(from: floatValue(targetWeight, maximum: maxWeight))
            onUpdate(sets, reps, durationSeconds, distance, calories, weight)
            dismiss()
          }
          .disabled(!isFormValid)
        }
      }
    }
  }

  private var targetForm: some View {
    VStack(alignment: .leading, spacing: 12) {
      inputField(title: "Sets", text: $targetSets, placeholder: "3")

      switch exercise.measurementType {
      case .reps:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
      case .time:
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .repsAndTime:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .repsAndWeight:
        inputField(title: "Target Reps", text: $targetReps, placeholder: "10")
        inputField(
          title: "Target Weight (\(preferredWeightUnit.abbreviation))", text: $targetWeight,
          placeholder: "50", keyboard: .decimalPad
        )
      case .timeAndWeight:
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
        inputField(
          title: "Target Weight (\(preferredWeightUnit.abbreviation))", text: $targetWeight,
          placeholder: "50", keyboard: .decimalPad
        )
      case .distanceAndTime:
        inputField(
          title: "Target Distance (\(preferredDistanceUnit.abbreviation))", text: $targetDistance,
          placeholder: "1.0",
          keyboard: .decimalPad)
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .caloriesAndTime:
        inputField(
          title: "Target Calories", text: $targetCalories, placeholder: "200", keyboard: .decimalPad
        )
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
      case .none:
        EmptyView()
      }
    }
    .padding(12)
    .background(Color(.systemGray6))
    .cornerRadius(12)
  }

  private func inputField(
    title: String,
    text: Binding<String>,
    placeholder: String,
    keyboard: UIKeyboardType = .numberPad
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title.uppercased())
        .font(.system(size: 11, weight: .bold))
        .foregroundColor(.secondary)
      TextField(placeholder, text: text)
        .keyboardType(keyboard)
        .padding(12)
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
    }
  }

  private func prefillTargets() {
    targetSets = boundedIntString(exercise.targetSets, minimum: 1, maximum: maxSets)
    targetReps = boundedIntString(exercise.targetReps, minimum: 1, maximum: maxReps)
    targetDuration = boundedIntString(
      exercise.targetDurationSeconds,
      minimum: 1,
      maximum: maxDurationSeconds
    )
    targetDistance = ""
    targetCalories = ""
    targetWeight = ""

    if exercise.targetDistance > 0 {
      let displayValue =
        preferredDistanceUnit == .km
        ? exercise.targetDistance
        : UnitConverter.kmToMi(exercise.targetDistance)
      if displayValue > 0 && displayValue <= maxDistance {
        targetDistance = UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
      }
    }

    if exercise.targetCalories > 0 && exercise.targetCalories <= maxCalories {
      targetCalories = "\(Int(exercise.targetCalories))"
    }

    if exercise.targetWeight > 0 {
      let displayValue =
        preferredWeightUnit == .kg
        ? exercise.targetWeight
        : UnitConverter.kgToLb(exercise.targetWeight)
      if displayValue > 0 && displayValue <= maxWeight {
        targetWeight = UnitFormatter.formatValue(displayValue, decimalPlaces: 1)
      }
    }

    switch exercise.measurementType {
    case .reps:
      targetDuration = ""
      targetDistance = ""
      targetCalories = ""
      targetWeight = ""
    case .time:
      targetReps = ""
      targetDistance = ""
      targetCalories = ""
      targetWeight = ""
    case .repsAndTime:
      targetDistance = ""
      targetCalories = ""
      targetWeight = ""
    case .repsAndWeight:
      targetDuration = ""
      targetDistance = ""
      targetCalories = ""
    case .timeAndWeight:
      targetReps = ""
      targetDistance = ""
      targetCalories = ""
    case .distanceAndTime:
      targetReps = ""
      targetCalories = ""
      targetWeight = ""
    case .caloriesAndTime:
      targetReps = ""
      targetDistance = ""
      targetWeight = ""
    case .none:
      targetReps = ""
      targetDuration = ""
      targetDistance = ""
      targetCalories = ""
      targetWeight = ""
    }
  }

  private func intValue(_ text: String, minimum: Int = 0, maximum: Int) -> Int {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value = Int(trimmed), value >= minimum, value <= maximum else { return 0 }
    return value
  }

  private func boundedIntString(_ value: Int, minimum: Int, maximum: Int) -> String {
    guard value >= minimum && value <= maximum else { return "" }
    return "\(value)"
  }

  private func floatValue(_ text: String, maximum: Float) -> Float {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let value = Float(trimmed), value.isFinite, value >= 0, value <= maximum else {
      return 0
    }
    return value
  }

  private func backendWeight(from value: Float) -> Float {
    let kgValue = preferredWeightUnit == .kg ? value : UnitConverter.lbToKg(value)
    return UnitConverter.round(kgValue, decimalPlaces: 1)
  }

  private func backendDistance(from value: Float) -> Float {
    let kmValue = preferredDistanceUnit == .km ? value : UnitConverter.miToKm(value)
    return UnitConverter.round(kmValue, decimalPlaces: 1)
  }
}

extension MeasurementType {
  fileprivate var label: String {
    switch self {
    case .reps:
      return "Strength"
    case .repsAndTime:
      return "Paced"
    case .time:
      return "Timed"
    case .timeAndWeight:
      return "Timed + Weight"
    case .repsAndWeight:
      return "Strength + Weight"
    case .distanceAndTime:
      return "Distance"
    case .caloriesAndTime:
      return "Calories"
    }
  }
}

// MARK: - Column Configuration

private struct ExerciseColumn {
  let header: String
  let getValue: (EnrichedPlanExercise) -> String
}

extension EnrichedPlanExercise {
  fileprivate var measurementBadge: String {
    switch measurementType {
    case .reps, .repsAndWeight:
      return "Strength"
    case .repsAndTime:
      return "Paced"
    case .time, .timeAndWeight:
      return "Timed"
    case .distanceAndTime:
      return "Distance"
    case .caloriesAndTime:
      return "Calories"
    case .none:
      return "Routine"
    }
  }
}
