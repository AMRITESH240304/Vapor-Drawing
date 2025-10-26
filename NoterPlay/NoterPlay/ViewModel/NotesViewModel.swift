//
//  NotesViewModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 18/10/25.
//

import Foundation
import Combine
import PencilKit

@MainActor
class NotesViewModel: ObservableObject {
    @Published var notes: [Note] = []
    @Published var allNotes: NoteResponse?
    @Published var isLoading: Bool = false
    @Published var errorMessage: String?
    let userId: String = UUID().uuidString
    
    func addNote(title: String) async {
        isLoading = true
        errorMessage = nil
        let newNote = Note(id: UUID(), title: title, createdAt: Date(),updatedAt: Date())
        
        do {
            try await NoteNetworkManager.shared.creatNotes(Note: newNote, token: UserDefaults.standard.string(forKey: "authToken")!) { result in
                
                switch result {
                case .success(let message):
                    DispatchQueue.main.async {
                        self.isLoading = false
                        print(message)
                    }
                case .failure(let error):
                    DispatchQueue.main.async {
                        self.errorMessage = error.localizedDescription
                        self.isLoading = false
                    }
                }
            }
            notes.append(newNote)
        }
        catch {
            print("Error creating note: \(error)")
        }
    }
    
    func deleteNote(_ id: UUID) async -> Void {
        let index = notes.first(where: {$0.id == id})
        
        if let index {
            notes.removeAll(where: {$0.id == index.id})
        }
    }
    
    func updateNoteDrawing(noteId: UUID, drawing: PKDrawing) async {
        if let index = notes.firstIndex(where: { $0.id == noteId }) {
            // Convert PKDrawing to strokes array
            notes[index].strokes = drawing.strokes.map { $0.toDrawingStroke(userId: userId) }
        }
    }
    
    func fetchNotes() async {
        isLoading = true
        errorMessage = nil
        
        do {
            try await NoteNetworkManager.shared.getAllUserNotes(token: UserDefaults.standard.string(forKey: "authToken")!) { result in
                switch result {
                case .success(let fetchedNotes):
                    DispatchQueue.main.async {
                        self.notes = fetchedNotes.notes
                        self.allNotes = fetchedNotes
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
}
