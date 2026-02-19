//
//  CreateProfileView.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//

import SwiftUI

struct CreateProfileView: View {

    @State private var selectedGender: Gender? = .male
    @State private var selectedExperience: ExperienceLevel? = .beginner
    @State private var selectedGoal: Goal? = .strength
    @State private var selectedWeightUnit: Unit = .kg
    @State private var selectedDistanceUnit: Unit = .km

    @StateObject private var viewModel: CreateProfileViewModel
    
    init(sessionStore: SessionStore) {
        _viewModel = StateObject(wrappedValue: CreateProfileViewModel(sessionStore: sessionStore))
    }
    
    @ViewBuilder
    private func genderCard(for gender: Gender) -> some View {
        let isSelected = selectedGender == gender
        Button {
            selectedGender = gender
        } label: {
            VStack(spacing: 8) {
                Image(systemName: gender.systemImageName)
                    .font(.system(size: 24, weight: .semibold))
                    .foregroundStyle(isSelected ? AppColors.accent : Color.primary)
                    .frame(height: 28)
                Text(gender.rawValue.uppercased())
                    .font(.system(size: 12, weight: .bold))
                    .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 12)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.2) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : Color(.systemGray4), lineWidth: 1)
            )
            .shadow(color: isSelected ? Color.accentColor.opacity(0.25) : Color.clear, radius: 10, x: 0, y: 4)
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(gender.rawValue))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    @ViewBuilder
    private func experienceCard(for experience: ExperienceLevel) -> some View {
        let isSelected = selectedExperience == experience
        Button {
            selectedExperience = experience
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(experience.rawValue.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
                    Text(experience.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.2) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(experience.rawValue))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    @ViewBuilder
    private func goalCard(for goal: Goal) -> some View {
        let isSelected = selectedGoal == goal
        Button {
            selectedGoal = goal
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 2) {
                    Text(goal.rawValue.uppercased())
                        .font(.system(size: 14, weight: .bold))
                        .foregroundStyle(isSelected ? AppColors.accent : AppColors.textPrimary)
                    Text(goal.description)
                        .font(.system(size: 12))
                        .foregroundStyle(.secondary)
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.system(size: 20))
                        .foregroundStyle(AppColors.accent)
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 16)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .fill(isSelected ? AppColors.accent.opacity(0.2) : Color(.systemBackground))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 14, style: .continuous)
                    .stroke(isSelected ? AppColors.accent : Color(.systemGray4), lineWidth: 1)
            )
        }
        .buttonStyle(.plain)
        .accessibilityLabel(Text(goal.rawValue))
        .accessibilityAddTraits(isSelected ? .isSelected : [])
    }
    
    var body: some View {
        ScrollView {
            VStack (spacing: 38){
                VStack (spacing: 3){
                    Text("Create Your Profile")
                        .font(.system(size: 24, weight: .bold))
                        .foregroundColor(.black)
                        .frame(maxWidth: .infinity, alignment: .leading)
                    
                    Text("We'll use this data to calculate your calorie needs and suggest optimal workout volumes.")
                        .font(.system(size: 14))
                        .frame(maxWidth: .infinity, alignment: .leading)
                }
                
                // GENDER SECTION
                VStack(alignment: .leading, spacing: 12) {
                    Text("WHAT IS YOUR GENDER?")
                        .font(.system(size: 12, weight: .semibold))
                        .foregroundColor(AppColors.textPrimary)
                        .textCase(.uppercase)
                    
                    HStack(spacing: 11) {
                        genderCard(for: .male)
                        genderCard(for: .female)
                        genderCard(for: .other)
                    }
                    
                }
                
                // HEIGHT AND WEIGHT SECTION
                VStack(alignment: .leading, spacing: 16) {
                    HStack(spacing: 16) {
                        // Height Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT HEIGHT")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                AppIcons.height
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                    .padding(.leading, 10)
                                
                                TextField("180", value: $height, format: .number)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .keyboardType(.numberPad)
                                
                                Text("CM")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .frame(height: 48)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                            
                        }
                        
                        // Weight Input
                        VStack(alignment: .leading, spacing: 8) {
                            Text("CURRENT WEIGHT")
                                .font(.system(size: 12, weight: .semibold))
                                .foregroundColor(AppColors.textPrimary)
                                .textCase(.uppercase)
                            
                            HStack(spacing: 8) {
                                AppIcons.weight
                                    .foregroundColor(.gray)
                                    .frame(width: 20)
                                    .padding(.leading, 10)
                                
                                TextField("75", value: $weight, format: .number)
                                    .font(.system(size: 16, weight: .semibold))
                                    .foregroundColor(AppColors.textPrimary)
                                    .keyboardType(.numberPad)
                                
                                Text("KG")
                                    .font(.system(size: 12, weight: .semibold))
                                    .foregroundColor(.gray)
                                    .padding(.trailing, 10)
                            }
                            .frame(height: 48)
                            .background(Color(.systemGray6))
                            .cornerRadius(12)
                        }
                    }
                }

            }
        }
        .padding(.horizontal, 16)
        .overlay {
            // Loading overlay
            if viewModel.isLoading {
                ZStack {
                    Color.black.opacity(0.2).ignoresSafeArea()
                    ProgressView("Creating profile…")
                        .padding(24)
                        .background(.ultraThinMaterial)
                        .cornerRadius(12)
                }
            }
        }
        .animation(.default, value: viewModel.isLoading)
        .navigationBarTitleDisplayMode(.inline)
        .toolbarBackground(.visible, for: .navigationBar)
        .toolbar {
            ToolbarItem(placement: .principal) {
                Text("TELL US ABOUT YOU")
                    .font(.headline)
                    .foregroundColor(AppColors.textPrimary)
            }
        }
        .overlay(alignment: .top) {
            GeometryReader { proxy in
                VStack(spacing: 0) {
                    Color.clear.frame(height: proxy.safeAreaInsets.top)
                    Divider()
                    Spacer()
                }
                .ignoresSafeArea(edges: .top)
            }
        }
    }
}


#Preview {
    CreateProfileView(sessionStore: SessionStore())
}
