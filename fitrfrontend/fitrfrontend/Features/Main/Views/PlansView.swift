//
//  PlansView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/23/26.
//

import SwiftUI

struct PlansView: View {
  @EnvironmentObject var sessionStore: SessionStore
  @StateObject private var viewModel: WorkoutPlanViewModel

  @State private var showCreatePlan = false
  @State private var planToDelete: PlanSummary?
  @State private var showDeleteConfirmation = false
  @State private var pendingCreatedPlan: WorkoutPlanResponse?
  @State private var createdPlanToOpen: WorkoutPlanResponse?

  init(sessionStore: SessionStore) {
    _viewModel = StateObject(wrappedValue: WorkoutPlanViewModel(sessionStore: sessionStore))
  }

  var body: some View {
    NavigationStack {
      ZStack {
        if viewModel.isLoading {
          ProgressView()
        } else if let errorMessage = viewModel.errorMessage {
          VStack(spacing: 16) {
            Image(systemName: "exclamationmark.circle")
              .font(.system(size: 48))
              .foregroundColor(.red)
            Text("Error loading plans")
              .font(.headline)
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.secondary)
            Button("Retry") {
              Task {
                await viewModel.loadPlans()
              }
            }
            .buttonStyle(.bordered)
          }
          .padding(24)
        } else {
          ScrollView {
            VStack(spacing: 24) {
              // Header
              VStack(alignment: .leading, spacing: 4) {
                Text("Your Programs")
                  .font(.system(size: 28, weight: .bold))
                  .foregroundColor(.black)
                Text("Manage your training blocks and active schedules.")
                  .font(.system(size: 14))
                  .foregroundColor(.secondary)
              }
              .frame(maxWidth: .infinity, alignment: .leading)
              .padding(.horizontal, 16)

              // Plans List
              if viewModel.plans.isEmpty {
                VStack(spacing: 16) {
                  Image(systemName: "doc.text")
                    .font(.system(size: 48))
                    .foregroundColor(.gray)
                  Text("No workout plans yet")
                    .font(.headline)
                  Text("Create your first plan to get started")
                    .font(.caption)
                    .foregroundColor(.secondary)

                  Button {
                    showCreatePlan = true
                  } label: {
                    HStack(spacing: 8) {
                      Image(systemName: "plus")
                        .font(.system(size: 14, weight: .bold))
                      Text("Create Your First Plan")
                        .font(.system(size: 15, weight: .semibold))
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 48)
                    .background(AppColors.accent)
                    .cornerRadius(12)
                  }
                  .buttonStyle(.plain)
                  .padding(.top, 4)
                }
                .frame(maxWidth: .infinity)
                .padding(40)
              } else {
                VStack(spacing: 12) {
                  ForEach(viewModel.plans) { plan in
                    NavigationLink(
                      destination: PlanDetailView(planId: plan.id)
                    ) {
                      PlanCard(
                        plan: plan,
                        onDelete: {
                          planToDelete = plan
                          showDeleteConfirmation = true
                        }
                      )
                    }
                  }
                }
                .padding(.horizontal, 16)
              }

              Spacer().frame(height: 20)
            }
            .padding(.vertical, 16)
          }
          .refreshable {
            await viewModel.loadPlans()
          }
        }

        // Floating Action Button
        if !viewModel.isLoading {
          VStack {
            Spacer()
            HStack {
              Spacer()
              Button {
                showCreatePlan = true
              } label: {
                Image(systemName: "plus")
                  .font(.system(size: 20, weight: .semibold))
                  .foregroundColor(.white)
                  .frame(width: 56, height: 56)
                  .background(AppColors.accent)
                  .cornerRadius(28)
                  .shadow(color: AppColors.accent.opacity(0.3), radius: 8, x: 0, y: 4)
              }
              .padding(.trailing, 24)
              .padding(.bottom, 92)
            }
          }
        }
      }
      .navigationDestination(item: $createdPlanToOpen) { plan in
        PlanDetailView(planId: plan.id)
      }
      .navigationBarHidden(true)
      .safeAreaInset(edge: .top) {
        VStack(spacing: 0) {
          HStack(spacing: 12) {
            Image(systemName: "bolt")
              .font(.system(size: 20, weight: .bold))
              .foregroundColor(.white)
              .frame(width: 40, height: 40)
              .background(Color.black)
              .cornerRadius(10)
            Spacer()
            Text("WORKOUT PLANS")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            Spacer()

            Image(systemName: "bolt.fill")
              .font(.system(size: 18, weight: .semibold))
              .foregroundColor(AppColors.accent)
          }
          .padding(.horizontal, 16)
          .padding(.vertical, 12)
          .background(Color(.systemBackground))

          Divider()
        }
      }
    }
    .sheet(isPresented: $showCreatePlan, onDismiss: handleCreateSheetDismissed) {
      CreatePlanSheet(
        isPresented: $showCreatePlan,
        onCreate: { name in
          let createdPlan = try await viewModel.createPlan(name: name)
          pendingCreatedPlan = createdPlan
        }
      )
    }
    .alert("Delete Plan", isPresented: $showDeleteConfirmation) {
      Button("Cancel", role: .cancel) {
        planToDelete = nil
      }
      Button("Delete", role: .destructive) {
        if let plan = planToDelete {
          Task {
            await viewModel.deletePlan(id: plan.id)
            planToDelete = nil
          }
        }
      }
    } message: {
      if let plan = planToDelete {
        Text("Are you sure you want to delete \"\(plan.name)\"? This action cannot be undone.")
      }
    }
    .task {
      await viewModel.loadPlans()
    }
  }

  private func handleCreateSheetDismissed() {
    guard let createdPlan = pendingCreatedPlan else {
      return
    }

    pendingCreatedPlan = nil
    createdPlanToOpen = createdPlan
  }
}

