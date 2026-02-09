//
//  SessionStore.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/9/26.
//

import Foundation
internal import Combine




final class SessionStore : ObservableObject {
    enum AuthState {
        case loading
        case authenticated
        case unauthenticated
    }
    
    @Published private(set) var authState: AuthState = .loading
    
    init() {
        restoreSession()
    }
    
    func restoreSession() {
        authState = .unauthenticated
    }
    
    func login(token: String) {
        authState = .authenticated
    }
    
    func logout() {
        authState = .unauthenticated
    }
}
