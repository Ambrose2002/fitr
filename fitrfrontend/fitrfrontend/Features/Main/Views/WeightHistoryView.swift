//
//  WeightHistoryView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 3/5/26.
//

import Charts
import SwiftUI

enum WeightHistoryLaunchAction: Equatable {
  case addEntry
}

struct WeightHistoryView: View {
  @Binding private var launchAction: WeightHistoryLaunchAction?
  @StateObject private var viewModel: WeightHistoryViewModel
  @State private var deleteFailureMessage: String?
  private let onWeightEntrySaved: () -> Void

  init(
    sessionStore: SessionStore,
    launchAction: Binding<WeightHistoryLaunchAction?> = .constant(nil),
    onWeightEntrySaved: @escaping () -> Void = {},
    initialEntries: [BodyMetricResponse]? = nil,
    initialChartMetrics: [BodyMetricResponse]? = nil,
    initialError: String? = nil,
    initialHasMoreEntries: Bool = false,
    initialLoadedCountText: String? = nil
  ) {
    _launchAction = launchAction
    self.onWeightEntrySaved = onWeightEntrySaved
    _viewModel = StateObject(
      wrappedValue: WeightHistoryViewModel(
        sessionStore: sessionStore,
        initialEntries: initialEntries,
        initialChartMetrics: initialChartMetrics,
        initialError: initialError,
        initialHasMoreEntries: initialHasMoreEntries,
        initialLoadedCountText: initialLoadedCountText
      )
    )
  }

