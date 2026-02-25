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
          Text("Error loading plan")
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
                  Text("\(viewModel.planDayCount) Workout Days")
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
                viewModel.showAddDaySheet = true
              } label: {
                HStack {
                  Image(systemName: "plus")
                  Text("Add New Workout Day")
                }
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 48)
                .background(AppColors.accent)
                .cornerRadius(12)
              }
              .buttonStyle(.plain)
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
                      onEdit: { newName in
                        Task {
                          await viewModel.updatePlanDay(id: day.id, name: newName)
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
        dayNumber: viewModel.planDayCount + 1,
        onAdd: { name in
          Task {
            await viewModel.addPlanDay(name: name)
          }
        }
      )
    }
    .navigationDestination(item: $selectedDay) { day in
      PlanDayDetailView(day: day, planName: viewModel.planDetail?.name ?? "Workout Plan")
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
  let onEdit: (String) -> Void
  let onDelete: () -> Void
  let onTap: () -> Void

  @State private var showEditSheet = false
  @State private var editedName: String = ""

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      HStack(alignment: .top) {
        VStack(alignment: .leading, spacing: 8) {
          HStack(spacing: 12) {
            Text("\(day.dayNumber)")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.white)
              .frame(width: 40, height: 40)
              .background(AppColors.accent)
              .cornerRadius(8)

            VStack(alignment: .leading, spacing: 2) {
              Text(day.name)
                .font(.system(size: 16, weight: .bold))
                .foregroundColor(AppColors.textPrimary)

              HStack(spacing: 12) {
                HStack(spacing: 4) {
                  Image(systemName: "clock")
                    .font(.system(size: 12))
                  Text("\(day.durationMinutes) min")
                    .font(.system(size: 12))
                }

                HStack(spacing: 4) {
                  Image(systemName: "dumbbell")
                    .font(.system(size: 12))
                  Text("\(day.exerciseCount) Exercises")
                    .font(.system(size: 12))
                }
              }
              .foregroundColor(.secondary)
            }
          }
        }

        Spacer()

        Menu {
          Button {
            editedName = day.name
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
        }
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
        onSave: { newName in
          onEdit(newName)
        }
      )
    }
  }
}

// MARK: - Add Workout Day Sheet

struct AddWorkoutDaySheet: View {
  @Environment(\.dismiss) var dismiss

  let dayNumber: Int
  let onAdd: (String) -> Void

  @State private var dayName = ""
  @State private var isLoading = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        TextField("Day name (e.g., Upper Body)", text: $dayName)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal, 16)

        Spacer()

        HStack(spacing: 12) {
          Button("Cancel") {
            dismiss()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .foregroundColor(AppColors.accent)
          .background(Color(.systemGray6))
          .cornerRadius(12)

          Button {
            isLoading = true
            onAdd(dayName)
            dismiss()
          } label: {
            if isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Text("Add Day")
                .foregroundColor(.white)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(AppColors.accent)
          .cornerRadius(12)
          .disabled(dayName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
      }
      .padding(.vertical, 16)
      .navigationTitle("New Workout Day")
      .navigationBarTitleDisplayMode(.inline)
    }
  }
}

// MARK: - Edit Workout Day Sheet

struct EditWorkoutDaySheet: View {
  @Environment(\.dismiss) var dismiss

  let dayName: String
  let onSave: (String) -> Void

  @State private var editedName: String = ""
  @State private var isLoading = false

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        TextField("Day name", text: $editedName)
          .textFieldStyle(.roundedBorder)
          .padding(.horizontal, 16)

        Spacer()

        HStack(spacing: 12) {
          Button("Cancel") {
            dismiss()
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .foregroundColor(AppColors.accent)
          .background(Color(.systemGray6))
          .cornerRadius(12)

          Button {
            isLoading = true
            onSave(editedName)
            dismiss()
          } label: {
            if isLoading {
              ProgressView()
                .tint(.white)
            } else {
              Text("Save Changes")
                .foregroundColor(.white)
            }
          }
          .frame(maxWidth: .infinity)
          .frame(height: 48)
          .background(AppColors.accent)
          .cornerRadius(12)
          .disabled(editedName.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
        }
        .padding(.horizontal, 16)
      }
      .padding(.vertical, 16)
      .navigationTitle("Edit Workout Day")
      .navigationBarTitleDisplayMode(.inline)
      .onAppear {
        editedName = dayName
      }
    }
  }
}

//#Preview {
//  NavigationStack {
//    PlanDetailView(planId: 1, sessionStore: SessionStore())
//      .environmentObject(SessionStore())
//  }
//}
