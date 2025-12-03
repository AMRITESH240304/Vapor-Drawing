//
//  NotificationView.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 11/11/25.
//

import SwiftUI
import PencilKit

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
    @EnvironmentObject private var viewModel: NotificationViewModel
    @State private var drawing: PKDrawing?
    @State private var isLoading = true
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView("Loading shared drawing...")
            } else if let drawing = drawing {
                PKCanvasViewRepresentable(drawing: .constant(drawing))
                    .navigationTitle("Shared Drawing")
                    .navigationBarTitleDisplayMode(.inline)
            } else {
                Text("Failed to load drawing")
                    .foregroundColor(.gray)
            }
        }
        .task {
            viewModel.shareToken = shareToken
            drawing = await viewModel.getSharedNote()
            isLoading = false
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