  var body: some View {
    Group {
      if viewModel.isLoading && viewModel.entries.isEmpty {
        ScrollView {
          WeightHistorySkeletonView()
            .padding(.horizontal, 16)
            .padding(.vertical, 18)
        }
      } else if viewModel.entries.isEmpty {
        ScrollView {
          VStack(spacing: 20) {
            if let errorMessage = viewModel.errorMessage {
              WeightHistoryInlineErrorCard(
                message: errorMessage,
                canRetry: !viewModel.isLoading && !viewModel.isRefreshing,
                retry: { Task { await viewModel.refresh() } }
              )
            }

            WeightHistoryEmptyState {
              viewModel.showAddSheet = true
            }
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 18)
        }
      }
      else {
        List {
          if let errorMessage = viewModel.errorMessage {
            WeightHistoryInlineErrorCard(
              message: errorMessage,
              canRetry: !viewModel.isLoading && !viewModel.isRefreshing,
              retry: { Task { await viewModel.refresh() } }
            )
            .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }

          if viewModel.isRefreshing {
            HStack(spacing: 8) {
              ProgressView()
                .controlSize(.small)
              Text("Refreshing weight history...")
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(AppColors.textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
            .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 6, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }

          WeightHistoryTrendSection(
            summary: viewModel.summary,
            points: viewModel.chartPoints,
            weightUnitLabel: viewModel.weightUnitLabel
          )
          .listRowInsets(EdgeInsets(top: 12, leading: 16, bottom: 10, trailing: 16))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)

          HStack {
            Text("All Measurements")
              .font(.system(size: 30, weight: .bold))
              .foregroundStyle(AppColors.textPrimary)

            Spacer()

            Text(viewModel.loadedCountText)
              .font(.system(size: 15, weight: .bold))
              .foregroundStyle(AppColors.textSecondary)
          }
          .listRowInsets(EdgeInsets(top: 6, leading: 16, bottom: 8, trailing: 16))
          .listRowSeparator(.hidden)
          .listRowBackground(Color.clear)

          ForEach(viewModel.entries) { row in
            WeightHistoryRowCard(row: row)
              .swipeActions(edge: .leading, allowsFullSwipe: false) {
                Button {
                  presentEdit(for: row)
                } label: {
                  Label("Edit", systemImage: "pencil")
                }
                .tint(AppColors.infoBlue)
              }
              .swipeActions(edge: .trailing, allowsFullSwipe: false) {
                Button(role: .destructive) {
                  requestDelete(for: row)
                } label: {
                  Label("Delete", systemImage: "trash")
                }
              }
              .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 12, trailing: 16))
              .listRowSeparator(.hidden)
              .listRowBackground(Color.clear)
          }

          if viewModel.hasMoreEntries {
            Button {
              Task {
                await viewModel.loadMoreEntries()
              }
            } label: {
              HStack {
                if viewModel.isLoadingMore {
                  ProgressView()
                    .controlSize(.small)
                    .tint(AppColors.textSecondary)
                }
                Text(viewModel.isLoadingMore ? "Loading..." : "Load Previous Entries")
                  .font(.system(size: 16, weight: .semibold))
                  .foregroundStyle(AppColors.textPrimary)
              }
              .frame(maxWidth: .infinity)
              .frame(height: 56)
              .background(AppColors.surface)
              .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
              .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                  .stroke(AppColors.borderGray, style: StrokeStyle(lineWidth: 1, dash: [4, 4]))
              )
            }
            .buttonStyle(.plain)
            .disabled(viewModel.isLoadingMore)
            .listRowInsets(EdgeInsets(top: 4, leading: 16, bottom: 8, trailing: 16))
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
          }

          Color.clear
            .frame(height: 92)
            .listRowInsets(EdgeInsets())
            .listRowSeparator(.hidden)
            .listRowBackground(Color.clear)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
      }
    }
    .safeAreaInset(edge: .bottom) {
      Color.clear
        .frame(height: 100)
        .allowsHitTesting(false)
    }
    .background(AppColors.background.ignoresSafeArea())
    .navigationTitle("WEIGHT HISTORY")
    .navigationBarTitleDisplayMode(.inline)
    .toolbar {
      ToolbarItem(placement: .topBarTrailing) {
        Button {
          viewModel.showAddSheet = true
        } label: {
          Image(systemName: "plus")
            .font(.system(size: 18, weight: .semibold))
            .foregroundStyle(AppColors.accent)
        }
        .buttonStyle(.plain)
        .accessibilityLabel("Add weight entry")
      }
    }
    .task {
      await viewModel.loadInitial()
    }
    .onAppear {
      consumeLaunchActionIfNeeded()
    }
    .onChange(of: launchAction) { _, _ in
      consumeLaunchActionIfNeeded()
    }
    .refreshable {
      await viewModel.refresh()
    }
    .sheet(isPresented: $viewModel.showAddSheet) {
      WeightEntrySheet(
        weightUnitLabel: viewModel.weightUnitLabel,
        isSaving: viewModel.isSavingEntry,
        errorMessage: viewModel.addEntryErrorMessage,
        onCancel: {
          viewModel.showAddSheet = false
          viewModel.addEntryErrorMessage = nil
        },
        onSave: { inputText in
          let submittedText = String(inputText)
          Task {
            let didSave = await viewModel.saveWeightEntry(inputText: submittedText)
            if didSave {
              onWeightEntrySaved()
            }
          }
        }
      )
      .presentationDetents([.medium])
      .presentationDragIndicator(.visible)
    }
    .sheet(isPresented: $viewModel.showEditSheet) {
      if let editingEntry = viewModel.editingEntry {
        let entryID = editingEntry.id
        WeightEntrySheet(
          weightUnitLabel: viewModel.weightUnitLabel,
          isSaving: viewModel.isSavingEntry,
          errorMessage: viewModel.entryMutationErrorMessage,
          title: "Edit Weight",
          headlineText: "Update this weigh-in value",
          helperText: "Date stays unchanged for this entry.",
          saveButtonTitle: "Save Changes",
          initialWeightText: inputText(for: editingEntry.displayValue),
          onCancel: {
            viewModel.showEditSheet = false
            viewModel.editingEntry = nil
            viewModel.entryMutationErrorMessage = nil
          },
          onSave: { inputText in
            let submittedText = String(inputText)
            Task {
              let didSave = await viewModel.updateWeightEntry(id: entryID, inputText: submittedText)
              if didSave {
                onWeightEntrySaved()
              }
            }
          }
        )
        .id(editingEntry.id)
        .presentationDetents([.medium])
        .presentationDragIndicator(.visible)
      }
    }
    .confirmationDialog(
      "Delete this entry?",
      isPresented: Binding(
        get: { viewModel.pendingDeleteEntry != nil },
        set: { isPresented in
          if !isPresented {
            viewModel.pendingDeleteEntry = nil
          }
        }
      ),
      titleVisibility: .visible
    ) {
      Button("Delete Entry", role: .destructive) {
        guard let entry = viewModel.pendingDeleteEntry else { return }
        Task {
          let didDelete = await viewModel.deleteWeightEntry(id: entry.id)
          if didDelete {
            onWeightEntrySaved()
          } else if let mutationError = viewModel.entryMutationErrorMessage {
            deleteFailureMessage = mutationError
          }
        }
      }

      Button("Cancel", role: .cancel) {
        viewModel.pendingDeleteEntry = nil
      }
    } message: {
      if let entry = viewModel.pendingDeleteEntry {
        Text("This will permanently delete the entry from \(entry.dateText).")
      }
    }
    .alert(
      "Unable to delete entry",
      isPresented: Binding(
        get: { deleteFailureMessage != nil },
        set: { isPresented in
          if !isPresented {
            deleteFailureMessage = nil
          }
        }
      )
    ) {
      Button("OK", role: .cancel) {}
    } message: {
      Text(deleteFailureMessage ?? "Please try again.")
    }
  }

  private func consumeLaunchActionIfNeeded() {
    guard let launchAction else {
      return
    }

    switch launchAction {
    case .addEntry:
      viewModel.addEntryErrorMessage = nil
      viewModel.showAddSheet = true
    }

    self.launchAction = nil
  }

  private func presentEdit(for row: WeightHistoryEntryRow) {
    viewModel.entryMutationErrorMessage = nil
    viewModel.editingEntry = row
    viewModel.showEditSheet = true
  }

  private func requestDelete(for row: WeightHistoryEntryRow) {
    viewModel.entryMutationErrorMessage = nil
    viewModel.pendingDeleteEntry = row
  }

  private func inputText(for value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 2
    return formatter.string(from: NSNumber(value: value)) ?? String(format: "%.2f", value)
  }
}

