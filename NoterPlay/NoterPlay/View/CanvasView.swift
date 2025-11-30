//
//  CanvasView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 18/10/25.
//

import PencilKit
import SwiftUI

struct CanvasView: UIViewRepresentable {
    @Binding var toolPickerShows: Bool
    let noteId: UUID
    @ObservedObject var viewModel: NotesViewModel
    let onCoordinatorReady: ((Coordinator) -> Void)?
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        let toolPicker = PKToolPicker()
        
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        Task { @MainActor in
            if let existingDrawing = await viewModel.getDrawing(noteID: noteId) {
                canvasView.drawing = existingDrawing
            }
        }
        
        // Set up tool picker properly
        canvasView.tool = PKInkingTool(.pen, color: .black, width: 15)
        
        // Show tool picker and make canvas first responder
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        // Store references in coordinator
        context.coordinator.canvasView = canvasView
        context.coordinator.toolPicker = toolPicker
        
        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        guard let toolPicker = context.coordinator.toolPicker else { return }
        
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        
        if toolPickerShows {
            canvasView.becomeFirstResponder()
        } else {
            canvasView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        let coordinator = Coordinator(noteId: noteId, viewModel: viewModel)
        onCoordinatorReady?(coordinator)
        return coordinator
    }
}

class Coordinator: NSObject, PKCanvasViewDelegate {
    let noteId: UUID
    let viewModel: NotesViewModel
    var canvasView: PKCanvasView?
    var toolPicker: PKToolPicker?
    
    init(noteId: UUID, viewModel: NotesViewModel) {
        self.noteId = noteId
        self.viewModel = viewModel
    }
    
    func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
        // Remove automatic saving - now only manual saves
        print("Drawing changed")
    }
    
    func saveDrawing() {
        guard let canvasView = canvasView else {
            print("Canvas view not available")
            return
        }
        print("Saving drawing...")
        Task { @MainActor in
            print(canvasView.drawing)
            await viewModel.updateNoteDrawing(noteId: noteId, drawing: canvasView.drawing)
        }
    }
    
    func inviteUser(to email: String) async {
        await viewModel.sendInvite(SendInviteRequest(email: email, noteID: noteId))
    }
}
