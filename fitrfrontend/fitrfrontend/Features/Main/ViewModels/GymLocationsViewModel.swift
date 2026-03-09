//
//  GymLocationsViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/6/26.
//

import Foundation
internal import Combine

struct GymLocationsSnapshot {
  let locations: [LocationResponse]
}

@MainActor
final class GymLocationsViewModel: ObservableObject {
  enum FormMode {
    case add
    case edit(LocationResponse)
  }

  @Published var locations: [LocationResponse] = []
  @Published var searchText = ""
  @Published var isLoading = false
  @Published private(set) var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published var isSaving = false
  @Published var isDeleting = false
  @Published var errorMessage: String?

  @Published var showFormSheet = false
  @Published var formName = ""
  @Published var formAddress = ""
  @Published var formErrorMessage: String?

  @Published var deleteTarget: LocationResponse?

  private var sessionStore: SessionStore?
  private var formMode: FormMode = .add
  private let locationsService: LocationsService
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

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

  func updateSessionStore(_ store: SessionStore) {
    self.sessionStore = store
    restoreSnapshotIfAvailable()
  }

  func loadLocations(forceRefresh: Bool = false) async {
    if isFetching {
      return
    }

    restoreSnapshotIfNewer()

    if
      !forceRefresh,
      let lastLoadedAt,
      Date().timeIntervalSince(lastLoadedAt) < freshnessInterval
    {
      return
    }

    let shouldBlockUI = !hasLoadedSnapshot
    isFetching = true
    if shouldBlockUI {
      isLoading = true
    } else {
      isRefreshing = true
    }
    errorMessage = nil

    defer {
      isFetching = false
      if shouldBlockUI {
        isLoading = false
      } else {
        isRefreshing = false
      }
    }

    do {
      let fetchedLocations = try await locationsService.fetchLocations()
      locations = sortLocations(fetchedLocations)
      persistSnapshot(loadedAt: Date())
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
      persistSnapshot(loadedAt: Date())
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
      persistSnapshot(loadedAt: Date())
    } catch {
      errorMessage = resolveErrorMessage(error, fallback: "Couldn't delete that location.")
    }
  }

  private func persistSnapshot(loadedAt: Date) {
    guard let sessionStore else {
      return
    }

    let snapshot = GymLocationsSnapshot(locations: locations)
    hasLoadedSnapshot = true
    lastLoadedAt = loadedAt
    sessionStore.runtimeViewCache.store(snapshot, for: .gymLocations, at: loadedAt)
  }

  private func restoreSnapshotIfAvailable() {
    guard
      let sessionStore,
      let snapshot: RuntimeViewCacheSnapshot<GymLocationsSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .gymLocations, as: GymLocationsSnapshot.self)
    else {
      return
    }

    locations = snapshot.value.locations
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
    isLoading = false
  }

  private func restoreSnapshotIfNewer() {
    guard
      let sessionStore,
      let snapshot: RuntimeViewCacheSnapshot<GymLocationsSnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .gymLocations, as: GymLocationsSnapshot.self)
    else {
      return
    }

    if let lastLoadedAt, snapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    locations = snapshot.value.locations
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
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
