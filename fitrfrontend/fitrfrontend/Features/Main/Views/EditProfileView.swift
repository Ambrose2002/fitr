//
//  EditProfileView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/7/26.
//

import SwiftUI

struct EditProfileView: View {
  @Environment(\.dismiss) private var dismiss
  @StateObject private var viewModel: EditProfileViewModel

  init(sessionStore: SessionStore) {
    _viewModel = StateObject(wrappedValue: EditProfileViewModel(sessionStore: sessionStore))
  }

  var body: some View {
    ScrollView {
      VStack(spacing: 22) {
        if viewModel.isLoading {
          HStack(spacing: 10) {
            ProgressView()
              .controlSize(.small)
            Text("Refreshing profile details...")
              .font(.system(size: 13, weight: .medium))
              .foregroundStyle(AppColors.textSecondary)
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }

        accountSection
        physicalStatsSection
        trainingProfileSection
        unitPreferencesSection

        if let error = viewModel.errorMessage, !error.isEmpty {
          Text(error)
            .font(.system(size: 14, weight: .medium))
            .foregroundStyle(AppColors.errorRed)
            .multilineTextAlignment(.center)
            .frame(maxWidth: .infinity)
            .padding(.horizontal, 8)
        }

        Button {
          Task {
            let result = await viewModel.saveChanges()
            switch result {
            case .saved, .noChanges:
              dismiss()
            case .failed:
              break
            }
          }
        } label: {
          Text(viewModel.isSaving ? "Saving..." : "SAVE CHANGES")
            .font(.system(size: 16, weight: .semibold))
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 56)
            .background(AppColors.accent)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(viewModel.isSaving)
        .opacity(viewModel.isSaving ? 0.8 : 1)

        Text("Updates to your height and weight will affect BMI and TDEE calculations.")
          .font(.system(size: 12))
          .foregroundStyle(AppColors.textSecondary)
          .multilineTextAlignment(.center)
          .frame(maxWidth: .infinity)
          .padding(.top, 2)
      }
      .padding(.horizontal, 16)
      .padding(.top, 18)
      .padding(.bottom, 40)
    }
    .background(AppColors.background.ignoresSafeArea())
    .safeAreaInset(edge: .bottom) {
      Color.clear
        .frame(height: 100)
        .allowsHitTesting(false)
    }
    .navigationTitle("EDIT PROFILE")
    .navigationBarTitleDisplayMode(.inline)
    .task {
      await viewModel.loadLatestProfile()
    }
    .overlay {
      if viewModel.isSaving {
        ZStack {
          Color.black.opacity(0.2).ignoresSafeArea()
          ProgressView("Saving changes…")
            .padding(24)
            .background(.ultraThinMaterial)
            .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        }
      }
    }
  }

  private var accountSection: some View {
    sectionGroup(title: "ACCOUNT") {
      VStack(spacing: 12) {
        HStack(spacing: 12) {
          inputField(
            title: "FIRST NAME",
            text: $viewModel.firstName,
            keyboardType: .default,
            textInputAutocapitalization: .words
          )
          inputField(
            title: "LAST NAME",
            text: $viewModel.lastName,
            keyboardType: .default,
            textInputAutocapitalization: .words
          )
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("EMAIL")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
            .tracking(0.4)

          Text(viewModel.email.isEmpty ? "No email on file" : viewModel.email)
            .font(.system(size: 15, weight: .medium))
            .foregroundStyle(AppColors.textPrimary)
            .frame(maxWidth: .infinity, alignment: .leading)
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
      }
    }
  }

  private var physicalStatsSection: some View {
    sectionGroup(title: "PHYSICAL STATS") {
      VStack(alignment: .leading, spacing: 12) {
        HStack(spacing: 12) {
          VStack(alignment: .leading, spacing: 6) {
            Text("HEIGHT")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(AppColors.textSecondary)
              .tracking(0.4)

            HStack(spacing: 8) {
              TextField("180", value: $viewModel.height, format: .number)
                .font(.system(size: 16, weight: .semibold))
                .keyboardType(.decimalPad)
                .foregroundStyle(AppColors.textPrimary)

              Text("CM")
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          }

          VStack(alignment: .leading, spacing: 6) {
            Text("WEIGHT")
              .font(.system(size: 11, weight: .semibold))
              .foregroundStyle(AppColors.textSecondary)
              .tracking(0.4)

            HStack(spacing: 8) {
              TextField("75", value: $viewModel.weight, format: .number)
                .font(.system(size: 16, weight: .semibold))
                .keyboardType(.decimalPad)
                .foregroundStyle(AppColors.textPrimary)

              Text(viewModel.selectedWeightUnit.abbreviation)
                .font(.system(size: 12, weight: .semibold))
                .foregroundStyle(AppColors.textSecondary)
            }
            .padding(.horizontal, 12)
            .frame(height: 48)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
          }
        }

        Text("GENDER")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary.opacity(0.9))
          .tracking(0.4)

        HStack(spacing: 10) {
          genderCard(for: .male)
          genderCard(for: .female)
          genderCard(for: .other)
        }
      }
    }
  }

  private var trainingProfileSection: some View {
    sectionGroup(title: "TRAINING PROFILE") {
      VStack(alignment: .leading, spacing: 12) {
        Text("EXPERIENCE LEVEL")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary.opacity(0.9))
          .tracking(0.4)

        VStack(spacing: 10) {
          experienceCard(for: .beginner)
          experienceCard(for: .intermediate)
          experienceCard(for: .advanced)
        }

        Text("FITNESS GOAL")
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary.opacity(0.9))
          .tracking(0.4)
          .padding(.top, 4)

        VStack(spacing: 10) {
          goalCard(for: .strength)
          goalCard(for: .hypertrophy)
          goalCard(for: .fatLoss)
          goalCard(for: .general)
        }
      }
    }
  }

