//
//  PlanDayDetailView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/25/26.
//

import SwiftUI

struct PlanDayDetailView: View {
  @Environment(\.dismiss) private var dismiss

  @StateObject private var viewModel: PlanDayDetailViewModel
  let planName: String

  init(planId: Int64, dayId: Int64, dayName: String, planName: String) {
    _viewModel = StateObject(
      wrappedValue: PlanDayDetailViewModel(
        planId: planId,
        dayId: dayId,
        dayName: dayName
      ))
    self.planName = planName
  }

  private var estimatedMinutesText: String {
    if viewModel.durationMinutes > 0 {
      return "\(viewModel.durationMinutes) min"
    }

    let fallbackMinutes = max(
      viewModel.exerciseCount * 6,
      viewModel.exercises.reduce(0) { $0 + max($1.targetSets, 1) * 2 }
    )
    return "\(fallbackMinutes) min"
  }

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text(viewModel.dayName)
              .font(.system(size: 38, weight: .black))
              .foregroundColor(AppColors.textPrimary)

            Text("Part of the \"\(planName)\" plan.")
              .font(.system(size: 17))
              .foregroundColor(.secondary)
          }

          HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
              Label {
                Text("EST. TIME")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "clock")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text(estimatedMinutesText)
                .font(.system(size: 33, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
              .frame(height: 70)
              .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
              Label {
                Text("EXERCISES")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "flame")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text("\(viewModel.exerciseCount)")
                .font(.system(size: 33, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
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
                PlanDayExerciseCard(exercise: exercise) {
                  viewModel.requestRemove(exercise)
                }
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
            dismiss()
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
            .font(.system(size: 30, weight: .black))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.leading, 20)
          Spacer()
        }
        .frame(height: 64)
        .background(AppColors.accent)
        .cornerRadius(16)
        .overlay(alignment: .trailing) {
          Circle()
            .fill(AppColors.accent)
            .frame(width: 52, height: 52)
            .shadow(color: AppColors.accent.opacity(0.35), radius: 6, x: 0, y: 4)
            .overlay {
              Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            }
            .padding(.trailing, 8)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .padding(.bottom, 60)
      .background(Color(.systemBackground))
    }
    .task {
      await viewModel.load()
    }
    .onChange(of: viewModel.shouldDismiss) { shouldDismiss in
      if shouldDismiss {
        dismiss()
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
        exercises: viewModel.availableExercises
      ) { exercise, targets in
        await viewModel.addExercise(exercise: exercise, targets: targets)
      }
    }
  }
}

struct PlanDayExerciseCard: View {
  let exercise: EnrichedPlanExercise
  let onRemove: () -> Void

