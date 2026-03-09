//
//  WeightHistoryViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/5/26.
//

import Foundation
internal import Combine

enum WeightHistoryDeltaDirection: Hashable {
  case up
  case down
  case flat
}

struct WeightHistorySummaryData: Hashable {
  let currentValueText: String
  let currentSubtitle: String
  let netChangeValueText: String
  let netChangeSubtitle: String
  let netChangeDirection: WeightHistoryDeltaDirection
  let avgWeeklyValueText: String
  let avgWeeklySubtitle: String
  let avgWeeklyDirection: WeightHistoryDeltaDirection

  static let empty = WeightHistorySummaryData(
    currentValueText: "--",
    currentSubtitle: "No entries yet",
    netChangeValueText: "0",
    netChangeSubtitle: "Need at least 2 entries",
    netChangeDirection: .flat,
    avgWeeklyValueText: "0",
    avgWeeklySubtitle: "Need at least 2 entries",
    avgWeeklyDirection: .flat
  )
}

struct WeightHistoryChartPoint: Identifiable, Hashable {
  let id: Int64
  let date: Date
  let value: Double
}

struct WeightHistoryEntryRow: Identifiable, Hashable {
  let id: Int64
  let recordedAt: Date
  let displayValue: Double
  let dateText: String
  let entryPeriodText: String
  let valueText: String
  let deltaText: String
  let deltaDirection: WeightHistoryDeltaDirection
}

struct WeightHistorySnapshot {
  let entries: [WeightHistoryEntryRow]
  let chartPoints: [WeightHistoryChartPoint]
  let summary: WeightHistorySummaryData
  let loadedCountText: String
  let hasMoreEntries: Bool
  let currentLimit: Int
}

@MainActor
final class WeightHistoryViewModel: ObservableObject {
  private let pageSize = 12
  private let chartLookbackDays = 30

  @Published var isLoading = false
  @Published var isRefreshing = false
  @Published private(set) var hasLoadedSnapshot = false
  @Published var isLoadingMore = false
  @Published var isSavingEntry = false
  @Published var errorMessage: String?
  @Published var entries: [WeightHistoryEntryRow] = []
  @Published var chartPoints: [WeightHistoryChartPoint] = []
  @Published var summary: WeightHistorySummaryData = .empty
  @Published var loadedCountText: String = "0 Loaded"
  @Published var hasMoreEntries = false
  @Published var showAddSheet = false
  @Published var addEntryErrorMessage: String?
  @Published var showEditSheet = false
  @Published var editingEntry: WeightHistoryEntryRow?
  @Published var pendingDeleteEntry: WeightHistoryEntryRow?
  @Published var entryMutationErrorMessage: String?

  private let sessionStore: SessionStore
  private let bodyMetricsService: BodyMetricsService
  private let skipInitialFetch: Bool
  private var currentLimit: Int
  private var lastLoadedAt: Date?
  private let freshnessInterval: TimeInterval = 60
  private var isFetching = false

  init(
    sessionStore: SessionStore,
    initialEntries: [BodyMetricResponse]? = nil,
    initialChartMetrics: [BodyMetricResponse]? = nil,
    initialError: String? = nil,
    initialHasMoreEntries: Bool = false,
    initialLoadedCountText: String? = nil
  ) {
    self.sessionStore = sessionStore
    self.bodyMetricsService = BodyMetricsService()
    self.currentLimit = pageSize
    self.skipInitialFetch =
      initialEntries != nil || initialChartMetrics != nil || initialError != nil

    if let initialError {
      self.errorMessage = initialError
    }

    if let initialEntries {
      let sortedEntries = initialEntries.sorted { $0.updatedAt > $1.updatedAt }
      let sortedChart = (initialChartMetrics ?? initialEntries).sorted { $0.updatedAt > $1.updatedAt }
      apply(entriesMetrics: sortedEntries, chartMetrics: sortedChart)
      self.hasMoreEntries = initialHasMoreEntries
      self.loadedCountText = initialLoadedCountText ?? "\(self.entries.count) Loaded"
      self.currentLimit = max(pageSize, sortedEntries.count)
      let loadedAt = Date()
      self.hasLoadedSnapshot = true
      self.lastLoadedAt = loadedAt
      persistSnapshot(loadedAt: loadedAt)
    } else {
      restoreSnapshotIfAvailable()
    }
  }

