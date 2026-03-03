//
//  ProgressMainView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Charts
import SwiftUI

struct ProgressMainView: View {
  @StateObject private var viewModel: ProgressViewModel
  private let onSeeFullHistoryTap: () -> Void

  init(
    sessionStore: SessionStore,
    onSeeFullHistoryTap: @escaping () -> Void = {},
    initialDashboard: ProgressDashboardData? = nil,
    initialError: String? = nil
  ) {
    self.onSeeFullHistoryTap = onSeeFullHistoryTap
    _viewModel = StateObject(
      wrappedValue: ProgressViewModel(
        sessionStore: sessionStore,
        initialDashboard: initialDashboard,
        initialError: initialError
      )
    )
  }

  var body: some View {
    NavigationStack {
      ScrollView {
        VStack(spacing: 24) {
          if let errorMessage = viewModel.errorMessage {
            ProgressInlineErrorCard(
              message: errorMessage,
              canRetry: !viewModel.isLoading,
              retry: { Task { await viewModel.refresh() } }
            )
          }

          if let dashboard = viewModel.dashboard {
            ProgressDashboardContent(
              dashboard: dashboard,
              isRefreshing: viewModel.isLoading,
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
      .background(AppColors.background.ignoresSafeArea())
      .navigationTitle("PROGRESS")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .topBarTrailing) {
          if viewModel.isLoading {
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
      .task {
        await viewModel.loadDashboard()
      }
      .refreshable {
        await viewModel.refresh()
      }
    }
  }
}

private struct ProgressDashboardContent: View {
  let dashboard: ProgressDashboardData
  let isRefreshing: Bool
  let onSeeFullHistoryTap: () -> Void

  var body: some View {
    VStack(spacing: 24) {
      BodyCompositionSection(data: dashboard.bodyComposition)
      WorkoutSummarySection(stats: dashboard.workoutSummary)
      MonthlyTrendsSection(
        points: dashboard.monthlyTrendPoints,
        kpis: dashboard.monthlyKpis,
        insight: dashboard.monthlyInsight,
        hasData: dashboard.hasMonthlyTrendData
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

        WeightTrendChart(points: data.weightPoints)
          .frame(height: 150)
      }
      .padding(18)
      .background(AppColors.surface)
      .clipShape(RoundedRectangle(cornerRadius: 18, style: .continuous))
      .overlay(
        RoundedRectangle(cornerRadius: 18, style: .continuous)
          .stroke(AppColors.borderGray, lineWidth: 1)
      )

      HStack(spacing: 12) {
        ProgressMetricCard(
          title: "HEIGHT",
          valueText: data.heightDisplayText,
          iconName: "ruler.fill",
          iconTint: AppColors.infoBlue
        )

        ProgressMetricCard(
          title: "VOLUME",
          valueText: data.volumeDisplayText,
          iconName: "bolt.fill",
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

  var body: some View {
    Chart {
      if points.count == 1, let point = points.first {
        RuleMark(y: .value("Baseline", point.value))
          .foregroundStyle(AppColors.accent.opacity(0.14))
          .lineStyle(StrokeStyle(lineWidth: 1))

        PointMark(
          x: .value("Date", point.date),
          y: .value("Weight", point.value)
        )
        .symbolSize(60)
        .foregroundStyle(AppColors.accent)
      } else {
        ForEach(points) { point in
          AreaMark(
            x: .value("Date", point.date),
            y: .value("Weight", point.value)
          )
          .interpolationMethod(.catmullRom)
          .foregroundStyle(
            LinearGradient(
              colors: [
                AppColors.accent.opacity(0.22),
                AppColors.accent.opacity(0.02),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          )

          LineMark(
            x: .value("Date", point.date),
            y: .value("Weight", point.value)
          )
          .interpolationMethod(.catmullRom)
          .lineStyle(StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
          .foregroundStyle(AppColors.accent)
        }
      }
    }
    .chartXAxis(.hidden)
    .chartYAxis(.hidden)
    .chartLegend(.hidden)
    .chartPlotStyle { plotArea in
      plotArea
        .background(Color.clear)
    }
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

private struct MonthlyTrendsSection: View {
  let points: [ProgressMonthlyTrendPoint]
  let kpis: [ProgressSummaryStat]
  let insight: String
  let hasData: Bool

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      Text("Monthly Trends")
        .font(.system(size: 28, weight: .bold))
        .foregroundStyle(AppColors.textPrimary)

      VStack(alignment: .leading, spacing: 16) {
        Chart {
          ForEach(points) { point in
            BarMark(
              x: .value("Month", point.monthLabel),
              y: .value("Sessions", point.sessionCount)
            )
            .foregroundStyle(AppColors.accent.opacity(0.22))

            LineMark(
              x: .value("Month", point.monthLabel),
              y: .value("Normalized Volume", point.normalizedVolume)
            )
            .interpolationMethod(.catmullRom)
            .lineStyle(StrokeStyle(lineWidth: 2.5, lineCap: .round, lineJoin: .round))
            .foregroundStyle(AppColors.textPrimary)

            PointMark(
              x: .value("Month", point.monthLabel),
              y: .value("Normalized Volume", point.normalizedVolume)
            )
            .symbolSize(28)
            .foregroundStyle(AppColors.textPrimary)
          }
        }
        .frame(height: 180)
        .chartYAxis(.hidden)
        .chartLegend(.hidden)
        .chartXAxis {
          AxisMarks(values: points.map(\.monthLabel)) { value in
            AxisValueLabel {
              if let label = value.as(String.self) {
                Text(label)
                  .font(.system(size: 11, weight: .semibold))
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

        HStack(spacing: 10) {
          ForEach(kpis) { kpi in
            TrendKPIChip(stat: kpi)
          }
        }

        if !hasData {
          Text("No completed workouts yet. Your monthly trend line will appear here.")
            .font(.system(size: 13))
            .foregroundStyle(AppColors.textSecondary)
        }

        Text(insight)
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
}

private struct TrendKPIChip: View {
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
        .font(.system(size: 16, weight: .bold))
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