  private var setCount: Int {
    max(exercise.targetSets, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          Text(exercise.measurementBadge)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          Text(exercise.name)
            .font(.system(size: 33, weight: .black))
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(2)
        }

        Spacer()

        Menu {
          Button(role: .destructive) {
            onRemove()
          } label: {
            Label("Remove from day", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 24, height: 24)
        }
      }

      VStack(spacing: 0) {
        // Dynamic table header
        HStack(spacing: 8) {
          Text("SET")
            .font(.system(size: 12, weight: .bold))
            .foregroundColor(.secondary)
            .frame(width: 50, alignment: .leading)

          ForEach(Array(exercise.columns.enumerated()), id: \.offset) { _, column in
            Text(column.header)
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(.secondary)
              .frame(maxWidth: .infinity, alignment: .center)
          }
        }
        .padding(.horizontal, 12)
        .padding(.bottom, 8)

        VStack(spacing: 0) {
          ForEach(1...setCount, id: \.self) { setIndex in
            HStack(spacing: 8) {
              Text("\(setIndex)")
                .font(.system(size: 22, weight: .medium))
                .foregroundColor(AppColors.textPrimary)
                .frame(width: 50, alignment: .leading)

              ForEach(Array(exercise.columns.enumerated()), id: \.offset) { index, column in
                Text(column.getValue(exercise))
                  .font(.system(size: 22, weight: .bold))
                  .foregroundColor(index == 0 ? AppColors.textPrimary : AppColors.accent)
                  .frame(maxWidth: .infinity, alignment: .center)
              }
            }
            .frame(height: 50)
            .padding(.horizontal, 12)

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
    }
    .padding(14)
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
  let onAdd: (ExerciseResponse, PlanExerciseTargets) async -> Void

  @State private var searchText = ""
  @State private var selectedExercise: ExerciseResponse?
  @State private var targetSets = ""
  @State private var targetReps = ""
  @State private var targetDuration = ""
  @State private var targetDistance = ""
  @State private var targetCalories = ""
  @State private var targetWeight = ""

  private var filteredExercises: [ExerciseResponse] {
    let trimmed = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    if trimmed.isEmpty {
      return exercises.sorted { $0.name < $1.name }
    }
    return exercises.filter { $0.name.localizedCaseInsensitiveContains(trimmed) }
      .sorted { $0.name < $1.name }
  }

  private var isFormValid: Bool {
    guard let exercise = selectedExercise else { return false }
    let sets = intValue(targetSets)
    if sets <= 0 { return false }

    switch exercise.measurementType {
    case .reps:
      return intValue(targetReps) > 0
    case .time:
      return intValue(targetDuration) > 0
    case .repsAndTime:
      return intValue(targetReps) > 0 && intValue(targetDuration) > 0
    case .repsAndWeight:
      return intValue(targetReps) > 0 && floatValue(targetWeight) > 0
    case .timeAndWeight:
      return intValue(targetDuration) > 0 && floatValue(targetWeight) > 0
    case .distanceAndTime:
      return floatValue(targetDistance) > 0 && intValue(targetDuration) > 0
    case .caloriesAndTime:
      return floatValue(targetCalories) > 0 && intValue(targetDuration) > 0
    }
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          Text("Choose Exercise")
            .font(.system(size: 22, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          searchField

          VStack(spacing: 8) {
            ForEach(filteredExercises) { exercise in
              exerciseRow(exercise)
            }
          }

          if let exercise = selectedExercise {
            targetForm(for: exercise)
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
            guard let exercise = selectedExercise else { return }
            let targets = PlanExerciseTargets(
              sets: intValue(targetSets),
              reps: intValue(targetReps),
              durationSeconds: intValue(targetDuration),
              distance: floatValue(targetDistance),
              calories: floatValue(targetCalories),
              weight: floatValue(targetWeight)
            )
            Task {
              await onAdd(exercise, targets)
              dismiss()
            }
          }
          .disabled(!isFormValid)
        }
      }
    }
    .presentationDetents([.medium, .large])
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

    return Button {
      selectedExercise = exercise
      resetTargets(for: exercise)
    } label: {
      HStack {
        VStack(alignment: .leading, spacing: 6) {
          Text(exercise.name)
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)

          Text(exercise.measurementType.label)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .foregroundColor(AppColors.accent)
        }
      }
      .padding(12)
      .background(isSelected ? AppColors.accent.opacity(0.08) : Color(.systemBackground))
      .overlay(
        RoundedRectangle(cornerRadius: 12)
          .stroke(Color(.systemGray4), lineWidth: 1)
      )
      .cornerRadius(12)
    }
    .buttonStyle(.plain)
  }

  private func targetForm(for exercise: ExerciseResponse) -> some View {
    VStack(alignment: .leading, spacing: 12) {
      Text("Targets")
        .font(.system(size: 18, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

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
          title: "Target Weight (kg)", text: $targetWeight, placeholder: "50", keyboard: .decimalPad
        )
      case .timeAndWeight:
        inputField(title: "Target Duration (sec)", text: $targetDuration, placeholder: "60")
        inputField(
          title: "Target Weight (kg)", text: $targetWeight, placeholder: "50", keyboard: .decimalPad
        )
      case .distanceAndTime:
        inputField(
          title: "Target Distance (m)", text: $targetDistance, placeholder: "100",
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

  private func resetTargets(for exercise: ExerciseResponse) {
    targetSets = ""
    targetReps = ""
    targetDuration = ""
    targetDistance = ""
    targetCalories = ""
    targetWeight = ""
  }

  private func intValue(_ text: String) -> Int {
    Int(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
  }

  private func floatValue(_ text: String) -> Float {
    Float(text.trimmingCharacters(in: .whitespacesAndNewlines)) ?? 0
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
  fileprivate var columns: [ExerciseColumn] {
    switch measurementType {
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
        ExerciseColumn(header: "WEIGHT (kg)") {
          "\($0.targetWeight > 0 ? String(format: "%.1f", $0.targetWeight) : "--")"
        },
      ]

    case .repsAndWeight:
      return [
        ExerciseColumn(header: "REPS") { "\($0.targetReps > 0 ? "\($0.targetReps)" : "--")" },
        ExerciseColumn(header: "WEIGHT (kg)") {
          "\($0.targetWeight > 0 ? String(format: "%.1f", $0.targetWeight) : "--")"
        },
      ]

    case .distanceAndTime:
      return [
        ExerciseColumn(header: "DISTANCE (m)") {
          "\($0.targetDistance > 0 ? "\(Int($0.targetDistance))" : "--")"
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