  func loadInitial() async {
    await load(forceRefresh: false)
  }

  func refresh() async {
    await load(forceRefresh: true)
  }

  func load(forceRefresh: Bool = false) async {
    guard !skipInitialFetch else { return }
    guard !isFetching else { return }
    guard !isLoadingMore else { return }

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
      let result = try await fetchWeightData(limit: currentLimit)
      apply(entriesMetrics: result.entriesMetrics, chartMetrics: result.chartMetrics)
      let loadedAt = Date()
      hasLoadedSnapshot = true
      lastLoadedAt = loadedAt
      persistSnapshot(loadedAt: loadedAt)
    } catch is CancellationError {
      return
    } catch let urlError as URLError where urlError.code == .cancelled {
      return
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = error.localizedDescription
    }
  }

  func loadMoreEntries() async {
    guard !isLoadingMore else { return }
    guard !isLoading && !isRefreshing else { return }
    guard hasMoreEntries else { return }

    let previousLimit = currentLimit
    currentLimit += pageSize
    isLoadingMore = true

    defer {
      isLoadingMore = false
    }

    do {
      let result = try await fetchWeightData(limit: currentLimit)
      apply(entriesMetrics: result.entriesMetrics, chartMetrics: result.chartMetrics)
      let loadedAt = Date()
      hasLoadedSnapshot = true
      lastLoadedAt = loadedAt
      persistSnapshot(loadedAt: loadedAt)
    } catch is CancellationError {
      currentLimit = previousLimit
      return
    } catch let urlError as URLError where urlError.code == .cancelled {
      currentLimit = previousLimit
      return
    } catch let apiError as APIErrorResponse {
      currentLimit = previousLimit
      errorMessage = apiError.message
    } catch {
      currentLimit = previousLimit
      errorMessage = error.localizedDescription
    }
  }

  func saveWeightEntry(inputText: String) async -> Bool {
    guard !isSavingEntry else { return false }

    addEntryErrorMessage = nil
    let inputCopy = String(inputText)
    let trimmedInput = inputCopy.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedInput.isEmpty else {
      addEntryErrorMessage = "Enter a weight value."
      return false
    }

    guard let valueInPreferredUnit = Float(trimmedInput) else {
      addEntryErrorMessage = "Enter a valid number."
      return false
    }

    guard valueInPreferredUnit > 0 else {
      addEntryErrorMessage = "Weight must be greater than 0."
      return false
    }

    if
      let validRange = UnitValidator.validWeightRange(for: preferredWeightUnit),
      !validRange.contains(valueInPreferredUnit)
    {
      let minValue = Self.formattedNumber(Double(validRange.lowerBound), maximumFractionDigits: 0)
      let maxValue = Self.formattedNumber(Double(validRange.upperBound), maximumFractionDigits: 0)
      addEntryErrorMessage = "Enter a value between \(minValue) and \(maxValue) \(weightUnitLabel)."
      return false
    }

    let valueInKg = UnitConverter.convertWeight(
      valueInPreferredUnit,
      from: preferredWeightUnit,
      to: .kg
    )

    guard valueInKg.isFinite && valueInKg > 0 else {
      addEntryErrorMessage = "Unable to convert this weight value."
      return false
    }

    isSavingEntry = true

    defer {
      isSavingEntry = false
    }

    do {
      _ = try await bodyMetricsService.createBodyMetric(
        CreateBodyMetricRequest(
          metricType: .weight,
          value: valueInKg
        )
      )
      showAddSheet = false
      addEntryErrorMessage = nil
      await refresh()
      return true
    } catch is CancellationError {
      return false
    } catch let urlError as URLError where urlError.code == .cancelled {
      return false
    } catch let apiError as APIErrorResponse {
      addEntryErrorMessage = apiError.message
      return false
    } catch {
      addEntryErrorMessage = error.localizedDescription
      return false
    }
  }

  func updateWeightEntry(id: Int64, inputText: String) async -> Bool {
    guard !isSavingEntry else { return false }

    entryMutationErrorMessage = nil
    let inputCopy = String(inputText)
    let trimmedInput = inputCopy.trimmingCharacters(in: .whitespacesAndNewlines)

    guard !trimmedInput.isEmpty else {
      entryMutationErrorMessage = "Enter a weight value."
      return false
    }

    guard let valueInPreferredUnit = Float(trimmedInput) else {
      entryMutationErrorMessage = "Enter a valid number."
      return false
    }

    guard valueInPreferredUnit > 0 else {
      entryMutationErrorMessage = "Weight must be greater than 0."
      return false
    }

    if
      let validRange = UnitValidator.validWeightRange(for: preferredWeightUnit),
      !validRange.contains(valueInPreferredUnit)
    {
      let minValue = Self.formattedNumber(Double(validRange.lowerBound), maximumFractionDigits: 0)
      let maxValue = Self.formattedNumber(Double(validRange.upperBound), maximumFractionDigits: 0)
      entryMutationErrorMessage = "Enter a value between \(minValue) and \(maxValue) \(weightUnitLabel)."
      return false
    }

    let valueInKg = UnitConverter.convertWeight(
      valueInPreferredUnit,
      from: preferredWeightUnit,
      to: .kg
    )

    guard valueInKg.isFinite && valueInKg > 0 else {
      entryMutationErrorMessage = "Unable to convert this weight value."
      return false
    }

    isSavingEntry = true

    defer {
      isSavingEntry = false
    }

    do {
      _ = try await bodyMetricsService.updateBodyMetric(
        id: id,
        request: CreateBodyMetricRequest(metricType: .weight, value: valueInKg)
      )
      showEditSheet = false
      editingEntry = nil
      entryMutationErrorMessage = nil
      await refresh()
      return true
    } catch is CancellationError {
      return false
    } catch let urlError as URLError where urlError.code == .cancelled {
      return false
    } catch let apiError as APIErrorResponse {
      entryMutationErrorMessage = apiError.message
      return false
    } catch {
      entryMutationErrorMessage = error.localizedDescription
      return false
    }
  }

  func deleteWeightEntry(id: Int64) async -> Bool {
    entryMutationErrorMessage = nil

    do {
      try await bodyMetricsService.deleteBodyMetric(id: id)
      pendingDeleteEntry = nil
      entryMutationErrorMessage = nil
      await refresh()
      return true
    } catch is CancellationError {
      return false
    } catch let urlError as URLError where urlError.code == .cancelled {
      return false
    } catch let apiError as APIErrorResponse {
      entryMutationErrorMessage = apiError.message
      return false
    } catch {
      entryMutationErrorMessage = error.localizedDescription
      return false
    }
  }

  var weightUnitLabel: String {
    preferredWeightUnit.abbreviation
  }

  private var preferredWeightUnit: Unit {
    sessionStore.userProfile?.preferredWeightUnit ?? .kg
  }

  private func fetchWeightData(limit: Int) async throws -> (
    entriesMetrics: [BodyMetricResponse],
    chartMetrics: [BodyMetricResponse]
  ) {
    let now = Date()
    let chartStartDate =
      Calendar.current.date(byAdding: .day, value: -chartLookbackDays, to: now)
      ?? now.addingTimeInterval(Double(-chartLookbackDays) * 86_400)

    async let entriesResponse = bodyMetricsService.fetchBodyMetrics(
      metricType: .weight,
      limit: limit
    )
    async let chartResponse = bodyMetricsService.fetchBodyMetrics(
      metricType: .weight,
      fromDate: chartStartDate,
      toDate: now
    )

    let (entries, chart) = try await (entriesResponse, chartResponse)
    return (
      entriesMetrics: entries.sorted { $0.updatedAt > $1.updatedAt },
      chartMetrics: chart.sorted { $0.updatedAt > $1.updatedAt }
    )
  }

  private func apply(
    entriesMetrics: [BodyMetricResponse],
    chartMetrics: [BodyMetricResponse]
  ) {
    errorMessage = nil
    entries = buildEntryRows(from: entriesMetrics)
    chartPoints = chartMetrics
      .sorted { $0.updatedAt < $1.updatedAt }
      .map { metric in
        WeightHistoryChartPoint(
          id: metric.id,
          date: metric.updatedAt,
          value: displayWeightValue(fromKg: Double(metric.value))
        )
      }
    summary = buildSummary(entriesMetrics: entriesMetrics, chartMetrics: chartMetrics)
    loadedCountText = "\(entries.count) Loaded"
    hasMoreEntries = entriesMetrics.count >= currentLimit
    addEntryErrorMessage = nil
    entryMutationErrorMessage = nil
  }

  private func buildEntryRows(from metrics: [BodyMetricResponse]) -> [WeightHistoryEntryRow] {
    guard !metrics.isEmpty else {
      return []
    }

    return metrics.enumerated().map { index, metric in
      let valueText = UnitFormatter.formatWeight(
        metric.value,
        preferredUnit: preferredWeightUnit,
        decimalPlaces: 1
      )

      let deltaText: String
      let rowDeltaDirection: WeightHistoryDeltaDirection

      if metrics.indices.contains(index + 1) {
        let olderMetric = metrics[index + 1]
        let deltaInDisplayUnit =
          displayWeightValue(fromKg: Double(metric.value))
          - displayWeightValue(fromKg: Double(olderMetric.value))
        let direction = deltaDirection(for: deltaInDisplayUnit)
        rowDeltaDirection = direction

        switch direction {
        case .flat:
          deltaText = "STABLE"
        case .up:
          deltaText =
            "+\(Self.formattedNumber(abs(deltaInDisplayUnit), maximumFractionDigits: 1)) \(weightUnitLabel)"
        case .down:
          deltaText =
            "-\(Self.formattedNumber(abs(deltaInDisplayUnit), maximumFractionDigits: 1)) \(weightUnitLabel)"
        }
      } else {
        deltaText = "STABLE"
        rowDeltaDirection = .flat
      }

      return WeightHistoryEntryRow(
        id: metric.id,
        recordedAt: metric.updatedAt,
        displayValue: displayWeightValue(fromKg: Double(metric.value)),
        dateText: Self.entryDateFormatter.string(from: metric.updatedAt),
        entryPeriodText: entryPeriodText(for: metric.updatedAt),
        valueText: valueText,
        deltaText: deltaText,
        deltaDirection: rowDeltaDirection
      )
    }
  }

  private func buildSummary(
    entriesMetrics: [BodyMetricResponse],
    chartMetrics: [BodyMetricResponse]
  ) -> WeightHistorySummaryData {
    let currentMetric = entriesMetrics.first
    let currentValueText =
      currentMetric.map {
        UnitFormatter.formatWeight($0.value, preferredUnit: preferredWeightUnit, decimalPlaces: 1)
      } ?? "--"

    guard chartMetrics.count >= 2 else {
      return WeightHistorySummaryData(
        currentValueText: currentValueText,
        currentSubtitle: currentMetric == nil ? "No entries yet" : "Latest entry",
        netChangeValueText: "0 \(weightUnitLabel)",
        netChangeSubtitle: "Need at least 2 entries",
        netChangeDirection: .flat,
        avgWeeklyValueText: "0 \(weightUnitLabel)",
        avgWeeklySubtitle: "Need at least 2 entries",
        avgWeeklyDirection: .flat
      )
    }

    guard let latestMetric = chartMetrics.first, let oldestMetric = chartMetrics.last else {
      return .empty
    }

    let latestDisplayWeight = displayWeightValue(fromKg: Double(latestMetric.value))
    let oldestDisplayWeight = displayWeightValue(fromKg: Double(oldestMetric.value))
    let netChange = latestDisplayWeight - oldestDisplayWeight
    let netDirection = deltaDirection(for: netChange)

    let daySpan = max(
      Calendar.current.dateComponents([.day], from: oldestMetric.updatedAt, to: latestMetric.updatedAt).day ?? 0,
      1
    )
    let avgWeekChange = (netChange / Double(daySpan)) * 7
    let avgWeekDirection = deltaDirection(for: avgWeekChange)

    return WeightHistorySummaryData(
      currentValueText: currentValueText,
      currentSubtitle: "Latest entry",
      netChangeValueText: signedValueText(for: netChange, maximumFractionDigits: 1),
      netChangeSubtitle: "vs. \(Self.shortDateFormatter.string(from: oldestMetric.updatedAt))",
      netChangeDirection: netDirection,
      avgWeeklyValueText: signedValueText(for: avgWeekChange, maximumFractionDigits: 2),
      avgWeeklySubtitle: "Based on 30-day trend",
      avgWeeklyDirection: avgWeekDirection
    )
  }

  private func persistSnapshot(loadedAt: Date) {
    let snapshot = WeightHistorySnapshot(
      entries: entries,
      chartPoints: chartPoints,
      summary: summary,
      loadedCountText: loadedCountText,
      hasMoreEntries: hasMoreEntries,
      currentLimit: currentLimit
    )
    sessionStore.runtimeViewCache.store(snapshot, for: .weightHistory, at: loadedAt)
  }

  private func restoreSnapshotIfAvailable() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<WeightHistorySnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .weightHistory, as: WeightHistorySnapshot.self)
    else {
      return
    }

    entries = snapshot.value.entries
    chartPoints = snapshot.value.chartPoints
    summary = snapshot.value.summary
    loadedCountText = snapshot.value.loadedCountText
    hasMoreEntries = snapshot.value.hasMoreEntries
    currentLimit = max(pageSize, snapshot.value.currentLimit)
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
    isLoading = false
  }

  private func restoreSnapshotIfNewer() {
    guard
      let snapshot: RuntimeViewCacheSnapshot<WeightHistorySnapshot> = sessionStore.runtimeViewCache
        .snapshot(for: .weightHistory, as: WeightHistorySnapshot.self)
    else {
      return
    }

    if let lastLoadedAt, snapshot.lastLoadedAt <= lastLoadedAt {
      return
    }

    entries = snapshot.value.entries
    chartPoints = snapshot.value.chartPoints
    summary = snapshot.value.summary
    loadedCountText = snapshot.value.loadedCountText
    hasMoreEntries = snapshot.value.hasMoreEntries
    currentLimit = max(pageSize, snapshot.value.currentLimit)
    hasLoadedSnapshot = true
    lastLoadedAt = snapshot.lastLoadedAt
  }

  private func signedValueText(for value: Double, maximumFractionDigits: Int) -> String {
    let direction = deltaDirection(for: value)

    switch direction {
    case .flat:
      return "0 \(weightUnitLabel)"
    case .up:
      return "+\(Self.formattedNumber(abs(value), maximumFractionDigits: maximumFractionDigits)) \(weightUnitLabel)"
    case .down:
      return "-\(Self.formattedNumber(abs(value), maximumFractionDigits: maximumFractionDigits)) \(weightUnitLabel)"
    }
  }

  private func deltaDirection(for value: Double) -> WeightHistoryDeltaDirection {
    if abs(value) < 0.01 {
      return .flat
    }

    return value > 0 ? .up : .down
  }

  private func displayWeightValue(fromKg value: Double) -> Double {
    if preferredWeightUnit == .lb {
      return Double(UnitConverter.kgToLb(Float(value)))
    }

    return value
  }

  private func entryPeriodText(for date: Date) -> String {
    let hour = Calendar.current.component(.hour, from: date)
    if hour < 12 {
      return "Morning Entry"
    }
    if hour < 17 {
      return "Afternoon Entry"
    }
    return "Evening Entry"
  }

  private static func formattedNumber(
    _ value: Double,
    maximumFractionDigits: Int
  ) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = maximumFractionDigits

    if let result = formatter.string(from: NSNumber(value: value)) {
      return result
    }

    return String(format: "%.\(maximumFractionDigits)f", value)
  }

  private static let entryDateFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM d, yyyy"
    return formatter
  }()

  private static let shortDateFormatter: Foundation.DateFormatter = {
    let formatter = Foundation.DateFormatter()
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.dateFormat = "MMM d"
    return formatter
  }()
}
