//
//  ContentView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 17/10/25.
//

import SwiftUI

struct ContentView: View {
    @StateObject private var notification = NotificationViewModel()
    @State private var toolPickerShows = true
    var body: some View {
        NavigationStack {
            RegisterView()
        }
        .environmentObject(notification)
    }
}

#Preview {
    ContentView()
}