private struct WeightHistoryTrendSection: View {
  let summary: WeightHistorySummaryData
  let points: [WeightHistoryChartPoint]
  let weightUnitLabel: String

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Body Weight Trend")
          .font(.system(size: 30, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        Spacer()

        Text("LAST 30 DAYS")
          .font(.system(size: 11, weight: .bold))
          .foregroundStyle(AppColors.textSecondary)
          .padding(.horizontal, 10)
          .padding(.vertical, 5)
          .background(Color(.systemGray6))
          .clipShape(Capsule())
      }

      VStack(spacing: 14) {
        WeightHistoryTrendChart(
          points: points,
          weightUnitLabel: weightUnitLabel
        )
        .frame(height: 220)

        HStack(spacing: 10) {
          WeightHistoryKpiCard(
            title: "CURRENT",
            valueText: summary.currentValueText,
            subtitle: summary.currentSubtitle,
            direction: .flat
          )

          WeightHistoryKpiCard(
            title: "NET CHANGE",
            valueText: summary.netChangeValueText,
            subtitle: summary.netChangeSubtitle,
            direction: summary.netChangeDirection
          )

          WeightHistoryKpiCard(
            title: "AVG/WEEK",
            valueText: summary.avgWeeklyValueText,
            subtitle: summary.avgWeeklySubtitle,
            direction: summary.avgWeeklyDirection
          )
        }
      }
      .padding(16)
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
    }
  }
}

private struct WeightHistoryTrendChart: View {
  let points: [WeightHistoryChartPoint]
  let weightUnitLabel: String

  private var latestPoint: WeightHistoryChartPoint? {
    points.last
  }

  private var chartValues: [Double] {
    points.map(\.value)
  }

  private var hasChartData: Bool {
    !points.isEmpty
  }

  private var xDomain: ClosedRange<Date> {
    let now = Date()
    let start =
      Calendar.current.date(byAdding: .day, value: -30, to: now)
      ?? now.addingTimeInterval(-30 * 86_400)
    return start...now
  }

  private var xAxisValues: [Date] {
    let start = xDomain.lowerBound
    let end = xDomain.upperBound
    let total = end.timeIntervalSince(start)
    let step = total / 5

    return (0...5).map { index in
      start.addingTimeInterval(Double(index) * step)
    }
  }

  private var yDomain: ClosedRange<Double> {
    guard let minValue = chartValues.min(), let maxValue = chartValues.max() else {
      return 0...1
    }

    if abs(maxValue - minValue) < 0.01 {
      let padding = max(maxValue * 0.04, 1.2)
      return (minValue - padding)...(maxValue + padding)
    }

    let padding = max((maxValue - minValue) * 0.14, 0.8)
    return (minValue - padding)...(maxValue + padding)
  }

