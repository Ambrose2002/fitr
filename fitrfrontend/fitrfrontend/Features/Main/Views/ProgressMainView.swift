//
//  ProgressMainView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Charts
import SwiftUI

enum ProgressLaunchAction: Equatable {
  case logWeight
}

private enum ProgressRoute: Hashable {
  case weightHistory
}

struct ProgressMainView: View {
  @Binding private var launchAction: ProgressLaunchAction?
  @ObservedObject private var viewModel: ProgressViewModel
  private let sessionStore: SessionStore
  private let onSeeFullHistoryTap: () -> Void
  private let onWeightEntrySaved: () -> Void
  @State private var navigationPath: [ProgressRoute] = []
  @State private var pendingWeightHistoryLaunchAction: WeightHistoryLaunchAction?

  init(
    sessionStore: SessionStore,
    viewModel: ProgressViewModel? = nil,
    launchAction: Binding<ProgressLaunchAction?> = .constant(nil),
    onSeeFullHistoryTap: @escaping () -> Void = {},
    onWeightEntrySaved: @escaping () -> Void = {},
    initialDashboard: ProgressDashboardData? = nil,
    initialError: String? = nil
  ) {
    _launchAction = launchAction
    self.sessionStore = sessionStore
    self.onSeeFullHistoryTap = onSeeFullHistoryTap
    self.onWeightEntrySaved = onWeightEntrySaved
    let resolvedViewModel = viewModel ?? ProgressViewModel(
        sessionStore: sessionStore,
        initialDashboard: initialDashboard,
        initialError: initialError
    )
    _viewModel = ObservedObject(wrappedValue: resolvedViewModel)
  }

  var body: some View {
    NavigationStack(path: $navigationPath) {
      ScrollView {
        VStack(spacing: 24) {
          if let errorMessage = viewModel.errorMessage {
            ProgressInlineErrorCard(
              message: errorMessage,
              canRetry: !(viewModel.isLoading || viewModel.isRefreshing),
              retry: { Task { await viewModel.refresh() } }
            )
          }

          if let dashboard = viewModel.dashboard {
            ProgressDashboardContent(
              dashboard: dashboard,
              isRefreshing: viewModel.isLoading || viewModel.isRefreshing,
              onOpenWeightHistory: {
                openWeightHistory()
              },
              onSeeFullHistoryTap: onSeeFullHistoryTap
            )
          } else if viewModel.isLoading {
            ProgressSkeletonView()
          } else {
            ProgressUnavailableState(
              retry: { Task { await viewModel.refresh() } }
            )
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 20)
      }
      .safeAreaInset(edge: .bottom) {
        Color.clear
          .frame(height: 100)
          .allowsHitTesting(false)
      }
      .background(AppColors.background.ignoresSafeArea())
      .navigationTitle("PROGRESS")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if viewModel.isLoading || viewModel.isRefreshing {
            ProgressView()
              .controlSize(.small)
          } else {
            Button {
              Task {
                await viewModel.refresh()
              }
            } label: {
              Image(systemName: "arrow.clockwise")
                .font(.system(size: 15, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
            }
            .buttonStyle(.plain)
            .accessibilityLabel("Refresh progress")
          }
        }
      }
      .refreshable {
        await viewModel.refresh()
      }
      .navigationDestination(for: ProgressRoute.self) { route in
        switch route {
        case .weightHistory:
          WeightHistoryView(
            sessionStore: sessionStore,
            launchAction: $pendingWeightHistoryLaunchAction,
            onWeightEntrySaved: handleWeightEntrySaved
          )
        }
      }
      .onAppear {
        consumeLaunchActionIfNeeded()
      }
      .onChange(of: launchAction) { _, _ in
        consumeLaunchActionIfNeeded()
      }
    }
  }

  private func consumeLaunchActionIfNeeded() {
    guard let launchAction else {
      return
    }

    switch launchAction {
    case .logWeight:
      openWeightHistory(launchAction: .addEntry)
    }

    self.launchAction = nil
  }

  private func openWeightHistory(launchAction: WeightHistoryLaunchAction? = nil) {
    pendingWeightHistoryLaunchAction = launchAction

    guard navigationPath.last != .weightHistory else {
      return
    }

    navigationPath.append(.weightHistory)
  }

  private func handleWeightEntrySaved() {
    onWeightEntrySaved()
    Task {
      await viewModel.refresh()
    }
  }
}

private struct ProgressDashboardContent: View {
  let dashboard: ProgressDashboardData
  let isRefreshing: Bool
  let onOpenWeightHistory: () -> Void
  let onSeeFullHistoryTap: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      BodyCompositionSection(
        data: dashboard.bodyComposition,
        onOpenWeightHistory: onOpenWeightHistory
      )
      WorkoutSummarySection(stats: dashboard.workoutSummary)
      MonthlyTrendsSection(
        points: dashboard.monthlyTrendPoints,
        insight: dashboard.monthlyInsight
      )

