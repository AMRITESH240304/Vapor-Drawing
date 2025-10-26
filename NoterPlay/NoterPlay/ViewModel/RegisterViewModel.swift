//
//  RegisterViewModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 24/10/25.
//

import Combine
import Foundation

class RegisterViewModel: ObservableObject {
    @Published var email: String = ""
    @Published var password: String = ""
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    @Published var token: String?
    @Published var isRegistered: Bool = false

    func register() async throws {
        isLoading = true
        errorMessage = nil

        let registerRequest = RegisterRequest(email: email, password: password)
        do {
            
            try await AuthNetworkManager.shared.registerUser(email: registerRequest.email, password: registerRequest.password) { result in
                switch result {
                case .success(let token):
                    DispatchQueue.main.async {
                        self.token = token
                        self.isRegistered = true
                        self.isLoading = false
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        } catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
    
    func login() async {
        isLoading = true
        errorMessage = nil
        
        let loginRequest = RegisterRequest(email: email, password: password)
        
        do{
            try await AuthNetworkManager.shared.loginUser(email: loginRequest.email, password: loginRequest.password) { result in
                switch result {
                case .success(let token):
                    DispatchQueue.main.async {
                        self.token = token
                        self.isRegistered = true
                        let userDefaults = UserDefaults.standard
                        userDefaults.set(token, forKey: "authToken")
                        self.isLoading = false
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
        }
        catch {
            DispatchQueue.main.async {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }
}

