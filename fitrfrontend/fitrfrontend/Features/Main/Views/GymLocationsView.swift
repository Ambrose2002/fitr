//
//  GymLocationsView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/6/26.
//

import SwiftUI

struct GymLocationsView: View {
  @EnvironmentObject private var sessionStore: SessionStore
  @StateObject private var viewModel: GymLocationsViewModel

  init(viewModel: GymLocationsViewModel) {
    _viewModel = StateObject(wrappedValue: viewModel)
  }

  init() {
    _viewModel = StateObject(wrappedValue: GymLocationsViewModel())
  }

  var body: some View {
    List {
      Section {
        searchField
      }
      .listRowBackground(Color.clear)

      if let errorMessage = viewModel.errorMessage {
        Section {
          inlineErrorRow(message: errorMessage)
        }
        .listRowBackground(Color.clear)
      }

      Section {
        locationRows
        addLocationButton
      } header: {
        Text(viewModel.savedSpotsTitle)
          .font(.system(size: 13, weight: .black))
          .foregroundStyle(AppColors.textSecondary)
          .tracking(1)
      }
      .listRowBackground(Color.clear)

      Section {
        infoCard
      }
      .listRowBackground(Color.clear)
    }
    .listStyle(.insetGrouped)
    .scrollContentBackground(.hidden)
    .background(AppColors.background.ignoresSafeArea())
    .navigationTitle("GYM LOCATIONS")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          viewModel.presentAddForm()
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 16, weight: .bold))
        }
        .disabled(viewModel.isSaving || viewModel.isDeleting)
      }
    }
    .task {
      viewModel.updateSessionStore(sessionStore)
      await viewModel.loadLocations()
    }
    .refreshable {
      await viewModel.loadLocations(forceRefresh: true)
    }
    .sheet(isPresented: $viewModel.showFormSheet) {
      GymLocationFormSheet(
        title: viewModel.formTitle,
        saveButtonTitle: viewModel.formSaveTitle,
        name: $viewModel.formName,
        address: $viewModel.formAddress,
        errorMessage: viewModel.formErrorMessage,
        canSave: viewModel.canSaveForm,
        isSaving: viewModel.isSaving,
        onCancel: {
          viewModel.dismissForm()
        },
        onSave: {
          Task {
            await viewModel.saveForm()
          }
        }
      )
    }
    .alert(item: $viewModel.deleteTarget) { location in
      Alert(
        title: Text("Delete \(location.name)?"),
        message: Text("This location will be removed from your saved spots."),
        primaryButton: .destructive(Text("Delete")) {
          Task {
            await viewModel.confirmDelete(location)
          }
        },
        secondaryButton: .cancel()
      )
    }
  }

  @ViewBuilder
  private var locationRows: some View {
    if viewModel.isLoading && viewModel.locations.isEmpty {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)
        Text("Loading locations...")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(AppColors.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .listRowSeparator(.hidden)
    } else if viewModel.isRefreshing {
      HStack(spacing: 10) {
        ProgressView()
          .controlSize(.small)
        Text("Refreshing locations...")
          .font(.system(size: 14, weight: .medium))
          .foregroundStyle(AppColors.textSecondary)
      }
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(12)
      .listRowSeparator(.hidden)
    } else if viewModel.locations.isEmpty {
      Text("No saved locations yet. Add your first gym location.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    } else if viewModel.filteredLocations.isEmpty {
      Text("No locations match your search.")
        .font(.system(size: 14, weight: .medium))
        .foregroundStyle(AppColors.textSecondary)
        .padding(.vertical, 8)
        .listRowSeparator(.hidden)
    } else {
      ForEach(viewModel.filteredLocations) { location in
        GymLocationCard(location: location)
          .swipeActions(edge: .leading, allowsFullSwipe: false) {
            Button {
              viewModel.presentEditForm(location)
            } label: {
              Label("Edit", systemImage: "pencil")
            }
            .tint(AppColors.infoBlue)
          }
          .swipeActions(edge: .trailing, allowsFullSwipe: false) {
            Button(role: .destructive) {
              viewModel.requestDelete(location)
            } label: {
              Label("Delete", systemImage: "trash")
            }
          }
          .listRowInsets(EdgeInsets(top: 6, leading: 0, bottom: 6, trailing: 0))
          .listRowSeparator(.hidden)
      }
    }
  }

  private var searchField: some View {
    HStack(spacing: 10) {
      Image(systemName: "magnifyingglass")
        .foregroundStyle(AppColors.textSecondary)
        .font(.system(size: 14, weight: .semibold))

      TextField("Search your locations...", text: $viewModel.searchText)
        .textInputAutocapitalization(.words)
        .autocorrectionDisabled()
        .font(.system(size: 16))
    }
    .padding(.horizontal, 12)
    .frame(height: 44)
    .background(Color(.systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 8, trailing: 0))
    .listRowSeparator(.hidden)
  }

  private var addLocationButton: some View {
    Button {
      viewModel.presentAddForm()
    } label: {
      HStack(spacing: 10) {
        Image(systemName: "plus")
          .font(.system(size: 14, weight: .bold))
        Text("Add New Location")
          .font(.system(size: 16, weight: .semibold))
      }
      .foregroundStyle(AppColors.textPrimary)
      .frame(maxWidth: .infinity)
      .frame(height: 52)
      .overlay(
        RoundedRectangle(cornerRadius: 12, style: .continuous)
          .stroke(
            AppColors.borderGray,
            style: StrokeStyle(lineWidth: 1, dash: [5, 5])
          )
      )
    }
    .buttonStyle(.plain)
    .padding(.top, 8)
    .listRowSeparator(.hidden)
  }

  private var infoCard: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "location.circle.fill")
        .font(.system(size: 22, weight: .semibold))
        .foregroundStyle(AppColors.accent)

      VStack(alignment: .leading, spacing: 4) {
        Text("Quick Setup")
          .font(.system(size: 13, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)
        Text("Adding precise locations helps Fitr detect your gym and suggest relevant workout plans.")
          .font(.system(size: 13))
          .foregroundStyle(AppColors.textSecondary)
      }
    }
    .padding(14)
    .background(AppColors.accent.opacity(0.13))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .listRowInsets(EdgeInsets(top: 8, leading: 0, bottom: 12, trailing: 0))
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
    .listRowInsets(EdgeInsets(top: 0, leading: 0, bottom: 8, trailing: 0))
    .listRowSeparator(.hidden)
  }
}

