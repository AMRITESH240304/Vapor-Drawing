//
//  ContentView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 17/10/25.
//

import SwiftUI

struct ContentView: View {
    @State private var toolPickerShows = true
    var body: some View {
        NavigationStack {
            if UserDefaults.standard.string(forKey: "authToken") != nil {
                NotesListView()
            } else {
                RegisterView()
            }
        }
    }
}

#Preview {
    ContentView()
}