      Button {
        onSeeFullHistoryTap()
      } label: {
        HStack(spacing: 8) {
          Text(isRefreshing ? "Refreshing..." : "See Full History")
            .font(.system(size: 18, weight: .bold))
          Image(systemName: "chevron.right")
            .font(.system(size: 14, weight: .bold))
        }
        .foregroundStyle(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 56)
        .background(AppColors.accent)
        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
        .shadow(color: AppColors.accent.opacity(0.22), radius: 10, x: 0, y: 6)
      }
      .buttonStyle(.plain)
      .disabled(isRefreshing)
      .padding(.top, 4)
    }
  }
}

private struct BodyCompositionSection: View {
  let data: ProgressDashboardData.BodyCompositionData
  let onOpenWeightHistory: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack {
        Text("Body Composition")
          .font(.system(size: 28, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        Spacer()

        Text(data.weightBadgeText)
          .font(.system(size: 12, weight: .semibold))
          .foregroundStyle(AppColors.accent)
          .padding(.horizontal, 10)
          .padding(.vertical, 6)
          .background(AppColors.accent.opacity(0.12))
          .clipShape(Capsule())
      }

      Button {
        onOpenWeightHistory()
      } label: {
        VStack(alignment: .leading, spacing: 14) {
          if let weightDisplayText = data.weightDisplayText {
            Text(weightDisplayText)
              .font(.system(size: 42, weight: .bold))
              .foregroundStyle(AppColors.textPrimary)
              .monospacedDigit()
          } else {
            Text("No weight data")
              .font(.system(size: 24, weight: .bold))
              .foregroundStyle(AppColors.textPrimary)
          }

          if let weightDeltaText = data.weightDeltaText,
            let weightDeltaDirection = data.weightDeltaDirection
          {
            HStack(spacing: 8) {
              Image(systemName: deltaSymbol(for: weightDeltaDirection))
                .font(.system(size: 12, weight: .bold))
                .foregroundStyle(deltaColor(for: weightDeltaDirection))

              Text(weightDeltaText)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.textPrimary)
                .monospacedDigit()

              Text(data.weightDeltaDescription)
                .font(.system(size: 14))
                .foregroundStyle(AppColors.textSecondary)
            }
          } else {
            Text(data.weightDeltaDescription)
              .font(.system(size: 14))
              .foregroundStyle(AppColors.textSecondary)
          }

          if let bodyEmptyMessage = data.bodyEmptyMessage {
            Text(bodyEmptyMessage)
              .font(.system(size: 14))
              .foregroundStyle(AppColors.textSecondary)
              .padding(.top, 4)
          }

          WeightTrendChart(
            points: data.weightPoints,
            weightUnitLabel: data.weightUnitLabel
          )
          .frame(height: 170)

          Text("Last 30 days")
            .font(.system(size: 12, weight: .medium))
            .foregroundStyle(AppColors.textSecondary)
        }
        .padding(18)
        .background(AppColors.surface)
        .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
        .overlay(
          RoundedRectangle(cornerRadius: 18, style: .continuous)
            .stroke(AppColors.borderGray, lineWidth: 1)
        )
      }
      .buttonStyle(.plain)
      .accessibilityLabel("Open weight history")

      HStack(spacing: 12) {
        ProgressMetricCard(
          title: "CURRENT HEIGHT",
          valueText: data.currentHeightDisplayText,
          iconName: "ruler.fill",
          iconTint: AppColors.infoBlue
        )

        ProgressMetricCard(
          title: "CURRENT WEIGHT",
          valueText: data.currentWeightStatDisplayText,
          iconName: "scalemass.fill",
          iconTint: AppColors.accent
        )
      }
    }
  }

  private func deltaSymbol(for direction: ProgressDeltaDirection) -> String {
    switch direction {
    case .down:
      return "arrow.down.right"
    case .up:
      return "arrow.up.right"
    case .flat:
      return "arrow.right"
    }
  }

  private func deltaColor(for direction: ProgressDeltaDirection) -> Color {
    switch direction {
    case .down:
      return AppColors.successGreen
    case .up:
      return AppColors.errorRed
    case .flat:
      return AppColors.textSecondary
    }
  }
}