private struct GymLocationCard: View {
  let location: LocationResponse

  var body: some View {
    HStack(alignment: .top, spacing: 12) {
      Image(systemName: "mappin.and.ellipse")
        .font(.system(size: 14, weight: .bold))
        .foregroundStyle(AppColors.accent)
        .frame(width: 36, height: 36)
        .background(AppColors.accent.opacity(0.14))
        .clipShape(RoundedRectangle(cornerRadius: 10, style: .continuous))

      VStack(alignment: .leading, spacing: 4) {
        Text(location.name)
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)
          .lineLimit(1)

        HStack(spacing: 5) {
          Image(systemName: "location")
            .font(.system(size: 10, weight: .bold))
            .foregroundStyle(AppColors.textSecondary)

          Text(location.address)
            .font(.system(size: 14))
            .foregroundStyle(AppColors.textSecondary)
            .lineLimit(2)
            .multilineTextAlignment(.leading)
        }
      }

      Spacer(minLength: 0)
    }
    .padding(14)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
  }
}

private struct GymLocationFormSheet: View {
  let title: String
  let saveButtonTitle: String

  @Binding var name: String
  @Binding var address: String

  let errorMessage: String?
  let canSave: Bool
  let isSaving: Bool
  let onCancel: () -> Void
  let onSave: () -> Void

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        VStack(alignment: .leading, spacing: 6) {
          Text("Location Name")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
          TextField("e.g., Iron Paradise", text: $name)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(.horizontal, 12)
            .frame(height: 46)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        VStack(alignment: .leading, spacing: 6) {
          Text("Address")
            .font(.system(size: 13, weight: .bold))
            .foregroundStyle(AppColors.textPrimary)
          TextField("e.g., 123 Muscle Ave", text: $address, axis: .vertical)
            .lineLimit(2...4)
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .padding(.horizontal, 12)
            .padding(.vertical, 12)
            .background(Color(.systemGray6))
            .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }

        if let errorMessage, !errorMessage.isEmpty {
          Text(errorMessage)
            .font(.system(size: 13, weight: .medium))
            .foregroundStyle(AppColors.errorRed)
        }

        Spacer()

        Button {
          onSave()
        } label: {
          HStack(spacing: 8) {
            if isSaving {
              ProgressView()
                .controlSize(.small)
                .tint(.white)
            }
            Text(isSaving ? "Saving..." : saveButtonTitle)
              .font(.system(size: 16, weight: .semibold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(canSave ? AppColors.accent : AppColors.accent.opacity(0.45))
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(!canSave)
      }
      .padding(16)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .cancellationAction) {
          Button("Cancel") {
            onCancel()
          }
          .disabled(isSaving)
        }
      }
    }
    .presentationDetents([.medium])
    .presentationDragIndicator(.visible)
  }
}