  private var yAxisValues: [Double] {
    let lower = yDomain.lowerBound
    let upper = yDomain.upperBound
    let middle = (lower + upper) / 2
    return [lower, middle, upper]
  }

  var body: some View {
    Group {
      if hasChartData {
        chartView
      } else {
        VStack(spacing: 10) {
          Image(systemName: "scalemass")
            .font(.system(size: 24, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)

          Text("No entries in the last 30 days.")
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(Color(.systemGray6).opacity(0.35))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
      }
    }
  }

  private var chartView: some View {
    Chart {
      ForEach(points) { point in
        LineMark(
          x: .value("Date", point.date),
          y: .value("Weight", point.value)
        )
        .interpolationMethod(.catmullRom)
        .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
        .foregroundStyle(AppColors.accent)

        AreaMark(
          x: .value("Date", point.date),
          yStart: .value("Baseline", yDomain.lowerBound),
          yEnd: .value("Weight", point.value)
        )
        .foregroundStyle(
          LinearGradient(
            colors: [AppColors.accent.opacity(0.28), AppColors.accent.opacity(0.04)],
            startPoint: .top,
            endPoint: .bottom
          )
        )
      }

      if let latestPoint {
        PointMark(
          x: .value("Date", latestPoint.date),
          y: .value("Weight", latestPoint.value)
        )
        .symbolSize(80)
        .foregroundStyle(AppColors.accentStrong)
      }
    }
    .chartXScale(domain: xDomain)
    .chartYScale(domain: yDomain)
    .chartXAxis {
      AxisMarks(values: xAxisValues) { value in
        AxisValueLabel {
          if let date = value.as(Date.self) {
            Text(date, format: .dateTime.month(.abbreviated).day())
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(AppColors.textSecondary)
          }
        }
      }
    }
    .chartYAxis {
      AxisMarks(position: .leading, values: yAxisValues) { value in
        AxisGridLine(stroke: StrokeStyle(lineWidth: 0.9, dash: [3, 3]))
          .foregroundStyle(AppColors.borderGray.opacity(0.7))
        AxisTick(stroke: StrokeStyle(lineWidth: 0.8))
          .foregroundStyle(AppColors.borderGray)
        AxisValueLabel {
          if let yValue = value.as(Double.self) {
            Text("\(formattedWeight(yValue)) \(weightUnitLabel)")
              .font(.system(size: 10, weight: .semibold))
              .foregroundStyle(AppColors.textSecondary)
          }
        }
      }
    }
    .chartLegend(.hidden)
    .chartPlotStyle { plotArea in
      plotArea
        .background(Color.clear)
    }
    .overlay(alignment: .topTrailing) {
      if let latestPoint {
        Text("\(formattedWeight(latestPoint.value)) \(weightUnitLabel)")
          .font(.system(size: 10, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary)
          .padding(.horizontal, 8)
          .padding(.vertical, 4)
          .background(AppColors.surface.opacity(0.96))
          .clipShape(Capsule())
          .overlay(
            Capsule()
              .stroke(AppColors.borderGray, lineWidth: 1)
          )
      }
    }
  }

  private func formattedWeight(_ value: Double) -> String {
    let formatter = NumberFormatter()
    formatter.numberStyle = .decimal
    formatter.minimumFractionDigits = 0
    formatter.maximumFractionDigits = 1

    if let result = formatter.string(from: NSNumber(value: value)) {
      return result
    }

    return String(format: "%.1f", value)
  }
}

private struct WeightHistoryKpiCard: View {
  let title: String
  let valueText: String
  let subtitle: String
  let direction: WeightHistoryDeltaDirection

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Text(title)
        .font(.system(size: 10, weight: .bold))
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(1)

      Text(valueText)
        .font(.system(size: 25, weight: .bold))
        .foregroundStyle(valueColor(for: direction))
        .minimumScaleFactor(0.72)
        .lineLimit(1)
        .monospacedDigit()

      Text(subtitle)
        .font(.system(size: 11))
        .foregroundStyle(AppColors.textSecondary)
        .lineLimit(2)
        .multilineTextAlignment(.leading)
    }
    .padding(.horizontal, 10)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .frame(minHeight: 110, alignment: .topLeading)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }

  private func valueColor(for direction: WeightHistoryDeltaDirection) -> Color {
    switch direction {
    case .up:
      return AppColors.errorRed
    case .down:
      return AppColors.successGreen
    case .flat:
      return AppColors.textPrimary
    }
  }
}

private struct WeightHistoryRowCard: View {
  let row: WeightHistoryEntryRow

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: "calendar")
        .font(.system(size: 16, weight: .semibold))
        .foregroundStyle(AppColors.textPrimary)
        .frame(width: 32, height: 32)
        .background(Color(.systemGray6))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 2) {
        Text(row.dateText)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        Text(row.entryPeriodText)
          .font(.system(size: 15))
          .foregroundStyle(AppColors.textSecondary)
      }

      Spacer()

      VStack(alignment: .trailing, spacing: 8) {
        Text(row.valueText)
          .font(.system(size: 22, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)
          .monospacedDigit()

        HStack(spacing: 4) {
          Image(systemName: deltaSymbol(for: row.deltaDirection))
            .font(.system(size: 10, weight: .bold))

          Text(row.deltaText)
            .font(.system(size: 12, weight: .bold))
            .monospacedDigit()
        }
        .foregroundStyle(deltaTextColor(for: row.deltaDirection))
        .padding(.horizontal, 8)
        .padding(.vertical, 5)
        .background(deltaBackgroundColor(for: row.deltaDirection))
        .clipShape(Capsule())
        .overlay(
          Capsule()
            .stroke(deltaBorderColor(for: row.deltaDirection), lineWidth: 1)
        )
      }
    }
    .padding(.horizontal, 14)
    .padding(.vertical, 12)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
  }

  private func deltaSymbol(for direction: WeightHistoryDeltaDirection) -> String {
    switch direction {
    case .up:
      return "arrow.up.right"
    case .down:
      return "arrow.down.right"
    case .flat:
      return "minus"
    }
  }

  private func deltaTextColor(for direction: WeightHistoryDeltaDirection) -> Color {
    switch direction {
    case .up:
      return AppColors.errorRed
    case .down:
      return AppColors.successGreen
    case .flat:
      return AppColors.textSecondary
    }
  }

  private func deltaBackgroundColor(for direction: WeightHistoryDeltaDirection) -> Color {
    switch direction {
    case .up:
      return AppColors.errorRed.opacity(0.12)
    case .down:
      return AppColors.successGreen.opacity(0.12)
    case .flat:
      return Color(.systemGray6)
    }
  }

  private func deltaBorderColor(for direction: WeightHistoryDeltaDirection) -> Color {
    switch direction {
    case .up:
      return AppColors.errorRed.opacity(0.3)
    case .down:
      return AppColors.successGreen.opacity(0.3)
    case .flat:
      return AppColors.borderGray
    }
  }
}

