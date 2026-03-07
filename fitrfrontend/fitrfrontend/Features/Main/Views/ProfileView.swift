//
//  ProfileView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import SwiftUI

struct ProfileView: View {
  @StateObject private var viewModel: ProfileViewModel
  private let sessionStore: SessionStore

  init(sessionStore: SessionStore) {
    self.sessionStore = sessionStore
    _viewModel = StateObject(wrappedValue: ProfileViewModel(sessionStore: sessionStore))
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 0) {
          headerSection
          settingsSection
          footerSection
        }
      }
      .background(AppColors.background.ignoresSafeArea())
      .safeAreaInset(edge: .bottom) {
        Color.clear
          .frame(height: 100)
          .allowsHitTesting(false)
      }
      .navigationTitle("PROFILE")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          NavigationLink {
            EditProfileView(sessionStore: sessionStore)
          } label: {
            Text("EDIT")
              .font(.system(size: 16, weight: .semibold))
              .foregroundStyle(AppColors.accent)
          }
        }
      }
      .task {
        await viewModel.load()
      }
      .refreshable {
        await viewModel.load(forceRefresh: true)
      }
    }
  }

  private var headerSection: some View {
    VStack(spacing: 12) {
      ZStack {
        Circle()
          .fill(AppColors.accent.opacity(0.18))
          .frame(width: 88, height: 88)

        Image(systemName: "person.fill")
          .font(.system(size: 38, weight: .semibold))
          .foregroundStyle(AppColors.accentStrong)
      }

      Text(viewModel.displayName)
        .font(.system(size: 34, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)
        .multilineTextAlignment(.center)

      Text(viewModel.email)
        .font(.system(size: 16))
        .foregroundStyle(AppColors.textSecondary)
        .multilineTextAlignment(.center)

      HStack(spacing: 12) {
        statCard(title: "WORKOUTS", value: viewModel.headerStats.workoutsCount)
        statCard(title: "STREAK", value: viewModel.headerStats.streakWeeks)
      }
      .padding(.top, 6)

      if viewModel.isLoading {
        ProgressView()
          .controlSize(.small)
          .padding(.top, 2)
      }

      if let errorMessage = viewModel.errorMessage {
        Text(errorMessage)
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(AppColors.errorRed)
          .multilineTextAlignment(.center)
          .padding(.top, 2)
      }
    }
    .padding(.horizontal, 16)
    .padding(.top, 26)
    .padding(.bottom, 20)
    .frame(maxWidth: .infinity)
    .background(AppColors.accent.opacity(0.12))
  }

  @ViewBuilder
  private func statCard(title: String, value: String) -> some View {
    VStack(spacing: 6) {
      Text(title)
        .font(.system(size: 11, weight: .semibold))
        .foregroundStyle(AppColors.textPrimary.opacity(0.8))
        .tracking(0.7)

      Text(value)
        .font(.system(size: 26, weight: .bold))
        .foregroundStyle(AppColors.accentStrong)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 14)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
  }

  private var settingsSection: some View {
    VStack(spacing: 24) {
      sectionGroup(title: "ACCOUNT SETTINGS") {
        ProfileSettingsNavigationRow(
          iconName: "person.crop.circle",
          iconTint: AppColors.accent,
          title: "Personal Information",
          subtitle: viewModel.rowSubtitles.personalInfo
        ) {
          PersonalInformationView(viewModel: viewModel)
        }

        Divider()
          .padding(.leading, 64)

        ProfileSettingsNavigationRow(
          iconName: "mappin.circle",
          iconTint: AppColors.accent,
          title: "Gym Locations",
          subtitle: viewModel.rowSubtitles.locations
        ) {
          GymLocationsView()
        }
      }

      sectionGroup(title: "PREFERENCES") {
        ProfileSettingsStaticRow(
          iconName: "slider.horizontal.3",
          iconTint: AppColors.accent,
          title: "Units & Preferences",
          subtitle: viewModel.rowSubtitles.units
        )
      }

      sectionGroup(title: "SYSTEM") {
        ProfileSettingsStaticRow(
          iconName: "iphone",
          iconTint: AppColors.accent,
          title: "App Version",
          subtitle: viewModel.rowSubtitles.appVersion
        )
      }

      ProfileSettingsRow(
        iconName: "rectangle.portrait.and.arrow.right",
        iconTint: AppColors.errorRed,
        title: "Log Out",
        subtitle: nil,
        isDestructive: true
      ) {
        viewModel.logout()
      }
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
    }
    .padding(.horizontal, 16)
    .padding(.top, 24)
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

      VStack(spacing: 0) {
        content()
      }
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
    }
  }

  private var footerSection: some View {
    VStack(spacing: 6) {
      Text("DEVELOPED BY AMBROSE BLAY")
        .font(.system(size: 12, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)
        .tracking(1)

      Text("© 2026 ALL RIGHTS RESERVED")
        .font(.system(size: 11))
        .foregroundStyle(AppColors.textSecondary.opacity(0.8))
        .tracking(0.7)
    }
    .frame(maxWidth: .infinity)
    .padding(.top, 44)
    .padding(.bottom, 50)
  }
}

