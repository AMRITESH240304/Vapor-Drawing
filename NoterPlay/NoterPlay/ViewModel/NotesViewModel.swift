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
    @Published var shareTokenAvailable: Bool = false
    
    func sendInvite(_ item: SendInviteRequest) async -> InviteResponse? {
        do {
            return try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        try await NoteNetworkManager.shared.inviteUserToNote(item, token: UserDefaults.standard.string(forKey: "authToken")!){ result in
                            switch result {
                            case .success(let response):
                                print("✅ Invite sent successfully")
                                print(response)
                                continuation.resume(returning: response)
                            case .failure(let error):
                                print("❌ Invite error: \(error.localizedDescription)")
                                continuation.resume(throwing: error)
                            }
                        }
                    } catch {
                        print("❌ Network error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
        } catch {
            print("Error sending invite: \(error)")
            errorMessage = error.localizedDescription
            return nil
        }
    }
    
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
    
    func getDrawing(noteID: UUID) async -> PKDrawing? {
            guard let note = notes.first(where: { $0.id == noteID }) else {
                print("Note not found with ID: \(noteID)")
                return nil
            }
            
            return await withCheckedContinuation { continuation in
                Task {
                    do {
                        try await NoteNetworkManager.shared.getNote(note: note, token: UserDefaults.standard.string(forKey: "authToken")!) { result in
                            switch result {
                            case .success(let fetchedNote):
                                print("Drawing fetched for note ID: \(noteID)")
                                let drawing = fetchedNote.toPKDrawing()
                                continuation.resume(returning: drawing)
                            case .failure(let error):
                                print("Fetch error: \(error.localizedDescription)")
                                continuation.resume(returning: nil)
                            }
                        }
                    } catch {
                        print("Network error: \(error)")
                        continuation.resume(returning: nil)
                    }
                }
            }
        }
    
    func updateNoteDrawing(noteId: UUID, drawing: PKDrawing) async {
        do {
            // Update local notes first
            if let index = notes.firstIndex(where: { $0.id == noteId }) {
                notes[index].strokes = drawing.strokes.map { $0.toDrawingStroke() }
                
                // Create note object for network call
                let noteToUpdate = notes[index]
                print(noteToUpdate)
                
                try await NoteNetworkManager.shared.updateDrawing(
                    Note: noteToUpdate,
                    token: UserDefaults.standard.string(forKey: "authToken")!
                ) { result in
                    switch result {
                    case .success(let message):
                        DispatchQueue.main.async {
                            print("Drawing saved: \(message)")
                        }
                    case .failure(let error):
                        DispatchQueue.main.async {
                            self.errorMessage = error.localizedDescription
                            print("Save error: \(error.localizedDescription)")
                        }
                    }
                }
            }
        } catch {
            print("Error updating note drawing: \(error)")
            errorMessage = error.localizedDescription
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
