//
//  NotesListView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 18/10/25.
//

import SwiftUI

struct NotesListView: View {
    @StateObject var viewModel = NotesViewModel()
    @State private var showNewNoteAlert = false
    @State private var newNoteTitle = ""

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.notes) { note in
                    NavigationLink(
                        destination: CanvasView(
                            toolPickerShows: .constant(true),
                            noteId: note.id,
                            viewModel: viewModel
                        )
                        .navigationTitle(note.title)
                    ) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(
                                note.dateCreated.formatted(
                                    date: .abbreviated,
                                    time: .shortened
                                )
                            )
                            .font(.caption)
                            .foregroundColor(.secondary)
                        }
                    }
                }
            }
        }
        .navigationBarBackButtonHidden()
        .navigationTitle("My Notes")
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                Button {
                    showNewNoteAlert = true
                } label: {
                    Image(systemName: "plus.circle.fill")
                        .font(.title2)
                }
            }
        }
        .alert("New Note", isPresented: $showNewNoteAlert) {
            TextField("Enter note name", text: $newNoteTitle)
            Button("Create") {
                Task {
                    if !newNoteTitle.trimmingCharacters(in: .whitespaces)
                        .isEmpty
                    {
                        await viewModel.addNote(title: newNoteTitle)
                        newNoteTitle = ""
                    }
                }
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Enter a name for your new note.")
        }
    }
}

#Preview {
    NotesListView()
}
