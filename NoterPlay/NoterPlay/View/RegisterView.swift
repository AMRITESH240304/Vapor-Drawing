//
//  RegisterView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 24/10/25.
//

import SwiftUI

struct RegisterView: View {
    @EnvironmentObject var registerViewModel: RegisterViewModel
    var body: some View {
            VStack{
                Spacer()
                    Text("Register")
                        .font(.largeTitle)
                        .bold()
                        .padding()
                TextField("Email",text: $registerViewModel.email)
                    .keyboardType(.emailAddress)
                    .autocapitalization(.none)
                    .padding()
                
                SecureField("Password", text: $registerViewModel.password)
                    .textContentType(.password)
                    .padding()
                
                Button("Register"){
                    Task{
                       try await registerViewModel.register()
                    }
                }
                
                if registerViewModel.isLoading{
                    ProgressView()
                        .padding()
                }
                
                if let errorMessage = registerViewModel.errorMessage{
                    Text("Error: \(errorMessage)")
                        .foregroundColor(.red)
                        .padding()
                }
                NavigationLink("Already have an account? Login", destination: LoginView())
                
                Spacer()
            }
            .navigationDestination(isPresented: $registerViewModel.isRegistered) { NotesListView() }
    }
}
