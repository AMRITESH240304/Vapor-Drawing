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
    
    private let canvasView = PKCanvasView()
    private let toolPicker = PKToolPicker()

    func makeUIView(context: Context) -> PKCanvasView {
        canvasView.drawingPolicy = .anyInput
        
        canvasView.delegate = context.coordinator
        
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        
        if toolPickerShows {
            canvasView.becomeFirstResponder()
        }

        return canvasView
    }

    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        toolPicker.setVisible(toolPickerShows, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        
        if toolPickerShows {
            canvasView.becomeFirstResponder()
        } else {
            canvasView.resignFirstResponder()
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(noteId: noteId, viewModel: viewModel)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        let noteId: UUID
        let viewModel: NotesViewModel
        
        init(noteId: UUID, viewModel: NotesViewModel) {
            self.noteId = noteId
            self.viewModel = viewModel
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            Task { @MainActor in
                await viewModel.updateNoteDrawing(noteId: noteId, drawing: canvasView.drawing)
            }
        }
    }
}

