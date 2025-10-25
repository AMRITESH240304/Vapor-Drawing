//
//  LoginView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 25/10/25.
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var loginViewModel: RegisterViewModel
    @Environment(\.dismiss) private var dismiss
    var body: some View {
        VStack {
            Spacer()
            Text("Login")
                .font(.largeTitle)
                .bold()
                .padding()
            TextField("Email", text: $loginViewModel.email)
                .keyboardType(.emailAddress)
                .autocapitalization(.none)
                .padding()

            SecureField("Password", text: $loginViewModel.password)
                .textContentType(.password)
                .padding()

            Button("Login") {
                Task {
                    await loginViewModel.login()
                }
            }

            if loginViewModel.isLoading {
                ProgressView()
                    .padding()
            }

            if let errorMessage = loginViewModel.errorMessage {
                Text("Error: \(errorMessage)")
                    .foregroundColor(.red)
                    .padding()
            }
            
            Button("Don't have an account? Register") {
                loginViewModel.isRegistered = false
                loginViewModel.errorMessage = nil
                loginViewModel.email = ""
                loginViewModel.password = ""
                dismiss()
            }
                
            Spacer()
        }
        .onAppear(){
            loginViewModel.errorMessage = nil
            loginViewModel.email = ""
            loginViewModel.password = ""
        }
        .onDisappear(){
            loginViewModel.errorMessage = nil
            loginViewModel.email = ""
            loginViewModel.password = ""
        }
        .navigationDestination(isPresented: $loginViewModel.isRegistered) { NotesListView() }
    }
}

#Preview {
    LoginView()
}
