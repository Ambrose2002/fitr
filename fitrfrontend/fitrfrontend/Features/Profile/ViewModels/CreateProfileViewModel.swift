//
//  CreateProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//
internal import Combine

class CreateProfileViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    @Published var selectedGender: Gender? = .male
    @Published var selectedExperience: ExperienceLevel? = .beginner
    @Published var selectedGoal: Goal? = .strength
    @Published var selectedWeightUnit: WeightUnit = .kg
    @Published var selectedDistanceUnit: DistanceUnit = .km
    
    @Published var height = 180
    @Published var weight = 75
    
    let sessionStore: SessionStore
    let profileService: ProfileService = ProfileService()
    
    
    init (sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }
}
