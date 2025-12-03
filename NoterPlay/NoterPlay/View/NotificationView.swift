//
//  NotificationView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 11/11/25.
//

import SwiftUI
import PencilKit
import Combine

struct NotificationView: View {
    @EnvironmentObject var notificationViewModel: NotificationViewModel
    @State private var selectedInvite: InviteResponse?
    @State private var navigateToSharedDrawing = false

    var body: some View {
        VStack {
            if notificationViewModel.message.isEmpty {
                Text("No notifications yet")
                    .foregroundColor(.gray)
                    .padding()
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(notificationViewModel.message) { invite in
                            Button {
                                selectedInvite = invite
                                navigateToSharedDrawing = true
                            } label: {
                                Text("Someone invited you to collaborate on a note")
                                    .padding()
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(Color.blue.opacity(0.1))
                                    .cornerRadius(8)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationDestination(isPresented: $navigateToSharedDrawing) {
            if let invite = selectedInvite {
                SharedDrawingView(shareToken: invite.shareToken, wssURL: invite.wssURL)
            }
        }
    }
}

struct SharedDrawingView: View {
    let shareToken: String
    let wssURL: String
    @State private var drawing: PKDrawing = PKDrawing()
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var noteID: UUID?
    @State private var cancellable: AnyCancellable?
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading shared drawing...")
            } else if let error = errorMessage {
                VStack {
                    Text("Error loading drawing")
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(.gray)
                }
            } else {
                SharedCanvasView(drawing: $drawing, noteID: noteID!)
                    .navigationTitle("Shared Drawing")
                    .navigationBarTitleDisplayMode(.inline)
            }
        }
        .task {
            await loadDrawing()
            setupWebSocketListener()
        }
        .onDisappear {
            if let noteID = noteID {
                WS.shared.sendLeave(noteID: noteID)
            }
            cancellable?.cancel()
        }
    }
    
    private func loadDrawing() async {
        do {
            let note = try await withCheckedThrowingContinuation { continuation in
                Task {
                    do {
                        try await NoteNetworkManager.shared.getSharedNote(shareToken) { result in
                            switch result {
                            case .success(let fetchedNote):
                                print("✅ Shared drawing fetched successfully")
                                continuation.resume(returning: fetchedNote)
                            case .failure(let error):
                                print("❌ Fetch error: \(error.localizedDescription)")
                                continuation.resume(throwing: error)
                            }
                        }
                    } catch {
                        print("❌ Network error: \(error)")
                        continuation.resume(throwing: error)
                    }
                }
            }
            
            noteID = note.id
            drawing = note.toPKDrawing()
            
            // Join the WebSocket room
            WS.shared.sendJoin(noteID: noteID!)
            isLoading = false
        } catch {
            errorMessage = error.localizedDescription
            isLoading = false
        }
    }
    
    private func setupWebSocketListener() {
        cancellable = WS.shared.noteUpdatePublisher
            .filter { $0.noteID == noteID }
            .sink { message in
                guard message.type == "noteUpdate",
                      let payload = message.payload,
                      let data = Data(base64Encoded: payload) else {
                    return
                }
                
                do {
                    let updatedDrawing = try PKDrawing(data: data)
                    drawing = updatedDrawing
                    print("✅ Received drawing update via WebSocket")
                } catch {
                    print("❌ Failed to decode drawing: \(error)")
                }
            }
    }
}

struct SharedCanvasView: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    let noteID: UUID
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        canvasView.delegate = context.coordinator
        
        let toolPicker = PKToolPicker()
        toolPicker.setVisible(true, forFirstResponder: canvasView)
        toolPicker.addObserver(canvasView)
        canvasView.becomeFirstResponder()
        
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, noteID: noteID)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let noteID: UUID
        
        init(drawing: Binding<PKDrawing>, noteID: UUID) {
            _drawing = drawing
            self.noteID = noteID
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            drawing = canvasView.drawing
            
            // Send update via WebSocket
            let data = canvasView.drawing.dataRepresentation()
            let base64 = data.base64EncodedString()

            WS.shared.sendNoteUpdate(noteID: noteID, base64DrawingPayload: base64)
            print("📤 Sent drawing update via WebSocket")

        }
    }
}

struct PKCanvasViewRepresentable: UIViewRepresentable {
    @Binding var drawing: PKDrawing
    
    func makeUIView(context: Context) -> PKCanvasView {
        let canvasView = PKCanvasView()
        canvasView.drawing = drawing
        canvasView.drawingPolicy = .anyInput
        return canvasView
    }
    
    func updateUIView(_ canvasView: PKCanvasView, context: Context) {
        canvasView.drawing = drawing
    }
}