private struct WeightEntrySheet: View {
  let weightUnitLabel: String
  let isSaving: Bool
  let errorMessage: String?
  let title: String
  let headlineText: String
  let helperText: String?
  let saveButtonTitle: String
  let onCancel: () -> Void
  let onSave: (String) -> Void

  @State private var weightText = ""

  init(
    weightUnitLabel: String,
    isSaving: Bool,
    errorMessage: String?,
    title: String = "Add Weight",
    headlineText: String = "Add a new weigh-in",
    helperText: String? = "Saved as a current-time entry.",
    saveButtonTitle: String = "Save Entry",
    initialWeightText: String = "",
    onCancel: @escaping () -> Void,
    onSave: @escaping (String) -> Void
  ) {
    self.weightUnitLabel = weightUnitLabel
    self.isSaving = isSaving
    self.errorMessage = errorMessage
    self.title = title
    self.headlineText = headlineText
    self.helperText = helperText
    self.saveButtonTitle = saveButtonTitle
    self.onCancel = onCancel
    self.onSave = onSave
    _weightText = State(initialValue: initialWeightText)
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 16) {
        Text(headlineText)
          .font(.system(size: 20, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        HStack(spacing: 10) {
          Image(systemName: "scalemass.fill")
            .foregroundStyle(AppColors.textSecondary)

          TextField("e.g. 81.4", text: $weightText)
            .keyboardType(.decimalPad)
            .textInputAutocapitalization(.never)
            .disableAutocorrection(true)

          Text(weightUnitLabel)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.textSecondary)
        }
        .font(.system(size: 16, weight: .semibold))
        .padding(.horizontal, 12)
        .frame(height: 48)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))

