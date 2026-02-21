//
//  SessionStore.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/9/26.
//

import Foundation
import KeychainSwift
internal import Combine


final class SessionStore : ObservableObject {
    enum AuthState {
        case loading
        case authenticated
        case unauthenticated
    }
    
    private let keychain = KeychainSwift()
    
    @Published private(set) var authState: AuthState = .loading
    
    @Published var hasCreatedProfile: Bool = false {
        didSet {
            if hasCreatedProfile {
                keychain.set("true", forKey: "hasCreatedProfile")
            } else {
                keychain.delete("hasCreatedProfile")
            }
        }
    }
    
    @Published var accessToken: String? = nil {
        didSet {
            if let token = accessToken {
                keychain.set(token, forKey: "userAccessToken")
            } else {
                keychain.delete("userAccessToken")
            }
        }
    }
    
    init() {
        restoreSession()
    }
    
    func restoreSession() {
        if let token = keychain.get("userAccessToken") {
            accessToken = token
            authState = .authenticated
            hasCreatedProfile = keychain.get("hasCreatedProfile") == "true"
        } else {
            authState = .unauthenticated
        }
    }
    
    func login(_ loginResponse: LoginResponse) {
        self.accessToken = loginResponse.token
        authState = .authenticated
    }
    
    func logout() {
        accessToken = nil
        hasCreatedProfile = false
        authState = .unauthenticated
    }
}