private struct WeightTrendChart: View {
  let points: [ProgressWeightPoint]
  let weightUnitLabel: String

  private var orderedPoints: [ProgressWeightPoint] {
    points.sorted { $0.date < $1.date }
  }

  private var plottedValues: [Double] {
    orderedPoints.map(\.value)
  }

  private var hasChartData: Bool {
    !orderedPoints.isEmpty
  }

  private var latestPlottedPoint: ProgressWeightPoint? {
    orderedPoints.last
  }

  private var yDomain: ClosedRange<Double> {
    guard let minimumValue = plottedValues.min(), let maximumValue = plottedValues.max() else {
      return 0...1
    }

    if abs(maximumValue - minimumValue) < 0.01 {
      let padding = max(maximumValue * 0.04, 1.5)
      return (minimumValue - padding)...(maximumValue + padding)
    }

    let padding = max((maximumValue - minimumValue) * 0.18, 0.8)
    return (minimumValue - padding)...(maximumValue + padding)
  }

  private var yAxisValues: [Double] {
    let lower = yDomain.lowerBound
    let upper = yDomain.upperBound
    let middle = (lower + upper) / 2
    return [lower, middle, upper]
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
      ForEach(orderedPoints) { point in
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

      if let latestPlottedPoint {
        PointMark(
          x: .value("Date", latestPlottedPoint.date),
          y: .value("Weight", latestPlottedPoint.value)
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
          if let rawValue = value.as(Double.self) {
            Text("\(formattedWeight(rawValue)) \(weightUnitLabel)")
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
      if let latestPlottedPoint {
        Text("\(formattedWeight(latestPlottedPoint.value)) \(weightUnitLabel)")
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

    if let formatted = formatter.string(from: NSNumber(value: value)) {
      return formatted
    }

    return String(format: "%.1f", value)
  }
}

private struct ProgressMetricCard: View {
  let title: String
  let valueText: String
  let iconName: String
  let iconTint: Color

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Image(systemName: iconName)
        .font(.system(size: 15, weight: .semibold))
        .foregroundStyle(iconTint)
        .frame(width: 34, height: 34)
        .background(iconTint.opacity(0.12))
        .clipShape(Circle())

      Spacer(minLength: 0)

      Text(title)
        .font(.system(size: 12, weight: .bold))
        .foregroundStyle(AppColors.textSecondary)

      Text(valueText)
        .font(.system(size: 24, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)
        .minimumScaleFactor(0.75)
    }
    .padding(16)
    .frame(maxWidth: .infinity, minHeight: 124, alignment: .topLeading)
    .background(AppColors.surface)
    .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
    .overlay(
      RoundedRectangle(cornerRadius: 16, style: .continuous)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
  }
}

private struct WorkoutSummarySection: View {
  let stats: [ProgressSummaryStat]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Workout Summary")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)

      VStack(spacing: 0) {
        ForEach(Array(stats.enumerated()), id: \.element.id) { index, stat in
          WorkoutSummaryRow(stat: stat)

          if index < stats.count - 1 {
            Divider()
              .padding(.leading, 58)
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
}

private struct WorkoutSummaryRow: View {
  let stat: ProgressSummaryStat

  var body: some View {
    HStack(spacing: 12) {
      Image(systemName: stat.systemImage)
        .font(.system(size: 14, weight: .semibold))
        .foregroundStyle(AppColors.textPrimary)
        .frame(width: 30, height: 30)
        .background(Color(.systemGray6))
        .clipShape(Circle())

      VStack(alignment: .leading, spacing: 2) {
        Text(stat.title)
          .font(.system(size: 16, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        if let subtitle = stat.subtitle {
          Text(subtitle)
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
        }
      }

      Spacer()

      Text(stat.valueText)
        .font(.system(size: 20, weight: .bold))
        .foregroundStyle(stat.isValueAccent ? AppColors.accent : AppColors.textPrimary)
        .monospacedDigit()
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 14)
  }
}

private struct MonthlyTrendSelectionSummaryData {
  let title: String
  let subtitle: String
  let metrics: [ProgressSummaryStat]
  let footerMessage: String
  let hasSessions: Bool
}

private struct MonthlyTrendsSection: View {

  let points: [ProgressMonthlyTrendPoint]
  let insight: String
  @State private var selectedMonthStarts: Set<Date> = []

  private var orderedPoints: [ProgressMonthlyTrendPoint] {
    points.sorted { $0.monthStart < $1.monthStart }
  }

  private var visibleMonthStarts: Set<Date> {
    Set(orderedPoints.map(\.monthStart))
  }

  private var activePoints: [ProgressMonthlyTrendPoint] {
    guard !selectedMonthStarts.isEmpty else {
      return orderedPoints
    }

    return orderedPoints.filter { selectedMonthStarts.contains($0.monthStart) }
  }

  private var chartMaximumValue: Double {
    let maxSessionCount = Double(orderedPoints.map(\.sessionCount).max() ?? 0)
    let maxNormalizedVolume = orderedPoints.map(\.normalizedVolume).max() ?? 0
    return max(maxSessionCount, maxNormalizedVolume, 1)
  }

  private var chartYUpperBound: Int {
    let scaledValue = Int(ceil(chartMaximumValue * 1.2))
    return max(scaledValue, 1)
  }

  private var chartYDomain: ClosedRange<Double> {
    0...Double(chartYUpperBound)
  }

  private var chartYAxisValues: [Double] {
    let midpoint = Double(max(1, Int(round(Double(chartYUpperBound) / 2.0))))
    return Array(Set([0, midpoint, Double(chartYUpperBound)])).sorted()
  }

  private var selectionSummary: MonthlyTrendSelectionSummaryData {
    let scopedPoints = activePoints
    let totalSessions = scopedPoints.reduce(0) { $0 + $1.sessionCount }
    let totalDurationMinutes = scopedPoints.reduce(0) { $0 + $1.totalDurationMinutes }
    let averageSessionMinutes =
      totalSessions > 0
      ? Int((Double(totalDurationMinutes) / Double(totalSessions)).rounded())
      : 0
    let totalVolume = scopedPoints.reduce(0.0) { $0 + $1.totalVolume }
    let totalCalories = scopedPoints.reduce(0.0) { $0 + $1.totalCalories }
    let distinctExercises = Set(scopedPoints.flatMap(\.distinctExerciseIDs)).count

    let title: String
    let subtitle: String
    let footerMessage: String

    if selectedMonthStarts.isEmpty {
      title = "Last 6 Months"
      subtitle = "Combined summary for all visible months"
      footerMessage = insight
    } else if scopedPoints.count == 1, let point = scopedPoints.first {
      title = point.monthStart.formatted(.dateTime.month(.wide).year())
      subtitle = "Tap the highlighted bar again to clear"
      footerMessage = "Tap a highlighted bar again to deselect."
    } else {
      title = "\(scopedPoints.count) Months Selected"
      subtitle = scopedPoints.map(\.monthLabel).joined(separator: ", ")
      footerMessage = "Tap a highlighted bar again to deselect."
    }

    return MonthlyTrendSelectionSummaryData(
      title: title,
      subtitle: subtitle,
      metrics: [
        ProgressSummaryStat(
          id: "selected-sessions",
          title: "Sessions",
          subtitle: nil,
          valueText: "\(totalSessions)",
          systemImage: "calendar",
          isValueAccent: false
        ),
        ProgressSummaryStat(
          id: "selected-total-time",
          title: "Total Time",
          subtitle: nil,
          valueText: Self.formattedDuration(totalDurationMinutes),
          systemImage: "timer",
          isValueAccent: false
        ),
        ProgressSummaryStat(
          id: "selected-average-session",
          title: "Avg Session",
          subtitle: nil,
          valueText: Self.formattedDuration(averageSessionMinutes),
          systemImage: "clock",
          isValueAccent: false
        ),
        ProgressSummaryStat(
          id: "selected-volume",
          title: "Volume",
          subtitle: nil,
          valueText: formattedVolume(totalVolume),
          systemImage: "bolt.fill",
          isValueAccent: false
        ),
        ProgressSummaryStat(
          id: "selected-calories",
          title: "Calories",
          subtitle: nil,
          valueText: Self.formattedCalories(totalCalories),
          systemImage: "flame.fill",
          isValueAccent: false
        ),
        ProgressSummaryStat(
          id: "selected-exercises",
          title: "Exercises",
          subtitle: nil,
          valueText: "\(distinctExercises)",
          systemImage: "figure.strengthtraining.traditional",
          isValueAccent: false
        ),
      ],
      footerMessage: footerMessage,
      hasSessions: totalSessions > 0
    )
  }

  var body: some View {
    let summary = selectionSummary

    VStack(alignment: .leading, spacing: 14) {
      Text("Monthly Trends")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)

      VStack(alignment: .leading, spacing: 16) {
        chartLegend

        Chart {
          ForEach(orderedPoints) { point in
            BarMark(
              x: .value("Month", point.monthStart),
              y: .value("Sessions", point.sessionCount)
            )
            .foregroundStyle(
              selectedMonthStarts.contains(point.monthStart)
                ? AppColors.accentStrong
                : AppColors.accent.opacity(0.42)
            )

            LineMark(
              x: .value("Month", point.monthStart),
              y: .value("Normalized Volume", point.normalizedVolume)
            )
            .interpolationMethod(.linear)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .foregroundStyle(AppColors.textPrimary)

            PointMark(
              x: .value("Month", point.monthStart),
              y: .value("Normalized Volume", point.normalizedVolume)
            )
            .symbolSize(28)
            .foregroundStyle(AppColors.textPrimary)
          }
        }
        .frame(height: 180)
        .chartYScale(domain: chartYDomain)
        .chartLegend(.hidden)
        .chartXAxis {
          AxisMarks(values: orderedPoints.map(\.monthStart)) { value in
            AxisValueLabel {
              if let monthStart = value.as(Date.self) {
                Text(monthStart, format: .dateTime.month(.abbreviated))
                  .font(.system(size: 11, weight: .semibold))
                  .foregroundStyle(AppColors.textSecondary)
              }
            }
          }
        }
        .chartYAxis {
          AxisMarks(position: .leading, values: chartYAxisValues) { value in
            AxisGridLine(stroke: StrokeStyle(lineWidth: 0.8, dash: [3, 3]))
              .foregroundStyle(AppColors.borderGray.opacity(0.55))
            AxisTick(stroke: StrokeStyle(lineWidth: 0.8))
              .foregroundStyle(AppColors.borderGray.opacity(0.85))
            AxisValueLabel {
              if let rawValue = value.as(Double.self) {
                Text("\(Int(rawValue.rounded()))")
                  .font(.system(size: 10, weight: .semibold))
                  .foregroundStyle(AppColors.textSecondary)
              }
            }
          }
        }
        .chartPlotStyle { plotArea in
          plotArea
            .padding(.horizontal, 4)
            .background(Color.clear)
        }
        .chartOverlay { proxy in
          GeometryReader { geometry in
            Rectangle()
              .fill(Color.clear)
              .contentShape(Rectangle())
              .gesture(
                SpatialTapGesture()
                  .onEnded { value in
                    handleChartTap(at: value.location, proxy: proxy, geometry: geometry)
                  }
              )
          }
        }
        .onChange(of: orderedPoints.map(\.monthStart)) { _, newValue in
          selectedMonthStarts.formIntersection(Set(newValue))
        }

        MonthlyTrendSelectionSummaryView(summary: summary)

        if !summary.hasSessions {
          Text("No completed workouts in the selected month range.")
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
        }

        Text(summary.footerMessage)
          .font(.system(size: 14, weight: .semibold))
          .foregroundStyle(AppColors.textPrimary)
      }
      .padding(18)
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 16, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )
    }
  }

  private var chartLegend: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 8) {
        RoundedRectangle(cornerRadius: 2, style: .continuous)
          .fill(AppColors.accent.opacity(0.42))
          .frame(width: 12, height: 12)

        Text("Sessions (bars)")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(AppColors.textSecondary)
      }

      HStack(spacing: 8) {
        Capsule()
          .fill(AppColors.textPrimary)
          .frame(width: 16, height: 3)
          .overlay(alignment: .trailing) {
            Circle()
              .fill(AppColors.textPrimary)
              .frame(width: 5, height: 5)
          }

        Text("Volume trend (normalized line)")
          .font(.system(size: 11, weight: .semibold))
          .foregroundStyle(AppColors.textSecondary)
      }
    }
  }

  private func handleChartTap(
    at location: CGPoint,
    proxy: ChartProxy,
    geometry: GeometryProxy
  ) {
    guard let plotFrame = proxy.plotFrame else {
      return
    }

    let plotAreaFrame = geometry[plotFrame]
    guard plotAreaFrame.contains(location) else {
      return
    }

    guard
      let nearestMonth = orderedPoints
        .compactMap({ point -> (Date, CGFloat)? in
          guard let xPosition = proxy.position(forX: point.monthStart) else {
            return nil
          }

          return (point.monthStart, plotAreaFrame.origin.x + xPosition)
        })
        .min(by: { lhs, rhs in
          abs(lhs.1 - location.x) < abs(rhs.1 - location.x)
        })?
        .0
    else {
      return
    }

    if selectedMonthStarts.contains(nearestMonth) {
      selectedMonthStarts.remove(nearestMonth)
    } else if visibleMonthStarts.contains(nearestMonth) {
      selectedMonthStarts.insert(nearestMonth)
    }
  }

  private func formattedVolume(_ value: Double) -> String {
    let unitLabel =
      orderedPoints.first?.totalVolumeText
      .split(separator: " ")
      .last
      .map(String.init)
      ?? "kg"

    guard value > 0 else {
      return "0 \(unitLabel)"
    }

    if value >= 1000 {
      return String(format: "%.1f K %@", value / 1000, unitLabel)
    }

    return "\(Self.formattedNumber(value, maximumFractionDigits: 0)) \(unitLabel)"
  }

  private static func formattedCalories(_ value: Double) -> String {
    "\(formattedNumber(max(value, 0), maximumFractionDigits: 0)) cal"
  }

  private static func formattedDuration(_ minutes: Int) -> String {
    guard minutes > 0 else {
      return "0m"
    }

    let hours = minutes / 60
    let remainingMinutes = minutes % 60

    if hours == 0 {
      return "\(minutes)m"
    }

    if remainingMinutes == 0 {
      return "\(hours)h"
    }

    return "\(hours)h \(remainingMinutes)m"
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
}

private struct MonthlyTrendSelectionSummaryView: View {
  let summary: MonthlyTrendSelectionSummaryData

  private let columns = [
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
    GridItem(.flexible(), spacing: 10),
  ]

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      VStack(alignment: .leading, spacing: 4) {
        Text(summary.title)
          .font(.system(size: 18, weight: .bold))
          .foregroundStyle(AppColors.textPrimary)

        Text(summary.subtitle)
          .font(.system(size: 13))
          .foregroundStyle(AppColors.textSecondary)
      }

      LazyVGrid(columns: columns, spacing: 10) {
        ForEach(summary.metrics) { stat in
          TrendSummaryMetricCard(stat: stat)
        }
      }
    }
  }
}

private struct TrendSummaryMetricCard: View {
  let stat: ProgressSummaryStat

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      HStack(spacing: 6) {
        Image(systemName: stat.systemImage)
          .font(.system(size: 11, weight: .semibold))
        Text(stat.title.uppercased())
          .font(.system(size: 10, weight: .bold))
      }
      .foregroundStyle(AppColors.textSecondary)

      Text(stat.valueText)
        .font(.system(size: 15, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)
        .minimumScaleFactor(0.7)
        .lineLimit(1)
    }
    .padding(.horizontal, 12)
    .padding(.vertical, 10)
    .frame(maxWidth: .infinity, alignment: .leading)
    .background(Color(.systemGray6))
    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
  }
}

private struct ProgressInlineErrorCard: View {
  let message: String
  let canRetry: Bool
  let retry: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(spacing: 8) {
        Image(systemName: "exclamationmark.triangle.fill")
          .foregroundStyle(AppColors.errorRed)
        Text("Unable to refresh progress")
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

private struct ProgressUnavailableState: View {
  let retry: () -> Void

  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "chart.xyaxis.line")
        .font(.system(size: 42, weight: .semibold))
        .foregroundStyle(AppColors.textSecondary)

      Text("Progress data is unavailable right now.")
        .font(.system(size: 18, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)

      Button("Try Again", action: retry)
        .buttonStyle(.borderedProminent)
        .tint(AppColors.accent)
    }
    .frame(maxWidth: .infinity)
    .padding(.vertical, 48)
  }
}

private struct ProgressSkeletonView: View {
  var body: some View {
    VStack(alignment: .leading, spacing: 24) {
      RoundedRectangle(cornerRadius: 8)
        .fill(Color(.systemGray5))
        .frame(width: 220, height: 28)

      RoundedRectangle(cornerRadius: 18)
        .fill(Color(.systemGray6))
        .frame(height: 280)

      HStack(spacing: 12) {
        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemGray6))
          .frame(height: 124)

        RoundedRectangle(cornerRadius: 16)
          .fill(Color(.systemGray6))
          .frame(height: 124)
      }

      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6))
        .frame(height: 210)

      RoundedRectangle(cornerRadius: 16)
        .fill(Color(.systemGray6))
        .frame(height: 300)

      RoundedRectangle(cornerRadius: 14)
        .fill(Color(.systemGray5))
        .frame(height: 56)
    }
    .redacted(reason: .placeholder)
  }
}

#Preview("Progress Dashboard") {
  ProgressMainView(
    sessionStore: MockData.mockSessionStore(),
    initialDashboard: MockData.progressDashboardFull
  )
}

#Preview("Progress Empty Workouts") {
  ProgressMainView(
    sessionStore: MockData.mockSessionStore(),
    initialDashboard: MockData.progressDashboardNoWorkouts
  )
}

#Preview("Progress No Metrics") {
  ProgressMainView(
    sessionStore: MockData.mockSessionStore(),
    initialDashboard: MockData.progressDashboardNoMetrics
  )
}
