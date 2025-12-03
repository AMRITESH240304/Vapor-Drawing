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
//                guard let self = self else { return }
                
                if message.type == "strokeUpdate",
                   let payload = message.payload,
                   let jsonData = payload.data(using: .utf8),
                   let drawingStroke = try? JSONDecoder().decode(DrawingStroke.self, from: jsonData),
                   let pkStroke = drawingStroke.toPKStroke() {
                    
                    print("✅ Received complete stroke with \(drawingStroke.points.count) points")
                    
                    // Apply to drawing without triggering sendStrokeUpdate
                    DispatchQueue.main.async {
                        var mutableDrawing = self.drawing
                        mutableDrawing.strokes.append(pkStroke)
                        self.drawing = mutableDrawing
                    }
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
        context.coordinator.isReceivingRemoteUpdate = true
        if canvasView.drawing != drawing {
            canvasView.drawing = drawing
        }
        context.coordinator.lastStrokeCount = drawing.strokes.count
        context.coordinator.isReceivingRemoteUpdate = false
    }
    
    func makeCoordinator() -> Coordinator {
        Coordinator(drawing: $drawing, noteID: noteID)
    }
    
    class Coordinator: NSObject, PKCanvasViewDelegate {
        @Binding var drawing: PKDrawing
        let noteID: UUID
        var lastStrokeCount = 0
        var isReceivingRemoteUpdate = false
        
        init(drawing: Binding<PKDrawing>, noteID: UUID) {
            _drawing = drawing
            self.noteID = noteID
            super.init()
            self.lastStrokeCount = drawing.wrappedValue.strokes.count
        }
        
        func canvasViewDrawingDidChange(_ canvasView: PKCanvasView) {
            // Don't send updates if we're receiving remote changes
            if isReceivingRemoteUpdate {
                return
            }
            
            drawing = canvasView.drawing
            
            let currentStrokes = canvasView.drawing.strokes
            
            // Only send when a NEW complete stroke is added (count increases)
            if currentStrokes.count > lastStrokeCount {
                // Get all new strokes since last count
                let newStrokes = currentStrokes.suffix(currentStrokes.count - lastStrokeCount)
                
                for newPKStroke in newStrokes {
                    let drawingStroke = newPKStroke.toDrawingStroke()
                    WS.shared.sendStrokeUpdate(noteID: noteID, stroke: drawingStroke)
                    print("📤 Sent complete stroke with \(drawingStroke.points.count) points")
                }
                
                lastStrokeCount = currentStrokes.count
            }
        }
        
        func applyRemoteStroke(_ stroke: PKStroke, to canvasView: PKCanvasView) {
            isReceivingRemoteUpdate = true
            var mutableDrawing = canvasView.drawing
            mutableDrawing.strokes.append(stroke)
            canvasView.drawing = mutableDrawing
            drawing = mutableDrawing
            lastStrokeCount = mutableDrawing.strokes.count
            isReceivingRemoteUpdate = false
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


extension WS {
    func sendStrokeUpdate(noteID: UUID, stroke: DrawingStroke) {
        if let jsonData = try? JSONEncoder().encode(stroke),
           let jsonString = String(data: jsonData, encoding: .utf8) {
            let msg = WebSocketMessage(type: "strokeUpdate", noteID: noteID, payload: jsonString)
            sendMessage(msg)
        }
    }
}
