//
//  GymLocationsViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/6/26.
//

import Foundation
internal import Combine

@MainActor
final class GymLocationsViewModel: ObservableObject {
  enum FormMode {
    case add
    case edit(LocationResponse)
  }

  @Published var locations: [LocationResponse] = []
  @Published var searchText = ""
  @Published var isLoading = false
  @Published var isSaving = false
  @Published var isDeleting = false
  @Published var errorMessage: String?

  @Published var showFormSheet = false
  @Published var formName = ""
  @Published var formAddress = ""
  @Published var formErrorMessage: String?

  @Published var deleteTarget: LocationResponse?

  private var hasLoaded = false
  private var formMode: FormMode = .add
  private let locationsService: LocationsService

  init(locationsService: LocationsService) {
    self.locationsService = locationsService
  }

  convenience init() {
    self.init(locationsService: LocationsService())
  }

  var filteredLocations: [LocationResponse] {
    let query = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
    guard !query.isEmpty else {
      return locations
    }

    let normalizedQuery = query.lowercased()
    return locations.filter { location in
      location.name.lowercased().contains(normalizedQuery)
        || location.address.lowercased().contains(normalizedQuery)
    }
  }

  var savedSpotsTitle: String {
    "SAVED SPOTS (\(locations.count))"
  }

  var formTitle: String {
    switch formMode {
    case .add:
      return "Add Location"
    case .edit:
      return "Edit Location"
    }
  }

  var formSaveTitle: String {
    switch formMode {
    case .add:
      return "Add Location"
    case .edit:
      return "Save Changes"
    }
  }

  var canSaveForm: Bool {
    !isSaving
      && !formName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
      && !formAddress.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
  }

  func loadLocations(forceRefresh: Bool = false) async {
    if isLoading {
      return
    }

    if hasLoaded && !forceRefresh {
      return
    }

    isLoading = true
    errorMessage = nil
    hasLoaded = true

    defer {
      isLoading = false
    }

    do {
      let fetchedLocations = try await locationsService.fetchLocations()
      locations = sortLocations(fetchedLocations)
    } catch {
      errorMessage = resolveErrorMessage(error, fallback: "Couldn't load your saved locations.")
    }
  }

  func presentAddForm() {
    formMode = .add
    formName = ""
    formAddress = ""
    formErrorMessage = nil
    showFormSheet = true
  }

  func presentEditForm(_ location: LocationResponse) {
    formMode = .edit(location)
    formName = location.name
    formAddress = location.address
    formErrorMessage = nil
    showFormSheet = true
  }

  func dismissForm() {
    guard !isSaving else {
      return
    }
    showFormSheet = false
    formErrorMessage = nil
  }

  func saveForm() async {
    if isSaving {
      return
    }

    formErrorMessage = nil
    let trimmedName = formName.trimmingCharacters(in: .whitespacesAndNewlines)
    let trimmedAddress = formAddress.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedName.isEmpty else {
      formErrorMessage = "Location name is required."
      return
    }

    guard !trimmedAddress.isEmpty else {
      formErrorMessage = "Location address is required."
      return
    }

    isSaving = true
    defer { isSaving = false }

    let payload = CreateLocationRequest(name: trimmedName, address: trimmedAddress)

    do {
      switch formMode {
      case .add:
        let createdLocation = try await locationsService.createLocation(payload)
        locations = sortLocations(locations + [createdLocation])
      case .edit(let existing):
        let updatedLocation = try await locationsService.updateLocation(id: existing.id, request: payload)
        locations = sortLocations(
          locations.map { location in
            location.id == updatedLocation.id ? updatedLocation : location
          }
        )
      }

      errorMessage = nil
      showFormSheet = false
      formErrorMessage = nil
    } catch {
      formErrorMessage = resolveErrorMessage(error, fallback: "Couldn't save that location.")
    }
  }

  func requestDelete(_ location: LocationResponse) {
    deleteTarget = location
  }

  func confirmDelete(_ location: LocationResponse) async {
    if isDeleting {
      return
    }

    isDeleting = true
    defer { isDeleting = false }

    do {
      try await locationsService.deleteLocation(id: location.id)
      locations.removeAll { $0.id == location.id }
      errorMessage = nil
    } catch {
      errorMessage = resolveErrorMessage(error, fallback: "Couldn't delete that location.")
    }
  }

  private func sortLocations(_ source: [LocationResponse]) -> [LocationResponse] {
    source.sorted { lhs, rhs in
      let left = lhs.name.trimmingCharacters(in: .whitespacesAndNewlines)
      let right = rhs.name.trimmingCharacters(in: .whitespacesAndNewlines)
      let order = left.localizedCaseInsensitiveCompare(right)

      if order == .orderedSame {
        return lhs.id < rhs.id
      }

      return order == .orderedAscending
    }
  }

  private func resolveErrorMessage(_ error: Error, fallback: String) -> String {
    if let apiError = error as? APIErrorResponse {
      return apiError.message
    }

    return fallback
  }
}
