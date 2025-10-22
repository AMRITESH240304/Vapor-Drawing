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
    let userId: String = UUID().uuidString
    
    func addNote(title: String) async {
        let newNote = Note(id: UUID(), title: title, dateCreated: Date())
        notes.append(newNote)
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
}