        if let helperText {
          Text(helperText)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
        }

        if let errorMessage {
          Text(errorMessage)
            .font(.system(size: 13, weight: .semibold))
            .foregroundStyle(AppColors.errorRed)
        }

        Spacer()

        Button {
          let submittedText = String(weightText)
          onSave(submittedText)
        } label: {
          HStack {
            if isSaving {
              ProgressView()
                .controlSize(.small)
                .tint(.white)
            }
            Text(isSaving ? "Saving..." : saveButtonTitle)
              .font(.system(size: 16, weight: .bold))
          }
          .foregroundStyle(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 52)
          .background(AppColors.accent)
          .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
        }
        .buttonStyle(.plain)
        .disabled(isSaving || weightText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
      }
      .padding(16)
      .navigationTitle(title)
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarLeading) {
          Button("Cancel") {
            onCancel()
          }
          .disabled(isSaving)
        }
      }
    }
  }
}

private struct WeightHistoryInlineErrorCard: View {
  let message: String
  let canRetry: Bool
  let retry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(AppColors.errorRed)
        Text("Unable to refresh weight history")
          .font(.system(size: 15, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)
      }

      Text(message)
        .font(.system(size: 14))
        .foregroundStyle(AppColors.textSecondary)

      if canRetry {
        Button("Retry", action: retry)
          .font(.system(size: 14, weight: .semibold))
          .buttonStyle(.bordered)
          .tint(AppColors.accent)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding(16)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 14, style: .continuous)
        .stroke(AppColors.errorRed.opacity(0.25), lineWidth: 1)
    )
  }
}

private struct WeightHistoryEmptyState: View {
  let onAddTap: () -> Void

  var body: some View {
    VStack(spacing: 14) {
      Image(systemName: "scalemass")
        .font(.system(size: 40, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)

      Text("No weight entries yet")
        .font(.system(size: 22, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)

      Text("Add your first weigh-in to start tracking your 30-day trend.")
        .font(.system(size: 14))
        .foregroundStyle(AppColors.textSecondary)
        .multilineTextAlignment(.center)

      Button("Add First Weigh-In", action: onAddTap)
        .font(.system(size: 15, weight: .bold))
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 40)
    .padding(.horizontal, 16)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
  }
}

private struct WeightHistorySkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 18) {
      RoundedRectangle(cornerRadius: 18)
        .fill(Color(.systemGray6))
        .frame(height: 340)

      HStack(spacing: 10) {
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemGray6))
          .frame(height: 110)
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemGray6))
          .frame(height: 110)
        RoundedRectangle(cornerRadius: 12)
          .fill(Color(.systemGray6))
          .frame(height: 110)
      }

      ForEach(0..<5, id: \.self) { _ in
        RoundedRectangle(cornerRadius: 14)
          .fill(Color(.systemGray6))
          .frame(height: 96)
      }
    }
    .redacted(reason: .placeholder)
  }
}

#Preview("Weight History Full") {
  NavigationStack {
    WeightHistoryView(
      sessionStore: MockData.mockSessionStore(),
      initialEntries: MockData.weightHistoryEntriesFull,
      initialChartMetrics: MockData.weightHistoryChartMetricsFull,
      initialHasMoreEntries: true,
      initialLoadedCountText: "\(MockData.weightHistoryEntriesFull.count) Loaded"
    )
  }
}

#Preview("Weight History Sparse") {
  NavigationStack {
    WeightHistoryView(
      sessionStore: MockData.mockSessionStore(),
      initialEntries: MockData.weightHistoryEntriesSparse,
      initialChartMetrics: MockData.weightHistoryChartMetricsSparse,
      initialHasMoreEntries: false,
      initialLoadedCountText: "\(MockData.weightHistoryEntriesSparse.count) Loaded"
    )
  }
}

#Preview("Weight History Empty") {
  NavigationStack {
    WeightHistoryView(
      sessionStore: MockData.mockSessionStore(),
      initialEntries: [],
      initialChartMetrics: [],
      initialHasMoreEntries: false,
      initialLoadedCountText: "0 Loaded"
    )
  }
}