  private var unitPreferencesSection: some View {
    sectionGroup(title: "UNIT PREFERENCES") {
      VStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 6) {
          Text("WEIGHT UNIT")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
            .tracking(0.4)

          Picker("Weight Unit", selection: $viewModel.selectedWeightUnit) {
            ForEach(WeightUnit.allCases) { unit in
              Text(unit.abbreviation).tag(unit)
            }
          }
          .pickerStyle(.segmented)
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("DISTANCE UNIT")
            .font(.system(size: 11, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
            .tracking(0.4)

          Picker("Distance Unit", selection: $viewModel.selectedDistanceUnit) {
            ForEach(DistanceUnit.allCases) { unit in
              Text(unit.abbreviation).tag(unit)
            }
          }
          .pickerStyle(.segmented)
        }
      }
    }
  }

  @ViewBuilder
  private func sectionGroup<Content: View>(
    title: String,
    @ViewBuilder content: () -> Content
  ) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(AppColors.textPrimary.opacity(0.88))
        .tracking(1)

      content()
        .padding(.horizontal, 14)
        .padding(.vertical, 14)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 16, style: .continuous)
            .stroke(AppColors.borderGray, lineWidth: 1)
        )
    }
  }

  @ViewBuilder
  private func inputField(
    title: String,
    text: Binding<String>,
    keyboardType: UIKeyboardType,
    textInputAutocapitalization: TextInputAutocapitalization?
  ) -> some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)
        .tracking(0.4)

      TextField("", text: text)
        .font(.system(size: 15, weight: .medium))
        .keyboardType(keyboardType)
        .textInputAutocapitalization(textInputAutocapitalization)
        .autocorrectionDisabled()
        .foregroundStyle(AppColors.textPrimary)
        .padding(.horizontal, 12)
        .frame(height: 46)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    }
    .frame(maxWidth: .infinity, alignment: .leading)
  }

  @ViewBuilder
  private func genderCard(for gender: Gender) -> some View {
    let isSelected = viewModel.selectedGender == gender
    Button {
      viewModel.selectedGender = gender
    } label: {
      Text(gender.representation)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(isSelected ? .white : AppColors.textPrimary)
        .frame(maxWidth: .infinity)
        .frame(height: 40)
        .background(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .fill(isSelected ? AppColors.accent : Color(.systemGray6))
        )
        .overlay(
          RoundedRectangle(cornerRadius: 10, style: .continuous)
            .stroke(isSelected ? AppColors.accent : AppColors.borderGray, lineWidth: 1)
        )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func experienceCard(for experience: ExperienceLevel) -> some View {
    let isSelected = viewModel.selectedExperience == experience
    Button {
      viewModel.selectedExperience = experience
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(experience.representation)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
          Text(experience.description)
            .font(.system(size: 12))
            .foregroundStyle(AppColors.textSecondary)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(AppColors.accent)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(isSelected ? AppColors.accent.opacity(0.16) : Color(.systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(isSelected ? AppColors.accent : AppColors.borderGray, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }

  @ViewBuilder
  private func goalCard(for goal: Goal) -> some View {
    let isSelected = viewModel.selectedGoal == goal
    Button {
      viewModel.selectedGoal = goal
    } label: {
      HStack(spacing: 12) {
        VStack(alignment: .leading, spacing: 2) {
          Text(goal.representation)
            .font(.system(size: 15, weight: .bold))
            .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
          Text(goal.description)
            .font(.system(size: 12))
            .foregroundStyle(AppColors.textSecondary)
        }

        Spacer()

        if isSelected {
          Image(systemName: "checkmark.circle.fill")
            .font(.system(size: 20, weight: .semibold))
            .foregroundStyle(AppColors.accent)
        }
      }
      .padding(.horizontal, 14)
      .padding(.vertical, 14)
      .frame(maxWidth: .infinity, alignment: .leading)
      .background(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .fill(isSelected ? AppColors.accent.opacity(0.16) : Color(.systemBackground))
      )
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(isSelected ? AppColors.accent : AppColors.borderGray, lineWidth: 1)
      )
    }
    .buttonStyle(.plain)
  }
}
