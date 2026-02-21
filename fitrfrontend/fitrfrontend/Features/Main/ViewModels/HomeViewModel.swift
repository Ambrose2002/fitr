//
//  HomeViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/21/26.
//

import Foundation
internal import Combine

@MainActor
final class HomeViewModel: ObservableObject {
    @Published var homeData: HomeScreenData?
    @Published var isLoading = true
    @Published var errorMessage: String?
    
    private let homeService = HomeService()
    private let sessionStore: SessionStore
    
    init(sessionStore: SessionStore) {
        self.sessionStore = sessionStore
    }
    
    
    func loadHomeData() async {
        isLoading = true
        errorMessage = nil
        
        do {
            let data = try await homeService.fetchHomeScreenData()
            self.homeData = data
        } catch {
            self.errorMessage = error.localizedDescription
        }
        
        isLoading = false
    }
}