private struct ProfileSettingsNavigationRow<Destination: View>: View {
  let iconName: String
  let iconTint: Color
  let title: String
  let subtitle: String?
  let destination: Destination

  init(
    iconName: String,
    iconTint: Color,
    title: String,
    subtitle: String?,
    @ViewBuilder destination: () -> Destination
  ) {
    self.iconName = iconName
    self.iconTint = iconTint
    self.title = title
    self.subtitle = subtitle
    self.destination = destination()
  }

  var body: some View {
    NavigationLink {
      destination
    } label: {
      ProfileSettingsRowContent(
        iconName: iconName,
        iconTint: iconTint,
        title: title,
        subtitle: subtitle,
        isDestructive: false,
        showsChevron: true
      )
    }
    .buttonStyle(.plain)
  }
}

private struct ProfileSettingsRow: View {
  let iconName: String
  let iconTint: Color
  let title: String
  let subtitle: String?
  var isDestructive: Bool = false
  var showsChevron: Bool = true
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      ProfileSettingsRowContent(
        iconName: iconName,
        iconTint: iconTint,
        title: title,
        subtitle: subtitle,
        isDestructive: isDestructive,
        showsChevron: showsChevron
      )
    }
    .buttonStyle(.plain)
  }
}

private struct ProfileSettingsStaticRow: View {
  let iconName: String
  let iconTint: Color
  let title: String
  let subtitle: String?
  var isDestructive: Bool = false

  var body: some View {
    ProfileSettingsRowContent(
      iconName: iconName,
      iconTint: iconTint,
      title: title,
      subtitle: subtitle,
      isDestructive: isDestructive,
      showsChevron: false
    )
  }
}

private struct ProfileSettingsRowContent: View {
  let iconName: String
  let iconTint: Color
  let title: String
  let subtitle: String?
  let isDestructive: Bool
  let showsChevron: Bool

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: iconName)
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(iconTint)
        .frame(width: 38, height: 38)
        .background(iconTint.opacity(0.12))
        .clipShape(RoundedRectangle(cornerRadius: 11, style: .continuous))

      VStack(alignment: .leading, spacing: 2) {
        Text(title)
          .font(.system(size: 17, weight: .semibold))
          .foregroundStyle(isDestructive ? AppColors.errorRed : AppColors.textPrimary)

        if let subtitle, !subtitle.isEmpty {
          Text(subtitle)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(2)
        }
      }

      Spacer()

      if showsChevron {
        Image(systemName: "chevron.right")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(Color(.systemGray3))
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
    .contentShape(Rectangle())
  }
}

//#Preview {
//  ProfileView(sessionStore: MockData.mockSessionStore())
//}
