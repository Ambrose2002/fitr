//
//  PlanDayDetailView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/25/26.
//

import SwiftUI

struct PlanDayDetailView: View {
  @Environment(\.dismiss) private var dismiss

  let day: EnrichedPlanDay
  let planName: String

  private var estimatedMinutesText: String {
    if day.durationMinutes > 0 {
      return "\(day.durationMinutes) min"
    }

    let fallbackMinutes = max(day.exerciseCount * 6, day.exercises.reduce(0) { $0 + max($1.targetSets, 1) * 2 })
    return "\(fallbackMinutes) min"
  }

  var body: some View {
    ZStack {
      Color(.systemBackground)
        .ignoresSafeArea()

      ScrollView {
        VStack(alignment: .leading, spacing: 16) {
          VStack(alignment: .leading, spacing: 8) {
            Text(day.name)
              .font(.system(size: 38, weight: .black))
              .foregroundColor(AppColors.textPrimary)

            Text("Part of the \"\(planName)\" plan.")
              .font(.system(size: 17))
              .foregroundColor(.secondary)
          }

          HStack(spacing: 0) {
            VStack(alignment: .leading, spacing: 8) {
              Label {
                Text("EST. TIME")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "clock")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text(estimatedMinutesText)
                .font(.system(size: 33, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)

            Divider()
              .frame(height: 70)
              .padding(.horizontal, 16)

            VStack(alignment: .leading, spacing: 8) {
              Label {
                Text("EXERCISES")
                  .font(.system(size: 11, weight: .bold))
              } icon: {
                Image(systemName: "flame")
                  .font(.system(size: 12, weight: .semibold))
              }
              .foregroundColor(.secondary)

              Text("\(day.exerciseCount)")
                .font(.system(size: 33, weight: .black))
                .foregroundColor(AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 14)
          .background(Color(.systemGray6))
          .overlay(
            RoundedRectangle(cornerRadius: 14)
              .stroke(Color(.systemGray4), lineWidth: 1)
          )
          .cornerRadius(14)

          HStack {
            Text("ROUTINE")
              .font(.system(size: 14, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            Spacer()

            Button("REORDER") {}
              .font(.system(size: 11, weight: .bold))
              .foregroundColor(AppColors.accent)
          }

          if day.exercises.isEmpty {
            VStack(spacing: 12) {
              Image(systemName: "dumbbell")
                .font(.system(size: 30))
                .foregroundColor(.secondary)
              Text("No exercises yet")
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(.secondary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 36)
            .background(Color(.systemGray6))
            .cornerRadius(12)
          } else {
            VStack(spacing: 12) {
              ForEach(day.exercises) { exercise in
                PlanDayExerciseCard(exercise: exercise)
              }
            }
          }

          Spacer(minLength: 32)
        }
        .padding(.horizontal, 16)
        .padding(.top, 16)
      }
    }
    .navigationBarBackButtonHidden(true)
    .safeAreaInset(edge: .top) {
      VStack(spacing: 0) {
        HStack {
          Button {
            dismiss()
          } label: {
            Image(systemName: "chevron.left")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(AppColors.textPrimary)
          }
          .frame(width: 44, alignment: .leading)

          Spacer()

          Text("PLAN DAY")
            .font(.system(size: 17, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          Spacer()

          Button("Edit") {}
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.accent)
            .frame(width: 44, alignment: .trailing)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))

        Divider()
      }
    }
    .safeAreaInset(edge: .bottom) {
      Button {} label: {
        HStack {
          Text("Start This Workout")
            .font(.system(size: 30, weight: .black))
            .foregroundColor(.white)
            .lineLimit(1)
            .minimumScaleFactor(0.7)
            .padding(.leading, 20)
          Spacer()
        }
        .frame(height: 64)
        .background(AppColors.accent)
        .cornerRadius(16)
        .overlay(alignment: .trailing) {
          Circle()
            .fill(AppColors.accent)
            .frame(width: 52, height: 52)
            .shadow(color: AppColors.accent.opacity(0.35), radius: 6, x: 0, y: 4)
            .overlay {
              Image(systemName: "plus")
                .font(.system(size: 24, weight: .semibold))
                .foregroundColor(.white)
            }
            .padding(.trailing, 8)
        }
      }
      .buttonStyle(.plain)
      .padding(.horizontal, 16)
      .padding(.vertical, 10)
      .background(Color(.systemBackground))
    }
  }
}

struct PlanDayExerciseCard: View {
  let exercise: EnrichedPlanExercise

  private var setCount: Int {
    max(exercise.targetSets, 1)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 14) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          Text(exercise.measurementBadge)
            .font(.system(size: 10, weight: .bold))
            .foregroundColor(AppColors.accent)
            .padding(.horizontal, 10)
            .padding(.vertical, 4)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(999)

          Text(exercise.name)
            .font(.system(size: 33, weight: .black))
            .foregroundColor(AppColors.textPrimary)
            .lineLimit(2)
        }

        Spacer()

        Button {} label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(.secondary)
            .frame(width: 24, height: 24)
        }
      }

      VStack(spacing: 0) {
        HStack {
          Text("SET")
            .frame(maxWidth: .infinity, alignment: .leading)
          Text("TARGET")
            .frame(maxWidth: .infinity, alignment: .center)
          Text("DETAIL")
            .frame(maxWidth: .infinity, alignment: .trailing)
        }
        .font(.system(size: 12, weight: .bold))
        .foregroundColor(.secondary)
        .padding(.horizontal, 12)
        .padding(.bottom, 8)

        VStack(spacing: 0) {
          ForEach(1...setCount, id: \.self) { setIndex in
            HStack {
              Text("\(setIndex)")
                .frame(maxWidth: .infinity, alignment: .leading)
              Text(exercise.targetValueText)
                .fontWeight(.bold)
                .frame(maxWidth: .infinity, alignment: .center)
              Text(exercise.detailValueText)
                .fontWeight(.bold)
                .foregroundColor(AppColors.accent)
                .frame(maxWidth: .infinity, alignment: .trailing)
            }
            .font(.system(size: 22, weight: .medium))
            .foregroundColor(AppColors.textPrimary)
            .frame(height: 50)
            .padding(.horizontal, 12)

            if setIndex != setCount {
              Divider()
            }
          }
        }
        .background(Color(.systemBackground))
        .overlay(
          RoundedRectangle(cornerRadius: 10)
            .stroke(Color(.systemGray4), lineWidth: 1)
        )
        .cornerRadius(10)
      }
    }
    .padding(14)
    .background(Color(.systemBackground))
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(Color(.systemGray4), lineWidth: 1)
    )
    .cornerRadius(12)
  }
}

private extension EnrichedPlanExercise {
  var measurementBadge: String {
    switch measurementType {
    case .reps, .repsAndWeight:
      return "Strength"
    case .repsAndTime:
      return "Paced"
    case .time, .timeAndWeight:
      return "Timed"
    case .distanceAndTime:
      return "Distance"
    case .caloriesAndTime:
      return "Calories"
    case .none:
      return "Routine"
    }
  }

  var targetValueText: String {
    if targetReps > 0 {
      return "\(targetReps)"
    }
    if targetDurationSeconds > 0 {
      return targetDurationSeconds.durationDisplay
    }
    if targetDistance > 0 {
      return "\(Int(targetDistance)) m"
    }
    if targetCalories > 0 {
      return "\(Int(targetCalories)) cal"
    }
    return "--"
  }

  var detailValueText: String {
    if targetReps > 0 && targetDurationSeconds > 0 {
      return targetDurationSeconds.durationDisplay
    }
    if targetDistance > 0 && targetDurationSeconds > 0 {
      return targetDurationSeconds.durationDisplay
    }
    if targetCalories > 0 && targetDurationSeconds > 0 {
      return targetDurationSeconds.durationDisplay
    }
    return "--"
  }
}

private extension Int {
  var durationDisplay: String {
    if self < 60 {
      return "\(self)s"
    }
    let minutes = self / 60
    let seconds = self % 60
    if seconds == 0 {
      return "\(minutes)m"
    }
    return "\(minutes)m \(seconds)s"
  }
}
