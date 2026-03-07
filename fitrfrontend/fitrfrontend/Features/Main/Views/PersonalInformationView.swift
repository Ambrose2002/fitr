//
//  PersonalInformationView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/7/26.
//

import SwiftUI

struct PersonalInformationView: View {
  @ObservedObject var viewModel: ProfileViewModel

  private static let createdAtFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.dateStyle = .medium
    formatter.timeStyle = .short
    return formatter
  }()

  var body: some View {
    ScrollView {
      VStack(spacing: 20) {
        if let profile = viewModel.profile {
          sectionGroup(
            title: "BASIC DETAILS",
            items: [
              .init(id: "firstName", label: "First Name", value: sanitized(profile.firstname)),
              .init(id: "lastName", label: "Last Name", value: sanitized(profile.lastname)),
              .init(id: "email", label: "Email", value: sanitized(profile.email)),
            ]
          )

          sectionGroup(
            title: "FITNESS PROFILE",
            items: [
              .init(id: "gender", label: "Gender", value: profile.gender.representation),
              .init(id: "experience", label: "Experience", value: profile.experience.representation),
              .init(id: "goal", label: "Goal", value: profile.goal.representation),
              .init(id: "height", label: "Height", value: UnitFormatter.formatHeight(profile.height)),
              .init(
                id: "weight",
                label: "Weight",
                value: UnitFormatter.formatWeight(
                  profile.weight,
                  preferredUnit: profile.preferredWeightUnit
                )
              ),
            ]
          )

          sectionGroup(
            title: "UNIT PREFERENCES",
            items: [
              .init(id: "weightUnit", label: "Weight Unit", value: profile.preferredWeightUnit.rawValue),
              .init(
                id: "distanceUnit",
                label: "Distance Unit",
                value: profile.preferredDistanceUnit.rawValue
              ),
            ]
          )

          sectionGroup(
            title: "PROFILE",
            items: [
              .init(
                id: "createdAt",
                label: "Created",
                value: Self.createdAtFormatter.string(from: profile.createdAt)
              )
            ]
          )
        } else {
          sectionGroup(
            title: "PERSONAL INFORMATION",
            items: [
              .init(
                id: "status",
                label: "Status",
                value: "Profile details are unavailable right now."
              )
            ]
          )
        }
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
    .task {
      await viewModel.load(forceRefresh: true)
    }
    .navigationTitle("PERSONAL INFO")
    .navigationBarTitleDisplayMode(.inline)
  }

  private func sanitized(_ text: String) -> String {
    let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
    return trimmed.isEmpty ? "Not provided" : trimmed
  }

  @ViewBuilder
  private func sectionGroup(title: String, items: [PersonalInfoItem]) -> some View {
    VStack(alignment: .leading, spacing: 10) {
      Text(title)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(AppColors.textPrimary.opacity(0.88))
        .tracking(1)

      VStack(spacing: 0) {
        ForEach(Array(items.enumerated()), id: \.element.id) { index, item in
          infoRow(label: item.label, value: item.value)

          if index < items.count - 1 {
            Divider()
              .padding(.leading, 16)
          }
        }
      }
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
    }
  }

  @ViewBuilder
  private func infoRow(label: String, value: String) -> some View {
    VStack(alignment: .leading, spacing: 4) {
      Text(label)
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)
        .tracking(0.4)

      Text(value)
        .font(.system(size: 16, weight: .medium))
        .foregroundStyle(AppColors.textPrimary)
        .multilineTextAlignment(.leading)
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 12)
  }
}

private struct PersonalInfoItem: Identifiable {
  let id: String
  let label: String
  let value: String
}
