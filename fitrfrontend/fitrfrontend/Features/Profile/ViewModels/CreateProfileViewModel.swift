//
//  CreateProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//
internal import Combine

@MainActor
final class CreateProfileViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    
    let sessionStore: SessionStore
    let profileService: ProfileService = ProfileServiceImpl()
    
    
    init (sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }
}
