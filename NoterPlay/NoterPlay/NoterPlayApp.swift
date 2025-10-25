//
//  NoterPlayApp.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 17/10/25.
//

import SwiftUI

@main
struct NoterPlayApp: App {
    @StateObject var registerViewModel: RegisterViewModel = RegisterViewModel()
    var body: some Scene {
        WindowGroup {
            ContentView()
                .preferredColorScheme(.dark)
                .environmentObject(registerViewModel)
        }
    }
}

