//
//  NotesListView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 18/10/25.
//

import SwiftUI

struct NotesListView: View {
    @Namespace private var namespace
    @StateObject var viewModel = NotesViewModel()
    @State private var showNewNoteAlert = false
    @State private var newNoteTitle = ""
    @State private var toolPickerVisible = true
    @State private var canvasCoordinator: CanvasView.Coordinator?

    var body: some View {
        VStack {
            List {
                ForEach(viewModel.notes) { note in
                    NavigationLink(
                        destination: CanvasView(
                            toolPickerShows: $toolPickerVisible,
                            noteId: note.id,
                            viewModel: viewModel,
                            onCoordinatorReady: { coordinator in
                                canvasCoordinator = coordinator
                            }
                        )
                        .navigationTitle(note.title)
                        .navigationBarTitleDisplayMode(.inline)
                        .navigationTransition(.zoom(sourceID: "zoom", in: namespace))
                        .toolbar {
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    toolPickerVisible.toggle()
                                } label: {
                                    Image(systemName: toolPickerVisible ? "pencil.circle.fill" : "pencil.circle")
                                        .font(.title2)
                                }
                            }
                            
                            ToolbarItem(placement: .topBarTrailing) {
                                Button {
                                    canvasCoordinator?.saveDrawing()
                                }
                                label: {
                                    // need a save button
                                    Image(systemName: "square.and.arrow.down")
                                        .font(.title2)
                                        
                                }
                            }
                        }
                    ) {
                        VStack(alignment: .leading) {
                            Text(note.title)
                                .font(.headline)
                            Text(
                                note.createdAt!.formatted(
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
        .onAppear(){
            Task {
                await viewModel.fetchNotes()
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
            
            ToolbarItem(placement: .topBarTrailing) {
                NavigationLink(destination: NotificationView()) {
                    Image(systemName: "bell.fill")
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
