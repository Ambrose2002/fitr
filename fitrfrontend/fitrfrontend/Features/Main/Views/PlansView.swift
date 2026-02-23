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
  @State private var newPlanName = ""

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
              .padding(.top, 16)

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
        }

        // Floating Action Button
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
            .padding(.bottom, 24)
          }
        }
        .ignoresSafeArea()
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
    .sheet(isPresented: $showCreatePlan) {
      CreatePlanSheet(
        isPresented: $showCreatePlan,
        onCreate: { name in
          Task {
            await viewModel.createPlan(name: name)
            showCreatePlan = false
          }
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
  let onCreate: (String) -> Void

  @State private var planName = ""
  @State private var errorMessage = ""

  var body: some View {
    NavigationStack {
      VStack(spacing: 16) {
        VStack(alignment: .leading, spacing: 8) {
          Text("Plan Name")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(AppColors.textPrimary)

          TextField("e.g., Upper Body Strength", text: $planName)
            .padding(12)
            .background(Color(.systemGray6))
            .cornerRadius(8)
            .submitLabel(.done)
        }

        if !errorMessage.isEmpty {
          HStack(spacing: 8) {
            Image(systemName: "exclamationmark.circle")
              .foregroundColor(.red)
            Text(errorMessage)
              .font(.caption)
              .foregroundColor(.red)
          }
        }

        Spacer()

        Button {
          if planName.trimmingCharacters(in: .whitespaces).isEmpty {
            errorMessage = "Plan name is required"
          } else {
            onCreate(planName)
          }
        } label: {
          Text("Create Plan")
            .font(.system(size: 16, weight: .semibold))
            .foregroundColor(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 44)
            .background(AppColors.accent)
            .cornerRadius(8)
        }
      }
      .padding(16)
      .navigationTitle("New Plan")
      .navigationBarTitleDisplayMode(.inline)
      .toolbar {
        ToolbarItem(placement: .navigationBarLeading) {
          Button("Cancel") {
            isPresented = false
          }
        }
      }
    }
  }
}

//#Preview {
//    let mockStore = SessionStore.mock()
//    PlansView(sessionStore: mockStore)
//        .environmentObject(mockStore)
//}
