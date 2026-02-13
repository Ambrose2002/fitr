//
//  SignUpViewModel.swift
//  fitrfrontend
//
//  Created by Ambrose Blay on 2/13/26.
//

struct SignUpViewModel {
    private var email : String = ""
    private var password : String = ""
    private var firstName : String = ""
    private var lastName : String = ""
    private var isLoading : Bool = false
    private var errorMessage : String?
    
    public mutating func signUp() {
        isLoading = true
    }
}
