//
//  WorkoutSessionEditSheet.swift
//  fitrfrontend
//
//  Created by Codex on 3/2/26.
//

import SwiftUI

struct WorkoutSessionEditDraft: Equatable {
  var title: String
  var notes: String
  var selectedLocationId: Int64?

  init(
    title: String = "",
    notes: String = "",
    selectedLocationId: Int64? = nil
  ) {
    self.title = title
    self.notes = notes
    self.selectedLocationId = selectedLocationId
  }

  init(workout: WorkoutSessionResponse) {
    let trimmedTitle = workout.title?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""

    self.init(
      title: trimmedTitle.isEmpty ? "Workout" : trimmedTitle,
      notes: workout.notes ?? "",
      selectedLocationId: workout.workoutLocationId
    )
  }

  var trimmedTitle: String {
    title.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  var trimmedNotes: String {
    notes.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  func hasChanges(comparedTo other: WorkoutSessionEditDraft) -> Bool {
    normalizedForComparison != other.normalizedForComparison
  }

  private var normalizedForComparison: WorkoutSessionEditDraft {
    WorkoutSessionEditDraft(
      title: trimmedTitle,
      notes: trimmedNotes,
      selectedLocationId: selectedLocationId
    )
  }
}

struct WorkoutSessionEditSheet: View {
  @Binding var draft: WorkoutSessionEditDraft

  let initialDraft: WorkoutSessionEditDraft
  let availableLocations: [LocationResponse]
  let isLoadingLocations: Bool
  let isSaving: Bool
  let locationLoadErrorMessage: String?
  let saveErrorMessage: String?
  let onCancel: () -> Void
  let onSave: () -> Void

  private var isSaveDisabled: Bool {
    isSaving || draft.trimmedTitle.isEmpty || !draft.hasChanges(comparedTo: initialDraft)
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(alignment: .leading, spacing: 18) {
          Text("Edit Session")
            .font(.system(size: 24, weight: .black))
            .foregroundColor(AppColors.textPrimary)

          if let saveErrorMessage {
            inlineMessage(
              message: saveErrorMessage,
              tint: AppColors.errorRed
            )
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Workout Title")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            TextField("Workout Title", text: $draft.title)
              .textInputAutocapitalization(.words)
              .disabled(isSaving)
              .padding(12)
              .background(Color(.systemGray6))
              .cornerRadius(12)
          }

          VStack(alignment: .leading, spacing: 8) {
            Text("Notes")
              .font(.system(size: 13, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            TextEditor(text: $draft.notes)
              .disabled(isSaving)
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
                ForEach(availableLocations) { location in
                  Button {
                    guard !isSaving else {
                      return
                    }

                    draft.selectedLocationId = location.id
                  } label: {
                    HStack(spacing: 12) {
                      Image(systemName: draft.selectedLocationId == location.id
                        ? "largecircle.fill.circle"
                        : "circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(
                          draft.selectedLocationId == location.id
                            ? AppColors.accent
                            : AppColors.textSecondary
                        )

                      VStack(alignment: .leading, spacing: 4) {
                        Text(location.name)
                          .font(.system(size: 15, weight: .semibold))
                          .foregroundColor(AppColors.textPrimary)

                        if !location.address.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                          Text(location.address)
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
                        .stroke(
                          draft.selectedLocationId == location.id
                            ? AppColors.accent
                            : Color(.systemGray4),
                          lineWidth: 1
                        )
                    )
                    .cornerRadius(12)
                  }
                  .buttonStyle(.plain)
                  .disabled(isSaving)
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
            onCancel()
          }
          .disabled(isSaving)
        }
        ToolbarItem(placement: .confirmationAction) {
          Button("Save") {
            onSave()
          }
          .disabled(isSaveDisabled)
        }
      }
    }
    .presentationDetents([.medium, .large])
    .presentationDragIndicator(.visible)
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
}
