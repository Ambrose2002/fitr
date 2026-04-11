//
//  ExerciseLibraryView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 4/11/26.
//

import SwiftUI

struct ExerciseLibraryView: View {
  @StateObject private var viewModel: ExerciseLibraryViewModel
  @State private var showCreateExerciseSheet = false
  @State private var editingExercise: ExerciseResponse?

  init(
    sessionStore: SessionStore,
    viewModel: ExerciseLibraryViewModel? = nil
  ) {
    _viewModel = StateObject(
      wrappedValue: viewModel ?? ExerciseLibraryViewModel(sessionStore: sessionStore)
    )
  }

  var body: some View {
    List {
      Section {
        searchField
      }

      if let errorMessage = viewModel.errorMessage {
        Section {
          inlineErrorRow(message: errorMessage)
        }
      }

      Section {
        exerciseRows
      } header: {
        Text("EXERCISES (\(viewModel.exercises.count))")
          .font(.system(size: 13, weight: .black))
          .foregroundStyle(AppColors.textSecondary)
          .tracking(1)
      } footer: {
        Text("System exercises are read-only. You can edit your custom exercises.")
          .font(.system(size: 12, weight: .medium))
          .foregroundStyle(AppColors.textSecondary)
      }
    }
    .listStyle(.plain)
    .scrollContentBackground(.hidden)
    .background(AppColors.background.ignoresSafeArea())
    .navigationTitle("EXERCISE LIBRARY")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          showCreateExerciseSheet = true
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .bold))
        }
      }
    }
    .task {
      await viewModel.load()
    }
    .refreshable {
      await viewModel.load(forceRefresh: true)
    }
    .sheet(isPresented: $showCreateExerciseSheet) {
      CustomExerciseFormSheet(mode: .create) { name, measurementType in
        try await viewModel.createCustomExercise(name: name, measurementType: measurementType)
      }
    }
    .sheet(item: $editingExercise) { exercise in
      CustomExerciseFormSheet(
        mode: .edit,
        initialName: exercise.name,
        initialMeasurementType: exercise.measurementType
      ) { name, measurementType in
        try await viewModel.updateCustomExercise(
          exerciseId: exercise.id,
          name: name,
          measurementType: measurementType
        )
      }
    }
  }

  @ViewBuilder
  private var exerciseRows: some View {
    if viewModel.isLoading && viewModel.exercises.isEmpty {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)
        Text("Loading exercises...")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(AppColors.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
    } else if viewModel.isRefreshing {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)
        Text("Refreshing exercises...")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(AppColors.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
      .listRowBackground(Color.clear)
      .listRowSeparator(.hidden)
    } else if viewModel.exercises.isEmpty {
      Text("No exercises yet. Create one to personalize your routine.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    } else if viewModel.filteredExercises.isEmpty {
      Text("No exercises match your search.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.vertical, 8)
        .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
        .listRowBackground(Color.clear)
        .listRowSeparator(.hidden)
    } else {
      ForEach(viewModel.filteredExercises) { exercise in
        ExerciseLibraryCard(exercise: exercise)
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            if exercise.isCustomExercise {
              Button {
                editingExercise = exercise
              } label: {
                Label("Edit", systemImage: "pencil")
              }
              .tint(AppColors.infoBlue)
            }
          }
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
          .listRowBackground(Color.clear)
          .listRowSeparator(.hidden)
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(AppColors.textSecondary)
        .font(.system(size: 14, weight: .semibold))

      TextField("Search exercises...", text: $viewModel.searchText)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .font(.system(size: 16))
    }
    .padding(.horizontal, 12)
    .frame(height: 44)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(Color(.systemGray6))
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(AppColors.borderGray, lineWidth: 1)
    )
    .listRowInsets(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
  }

  private func inlineErrorRow(message: String) -> some View {
    HStack(spacing: 8) {
      Image(systemName: "exclamationmark.triangle.fill")
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(AppColors.errorRed)
      Text(message)
        .font(.system(size: 13, weight: .medium))
        .foregroundStyle(AppColors.errorRed)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(AppColors.errorRed.opacity(0.1))
    .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))
    .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 8, trailing: 16))
    .listRowBackground(Color.clear)
    .listRowSeparator(.hidden)
  }
}

private struct ExerciseLibraryCard: View {
  let exercise: ExerciseResponse

  private var sourceBadgeColor: Color {
    exercise.isCustomExercise ? AppColors.warningYellow : AppColors.infoBlue
  }

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "figure.strengthtraining.traditional")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 36, height: 36)
        .background(AppColors.accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 6) {
        Text(exercise.name)
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)
          .lineLimit(2)

        HStack(spacing: 8) {
          Text(exercise.measurementType.workoutDisplayLabel)
            .font(.system(size: 11, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          Text(exercise.sourceBadgeText)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(sourceBadgeColor)
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
            .background(sourceBadgeColor.opacity(0.14))
            .cornerRadius(999)
        }
      }

      Spacer(minLength: 0)

      if exercise.isCustomExercise {
        Image(systemName: "pencil")
          .font(.system(size: 13, weight: .semibold))
          .foregroundStyle(AppColors.textSecondary)
          .padding(.top, 2)
      }
    }
    .padding(14)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(AppColors.surface)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .strokeBorder(AppColors.borderGray, lineWidth: 1)
    )
  }
}
