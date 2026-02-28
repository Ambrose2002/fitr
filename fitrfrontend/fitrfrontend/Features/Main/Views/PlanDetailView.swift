//
//  PlanDetailView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

import SwiftUI

struct PlanDetailView: View {
  @Environment(\.dismiss) var dismiss
  @EnvironmentObject var sessionStore: SessionStore
  @StateObject private var viewModel: PlanDetailViewModel = PlanDetailViewModel(
    planId: 0, sessionStore: SessionStore())
  @State private var selectedDay: EnrichedPlanDay?

  let planId: Int64

  var body: some View {
    ZStack {
      Color(.systemBackground).ignoresSafeArea()

      if viewModel.isLoading {
        ProgressView()
      } else if let errorMessage = viewModel.errorMessage {
        VStack(spacing: 16) {
          Image(systemName: "exclamationmark.circle")
            .font(.system(size: 48))
            .foregroundColor(.red)
          Text("Something went wrong")
            .font(.headline)
          Text(errorMessage)
            .font(.caption)
            .foregroundColor(.secondary)
          Button("Retry") {
            Task {
              await viewModel.loadPlanDetail()
            }
          }
          .buttonStyle(.bordered)
        }
        .padding(24)
      } else if let plan = viewModel.planDetail {
        ScrollView {
          VStack(spacing: 24) {
            // Plan Header Card
            VStack(alignment: .leading, spacing: 16) {
              HStack(alignment: .top) {
                VStack(alignment: .leading, spacing: 8) {
                  Text(plan.name)
                    .font(.system(size: 24, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)

                  HStack(spacing: 8) {
                    Image(systemName: "checkmark.circle.fill")
                      .foregroundColor(AppColors.accent)
                  }
                }

                Spacer()

                Image(systemName: "bolt.fill")
                  .font(.system(size: 24))
                  .foregroundColor(AppColors.accent)
              }

              Divider()

              HStack(spacing: 24) {
                VStack(alignment: .leading, spacing: 4) {
                  Text("DAYS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                  Text("\(viewModel.planDayCount) of 7 Days Assigned")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                }

                Spacer()

                VStack(alignment: .leading, spacing: 4) {
                  Text("STATUS")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundColor(AppColors.textPrimary)
                  Text(plan.isActive ? "Currently Active" : "Inactive")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                }

                Spacer()
              }
            }
            .padding(16)
            .background(AppColors.accent.opacity(0.15))
            .cornerRadius(16)
            .padding(.horizontal, 16)

            // Set as Active Plan Card
            VStack(spacing: 16) {
              HStack {
                VStack(alignment: .leading, spacing: 4) {
                  Text("Set as Active Plan")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(AppColors.textPrimary)
                  Text("Track progress specifically for this routine.")
                    .font(.system(size: 12))
                    .foregroundColor(.secondary)
                }

                Spacer()

                Toggle(
                  "",
                  isOn: Binding(
                    get: { viewModel.isActiveToggle },
                    set: { newValue in
                      Task {
                        await viewModel.toggleActiveStatus(newValue)
                      }
                    }
                  )
                )
                .tint(AppColors.accent)
              }

              Button {
                if viewModel.hasAvailableWeekdays {
                  viewModel.showAddDaySheet = true
                }
              } label: {
                HStack {
                  Image(systemName: "plus")
                  Text("Add New Workout Day")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(
                  viewModel.hasAvailableWeekdays
                    ? AppColors.accent : AppColors.accent.opacity(0.35)
                )
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
              .disabled(!viewModel.hasAvailableWeekdays)

              if !viewModel.hasAvailableWeekdays {
                Text("All 7 weekdays are already assigned.")
                  .font(.system(size: 12, weight: .medium))
                  .foregroundColor(AppColors.textSecondary)
                  .frame(maxWidth: .infinity, alignment: .leading)
              }
            }
            .padding(16)
            .background(Color(.systemGray6))
            .cornerRadius(12)
            .padding(.horizontal, 16)

            // Training Schedule Section
            VStack(alignment: .leading, spacing: 12) {
              HStack {
                Text("Training Schedule")
                  .font(.system(size: 16, weight: .bold))
                  .foregroundColor(AppColors.textPrimary)

                Spacer()

                Text("\(viewModel.planDayCount) TOTAL")
                  .font(.system(size: 12, weight: .semibold))
                  .foregroundColor(AppColors.accent)
              }
              .padding(.horizontal, 16)

              if viewModel.enrichedDays.isEmpty {
                VStack(spacing: 12) {
                  Image(systemName: "calendar.badge.exclamationmark")
                    .font(.system(size: 32))
                    .foregroundColor(.secondary)
                  Text("No workout days yet")
                    .font(.system(size: 14, weight: .semibold))
                    .foregroundColor(.secondary)
                }
                .padding(.vertical, 32)
                .frame(maxWidth: .infinity)
                .background(Color(.systemGray6))
                .cornerRadius(12)
                .padding(.horizontal, 16)
              } else {
                VStack(spacing: 12) {
                  ForEach(viewModel.enrichedDays) { day in
                    TrainingDayCard(
                      day: day,
                      availableDayNumbers: viewModel.availableDayNumbers(forEditing: day.id),
                      onEdit: { newName, newDayNumber in
                        Task {
                          await viewModel.updatePlanDay(
                            id: day.id,
                            name: newName,
                            dayNumber: newDayNumber
                          )
                        }
                      },
                      onDelete: {
                        Task {
                          await viewModel.deletePlanDay(id: day.id)
                        }
                      },
                      onTap: {
                        selectedDay = day
                      }
                    )
                  }
                }
                .padding(.horizontal, 16)
              }
            }

            Spacer().frame(height: 20)
          }
          .padding(.vertical, 16)
        }
        .refreshable {
          await viewModel.loadPlanDetail()
        }
      }
    }
    .navigationBarHidden(true)
    .safeAreaInset(edge: .top) {
      VStack(spacing: 0) {
        HStack(spacing: 12) {
          Button {
            dismiss()
          } label: {
            HStack(spacing: 6) {
              Image(systemName: "chevron.left")
                .font(.system(size: 16, weight: .semibold))
              Text("Back")
                .font(.system(size: 16, weight: .semibold))
            }
            .foregroundColor(AppColors.accent)
          }

          Spacer()

          Text("Plan Details")
            .font(.system(size: 18, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          Spacer()

          Menu {
            Button(role: .destructive) {
              Task {
                await viewModel.deletePlan()
                dismiss()
              }
            } label: {
              Label("Delete Plan", systemImage: "trash")
            }
          } label: {
            Image(systemName: "ellipsis")
              .font(.system(size: 16, weight: .semibold))
              .foregroundColor(AppColors.textPrimary)
          }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 12)
        .background(Color(.systemBackground))

        Divider()
      }
    }
    .sheet(isPresented: $viewModel.showAddDaySheet) {
      AddWorkoutDaySheet(
        availableDayNumbers: viewModel.availableDayNumbersForNewDay,
        onAdd: { name, dayNumber in
          Task {
            await viewModel.addPlanDay(name: name, dayNumber: dayNumber)
          }
        }
      )
    }
    .navigationDestination(item: $selectedDay) { day in
      PlanDayDetailView(
        planId: planId,
        planName: viewModel.planDetail?.name ?? "Workout Plan",
        days: viewModel.enrichedDays,
        initialDayId: day.id,
        onDayDeleted: { deletedId in
          viewModel.removeDeletedDay(id: deletedId)
          if viewModel.enrichedDays.isEmpty {
            selectedDay = nil
          }
        }
      )
    }
    .task {
      viewModel.updatePlanId(planId)
      viewModel.updateSessionStore(sessionStore)
      await viewModel.loadPlanDetail()
    }
  }
}

// MARK: - Training Day Card Component

struct TrainingDayCard: View {
  let day: EnrichedPlanDay
  let availableDayNumbers: [Int]
  let onEdit: (String, Int) -> Void
  let onDelete: () -> Void
  let onTap: () -> Void

  @State private var showEditSheet = false
  @State private var editedName: String = ""
  @State private var editedDayNumber: Int = 1

  var body: some View {
    VStack(alignment: .leading, spacing: 10) {
      HStack(alignment: .top, spacing: 12) {
        weekdayBadge

        VStack(alignment: .leading, spacing: 6) {
          Text(day.name)
            .font(.system(size: 16, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          HStack(spacing: 8) {
            Text(day.weekdayName)
              .font(.system(size: 12, weight: .semibold))
              .foregroundColor(AppColors.accent)

            Circle()
              .fill(AppColors.borderGray)
              .frame(width: 4, height: 4)

            HStack(spacing: 4) {
              AppIcons.clock
                .font(.system(size: 11, weight: .semibold))
              Text("\(day.estimatedMinutes) min")
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.textSecondary)

            Circle()
              .fill(AppColors.borderGray)
              .frame(width: 4, height: 4)

            HStack(spacing: 4) {
              AppIcons.strength
                .font(.system(size: 11, weight: .semibold))
              Text("\(day.exerciseCount) Exercises")
                .font(.system(size: 12, weight: .medium))
            }
            .foregroundColor(AppColors.textSecondary)
          }
        }

        Spacer(minLength: 8)

        dayMenu
      }
    }
    .padding(12)
    .background(Color(.systemGray6))
    .cornerRadius(12)
    .contentShape(Rectangle())
    .onTapGesture {
      onTap()
    }
    .sheet(isPresented: $showEditSheet) {
      EditWorkoutDaySheet(
        dayName: editedName,
        currentDayNumber: editedDayNumber,
        availableDayNumbers: availableDayNumbers,
        onSave: { newName, newDayNumber in
          onEdit(newName, newDayNumber)
        }
      )
    }
  }

  private var weekdayBadge: some View {
    VStack(spacing: 3) {
      AppIcons.calendar
        .font(.system(size: 11, weight: .semibold))
        .foregroundColor(.white.opacity(0.9))

      Text(day.weekday?.badgeName ?? "\(day.dayNumber)")
        .font(.system(size: 12, weight: .black))
        .foregroundColor(.white)
    }
    .frame(width: 50, height: 50)
    .background(
      RoundedRectangle(cornerRadius: 12, style: .continuous)
        .fill(AppColors.accent)
    )
  }

  private var dayMenu: some View {
    Menu {
      Button {
        editedName = day.name
        editedDayNumber = day.dayNumber
        showEditSheet = true
      } label: {
        Label("Edit", systemImage: "pencil")
      }

      Button(role: .destructive) {
        onDelete()
      } label: {
        Label("Delete", systemImage: "trash")
      }
    } label: {
      Image(systemName: "ellipsis")
        .font(.system(size: 14))
        .foregroundColor(.secondary)
        .frame(width: 24, height: 24)
    }
  }
}

// MARK: - Add Workout Day Sheet

struct AddWorkoutDaySheet: View {
  @Environment(\.dismiss) var dismiss

  let availableDayNumbers: [Int]
  let onAdd: (String, Int) -> Void

  @State private var dayName = ""
  @State private var selectedDayNumber: Int?

  init(availableDayNumbers: [Int], onAdd: @escaping (String, Int) -> Void) {
    self.availableDayNumbers = availableDayNumbers.sorted()
    self.onAdd = onAdd
    _selectedDayNumber = State(initialValue: availableDayNumbers.sorted().first)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 18) {
        if availableDayNumbers.isEmpty {
          unavailableWeekdayState
        } else {
          formSection(title: "DAY NAME") {
            textInputField(
              title: "Day name (e.g., Upper Body)",
              text: $dayName
            )
          }

          formSection(title: "WEEKDAY") {
            WeekdaySelectionGrid(
              availableDayNumbers: Set(availableDayNumbers),
              selectedDayNumber: $selectedDayNumber
            )
          }
        }

        Spacer()

        actionButtons(
          primaryTitle: "Add Day",
          onCancel: { dismiss() },
          primaryAction: {
            guard let selectedDayNumber else { return }
            onAdd(dayName.trimmingCharacters(in: .whitespacesAndNewlines), selectedDayNumber)
            dismiss()
          },
          isPrimaryDisabled: !isSubmissionValid
        )
      }
      .padding(16)
      .navigationTitle("New Workout Day")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var isSubmissionValid: Bool {
    let trimmedName = dayName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let selectedDayNumber else { return false }
    return !trimmedName.isEmpty && availableDayNumbers.contains(selectedDayNumber)
  }

  private var unavailableWeekdayState: some View {
    VStack(spacing: 12) {
      AppIcons.calendar
        .font(.system(size: 28, weight: .semibold))
        .foregroundColor(AppColors.accent)

      Text("All weekdays are already assigned")
        .font(.system(size: 16, weight: .bold))
        .foregroundColor(AppColors.textPrimary)

      Text("Remove a workout day or reassign one before adding another.")
        .font(.system(size: 13))
        .foregroundColor(AppColors.textSecondary)
        .multilineTextAlignment(.center)
    }
    .frame(maxWidth: .infinity)
    .padding(20)
    .background(Color(.systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 16)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(16)
  }
}

// MARK: - Edit Workout Day Sheet

struct EditWorkoutDaySheet: View {
  @Environment(\.dismiss) var dismiss

  let dayName: String
  let currentDayNumber: Int
  let availableDayNumbers: [Int]
  let onSave: (String, Int) -> Void

  @State private var editedName: String = ""
  @State private var selectedDayNumber: Int?

  init(
    dayName: String,
    currentDayNumber: Int,
    availableDayNumbers: [Int],
    onSave: @escaping (String, Int) -> Void
  ) {
    self.dayName = dayName
    self.currentDayNumber = currentDayNumber
    self.availableDayNumbers = availableDayNumbers.sorted()
    self.onSave = onSave
    _editedName = State(initialValue: dayName)
    let defaultDayNumber =
      availableDayNumbers.contains(currentDayNumber)
      ? currentDayNumber
      : availableDayNumbers.sorted().first
    _selectedDayNumber = State(initialValue: defaultDayNumber)
  }

  var body: some View {
    NavigationStack {
      VStack(spacing: 18) {
        formSection(title: "DAY NAME") {
          textInputField(
            title: "Day name",
            text: $editedName
          )
        }

        formSection(title: "WEEKDAY") {
          WeekdaySelectionGrid(
            availableDayNumbers: Set(availableDayNumbers),
            selectedDayNumber: $selectedDayNumber
          )
        }

        Spacer()

        actionButtons(
          primaryTitle: "Save Changes",
          onCancel: { dismiss() },
          primaryAction: {
            guard let selectedDayNumber else { return }
            onSave(editedName.trimmingCharacters(in: .whitespacesAndNewlines), selectedDayNumber)
            dismiss()
          },
          isPrimaryDisabled: !isSubmissionValid
        )
      }
      .padding(16)
      .navigationTitle("Edit Workout Day")
      .navigationBarTitleDisplayMode(.inline)
    }
  }

  private var isSubmissionValid: Bool {
    let trimmedName = editedName.trimmingCharacters(in: .whitespacesAndNewlines)
    guard let selectedDayNumber else { return false }
    return !trimmedName.isEmpty && availableDayNumbers.contains(selectedDayNumber)
  }
}

private struct WeekdaySelectionGrid: View {
  let availableDayNumbers: Set<Int>
  @Binding var selectedDayNumber: Int?

  private let columns = Array(repeating: GridItem(.flexible(), spacing: 8), count: 4)

  var body: some View {
    LazyVGrid(columns: columns, spacing: 8) {
      ForEach(WorkoutWeekday.allCases) { weekday in
        let isAvailable = availableDayNumbers.contains(weekday.rawValue)
        let isSelected = selectedDayNumber == weekday.rawValue

        Button {
          guard isAvailable else { return }
          selectedDayNumber = weekday.rawValue
        } label: {
          VStack(spacing: 4) {
            Text(weekday.badgeName)
              .font(.system(size: 12, weight: .bold))
              .foregroundColor(
                isAvailable
                  ? (isSelected ? .white : AppColors.textPrimary) : AppColors.textSecondary
              )

            Text(weekday.fullName)
              .font(.system(size: 10, weight: .medium))
              .foregroundColor(
                isAvailable
                  ? (isSelected ? .white.opacity(0.88) : AppColors.textSecondary)
                  : AppColors.textSecondary.opacity(0.6)
              )
              .lineLimit(1)
          }
          .frame(maxWidth: .infinity)
          .frame(height: 54)
          .background(backgroundColor(isAvailable: isAvailable, isSelected: isSelected))
          .overlay(
            RoundedRectangle(cornerRadius: 12)
              .stroke(borderColor(isAvailable: isAvailable, isSelected: isSelected), lineWidth: 1)
          )
          .cornerRadius(12)
          .opacity(isAvailable ? 1 : 0.55)
        }
        .buttonStyle(.plain)
        .disabled(!isAvailable)
      }
    }
  }

  private func backgroundColor(isAvailable: Bool, isSelected: Bool) -> Color {
    if isSelected && isAvailable {
      return AppColors.accent
    }
    return Color(.systemGray6)
  }

  private func borderColor(isAvailable: Bool, isSelected: Bool) -> Color {
    if isSelected && isAvailable {
      return AppColors.accent
    }
    return AppColors.borderGray
  }
}

private func formSection<Content: View>(
  title: String,
  @ViewBuilder content: () -> Content
) -> some View {
  VStack(alignment: .leading, spacing: 10) {
    Text(title)
      .font(.system(size: 11, weight: .bold))
      .foregroundColor(AppColors.textSecondary)

    content()
  }
}

private func textInputField(title: String, text: Binding<String>) -> some View {
  TextField(title, text: text)
    .padding(14)
    .background(Color(.systemGray6))
    .overlay(
      RoundedRectangle(cornerRadius: 14)
        .stroke(AppColors.borderGray, lineWidth: 1)
    )
    .cornerRadius(14)
}

private func actionButtons(
  primaryTitle: String,
  onCancel: @escaping () -> Void,
  primaryAction: @escaping () -> Void,
  isPrimaryDisabled: Bool
) -> some View {
  HStack(spacing: 12) {
    Button("Cancel") {
      onCancel()
    }
    .frame(maxWidth: .infinity)
    .frame(height: 48)
    .foregroundColor(AppColors.accent)
    .background(Color(.systemGray6))
    .cornerRadius(12)

    Button(action: primaryAction) {
      Text(primaryTitle)
        .foregroundColor(.white)
        .frame(maxWidth: .infinity)
        .frame(height: 48)
        .background(isPrimaryDisabled ? AppColors.accent.opacity(0.35) : AppColors.accent)
        .cornerRadius(12)
    }
    .disabled(isPrimaryDisabled)
  }
}

//#Preview {
//  NavigationStack {
//    PlanDetailView(planId: 1, sessionStore: SessionStore())
//      .environmentObject(SessionStore())
//  }
//}