// MARK: - Plan Card Component

struct PlanCard: View {
  let plan: PlanSummary
  let onDelete: () -> Void

  var body: some View {
    VStack(alignment: .leading, spacing: 12) {
      // Header with name and active status
      HStack {
        VStack(alignment: .leading, spacing: 4) {
          HStack(spacing: 8) {
            Text(plan.name)
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(AppColors.textPrimary)
            if plan.isActive {
              Label("ACTIVE", systemImage: "checkmark.circle.fill")
                .font(.system(size: 9, weight: .semibold))
                .foregroundColor(AppColors.accent)
                .padding(.horizontal, 6)
                .padding(.vertical, 2)
                .background(AppColors.accent.opacity(0.15))
                .cornerRadius(4)
            }
          }

          Text(plan.createdDescription)
            .font(.system(size: 11))
            .foregroundColor(.secondary)
        }

        Spacer()

        Menu {
          Button(role: .destructive) {
            onDelete()
          } label: {
            Label("Delete", systemImage: "trash")
          }
        } label: {
          Image(systemName: "ellipsis")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
        }
      }

      Divider()
        .padding(.vertical, 4)

      // Stats Grid - Frequency, Exercises, Avg per Day
      HStack(spacing: 12) {
        // Frequency
        VStack(alignment: .leading, spacing: 4) {
          Label("FREQ", systemImage: "calendar")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
          Text(plan.frequencyDescription)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
        }

        // Total Exercises
        VStack(alignment: .leading, spacing: 4) {
          Label("TOTAL", systemImage: "dumbbell.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
          Text(plan.exerciseCountDescription)
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
        }

        // Average per day
        VStack(alignment: .leading, spacing: 4) {
          Label("AVG", systemImage: "chart.bar.fill")
            .font(.system(size: 10, weight: .semibold))
            .foregroundColor(.secondary)
          Text(String(format: "%.1f/day", plan.averageExercisesPerDay))
            .font(.system(size: 14, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)
        }

        Spacer()
      }
    }
    .padding(16)
    .background(
      plan.isActive ? AppColors.accent.opacity(0.15) : Color(.systemGray6)
    )
    .overlay(
      RoundedRectangle(cornerRadius: 12)
        .stroke(
          plan.isActive ? AppColors.accent : Color(.systemGray4),
          lineWidth: 1
        )
    )
    .cornerRadius(12)
  }
}

// MARK: - Create Plan Sheet

struct CreatePlanSheet: View {
  @Binding var isPresented: Bool
  let onCreate: (String) async throws -> Void

  @State private var planName = ""
  @State private var errorMessage = ""
  @State private var isSubmitting = false

  private var trimmedPlanName: String {
    planName.trimmingCharacters(in: .whitespacesAndNewlines)
  }

  private var hasOnlyWhitespaceInput: Bool {
    !planName.isEmpty && trimmedPlanName.isEmpty
  }

  private var canSubmit: Bool {
    !trimmedPlanName.isEmpty && !isSubmitting
  }

  var body: some View {
    NavigationStack {
      VStack(alignment: .leading, spacing: 20) {
        HStack(spacing: 12) {
          AppIcons.plans
            .font(.system(size: 18, weight: .semibold))
            .foregroundColor(AppColors.accent)
            .frame(width: 42, height: 42)
            .background(AppColors.accent.opacity(0.12))
            .cornerRadius(12)

          VStack(alignment: .leading, spacing: 4) {
            Text("Start a new routine")
              .font(.system(size: 18, weight: .bold))
              .foregroundColor(AppColors.textPrimary)

            Text("Give this routine a short name. You can add workout days next.")
              .font(.system(size: 13))
              .foregroundColor(AppColors.textSecondary)
          }
        }
        .padding(.top, 8)

        VStack(alignment: .leading, spacing: 12) {
          Text("Plan Name")
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(AppColors.textPrimary)

          HStack(spacing: 12) {
            AppIcons.calendar
              .font(.system(size: 15, weight: .semibold))
              .foregroundColor(AppColors.textSecondary)
              .frame(width: 34, height: 34)
              .background(Color(.systemGray6))
              .cornerRadius(10)

            TextField(
              "",
              text: $planName,
              prompt: Text("e.g., Upper Body Strength")
                .foregroundColor(AppColors.textSecondary)
            )
            .textInputAutocapitalization(.words)
            .autocorrectionDisabled()
            .submitLabel(.done)
            .onSubmit {
              Task {
                await submit()
              }
            }
          }
          .padding(.horizontal, 14)
          .padding(.vertical, 12)
          .background(AppColors.surface)
          .overlay(
            RoundedRectangle(cornerRadius: 14)
              .stroke(
                hasOnlyWhitespaceInput ? AppColors.errorRed : AppColors.borderGray,
                lineWidth: 1
              )
          )
          .cornerRadius(14)
        }
        .padding(16)
        .background(Color(.systemGray6))
        .cornerRadius(18)

        if hasOnlyWhitespaceInput || !errorMessage.isEmpty {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle.fill")
              .font(.system(size: 13, weight: .semibold))
              .foregroundColor(AppColors.errorRed)
            Text(hasOnlyWhitespaceInput ? "Plan name is required." : errorMessage)
              .font(.system(size: 13, weight: .medium))
              .foregroundColor(AppColors.errorRed)
          }
          .padding(.horizontal, 4)
        }

        Spacer()

        Button {
          Task {
            await submit()
          }
        } label: {
          HStack {
            if isSubmitting {
              ProgressView()
                .progressViewStyle(.circular)
                .tint(.white)
                .scaleEffect(0.85)
            }

            Text(isSubmitting ? "Creating..." : "Create Plan")
              .font(.system(size: 16, weight: .semibold))
          }
          .foregroundColor(.white)
          .frame(maxWidth: .infinity)
          .frame(height: 50)
          .background(canSubmit ? AppColors.accent : AppColors.accent.opacity(0.4))
          .cornerRadius(14)
        }
        .buttonStyle(.plain)
        .disabled(!canSubmit)
      }
      .padding(16)
      .background(Color(.systemBackground))
      .navigationTitle("New Plan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            isPresented = false
          }
        }
      }
      .onChange(of: planName) { _, _ in
        if !errorMessage.isEmpty {
          errorMessage = ""
        }
      }
    }
  }

  @MainActor
  private func submit() async {
    guard !isSubmitting else {
      return
    }

    guard !trimmedPlanName.isEmpty else {
      errorMessage = ""
      return
    }

    isSubmitting = true
    errorMessage = ""

    defer {
      isSubmitting = false
    }

    do {
      try await onCreate(trimmedPlanName)
      isPresented = false
    } catch let apiError as APIErrorResponse {
      errorMessage = apiError.message
    } catch {
      errorMessage = "Failed to create workout plan."
    }
  }
}

//#Preview {
//    let mockStore = SessionStore.mock()
//    PlansView(sessionStore: mockStore)
//        .environmentObject(mockStore)
//}
