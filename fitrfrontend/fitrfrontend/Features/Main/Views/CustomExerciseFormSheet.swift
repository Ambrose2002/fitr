//
//  CustomExerciseFormSheet.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 4/11/26.
//

import SwiftUI

enum CustomExerciseFormMode {
  case create
  case edit

  var title: String {
    switch self {
    case .create:
      return "Create Exercise"
    case .edit:
      return "Edit Exercise"
    }
  }

  var saveButtonTitle: String {
    switch self {
    case .create:
      return "Create"
    case .edit:
      return "Save"
    }
  }

  var fallbackErrorMessage: String {
    switch self {
    case .create:
      return "Couldn't create the exercise."
    case .edit:
      return "Couldn't save the exercise."
    }
  }
}

struct CustomExerciseFormSheet: View {
  @Environment(\.dismiss) private var dismiss

  let mode: CustomExerciseFormMode
  let initialName: String
  let initialMeasurementType: MeasurementType
  let onSubmit: @MainActor (String, MeasurementType) async throws -> ExerciseResponse
  let onComplete: @MainActor (ExerciseResponse) -> Void

  @State private var name: String
  @State private var measurementType: MeasurementType
  @State private var isSubmitting = false
  @State private var errorMessage: String?

  init(
    mode: CustomExerciseFormMode,
    initialName: String = "",
    initialMeasurementType: MeasurementType = .reps,
    onSubmit: @escaping @MainActor (String, MeasurementType) async throws -> ExerciseResponse,
    onComplete: @escaping @MainActor (ExerciseResponse) -> Void = { _ in }
  ) {
    self.mode = mode
    self.initialName = initialName
    self.initialMeasurementType = initialMeasurementType
    self.onSubmit = onSubmit
    self.onComplete = onComplete
    _name = State(initialValue: initialName)
    _measurementType = State(initialValue: initialMeasurementType)
  }

  private var trimmedName: String {
    name.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var hasChanges: Bool {
    let initialTrimmedName = initialName.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmedName != initialTrimmedName || measurementType != initialMeasurementType
  }

  private var canSubmit: Bool {
    guard !isSubmitting, !trimmedName.isEmpty else {
      return false
    }
    if mode == .edit {
      return hasChanges
    }
    return true
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text(mode.title)
            .font(.system(size: 24, weight: .black))
            .foregroundColor(AppColors.textPrimary)

          VStack(alignment: .leading, spacing: 8) {
            Text("Exercise Name")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            TextField("e.g., Cable Lateral Raise", text: $name)
              .textInputAutocapitalization(.words)
              .autocorrectionDisabled()
              .disabled(isSubmitting)
              .padding(12)
              .background(Color(.systemGray6))
              .cornerRadius(12)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Tracking Type")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            Picker("Tracking Type", selection: $measurementType) {
              ForEach(MeasurementType.allCases, id: \.self) { type in
                Text(type.customExerciseFormLabel).tag(type)
              }
            }
            .pickerStyle(.menu)
            .disabled(isSubmitting)
            .padding(12)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(Color(.systemGray6))
            .cornerRadius(12)
          }

          if let errorMessage, !errorMessage.isEmpty {
            HStack(spacing: 8) {
              Image(systemName: "exclamationmark.circle.fill")
                .font(.system(size: 13, weight: .semibold))
                .foregroundColor(AppColors.errorRed)
              Text(errorMessage)
                .font(.system(size: 13, weight: .medium))
                .foregroundColor(AppColors.errorRed)
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
          Button(isSubmitting ? "Saving..." : mode.saveButtonTitle) {
            Task {
              await submit()
            }
          }
          .disabled(!canSubmit)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
    .onChange(of: name) { _, _ in
      if errorMessage != nil {
        errorMessage = nil
      }
    }
    .onChange(of: measurementType) { _, _ in
      if errorMessage != nil {
        errorMessage = nil
      }
    }
  }

  @MainActor
  private func submit() async {
    guard canSubmit else {
      if trimmedName.isEmpty {
        errorMessage = "Exercise name is required."
      }
      return
    }

    isSubmitting = true
    errorMessage = nil

    defer {
      isSubmitting = false
    }

    do {
      let exercise = try await onSubmit(trimmedName, measurementType)
      onComplete(exercise)
      dismiss()
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = mode.fallbackErrorMessage
    }
  }
}
