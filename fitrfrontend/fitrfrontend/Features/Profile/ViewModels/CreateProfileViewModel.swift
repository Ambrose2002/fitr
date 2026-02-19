//
//  CreateProfileViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/18/26.
//
internal import Combine

final class CreateProfileViewModel: ObservableObject {
    
    @Published var isLoading: Bool = false
    
    let sessionStore: SessionStore
    
    init (sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }
}
