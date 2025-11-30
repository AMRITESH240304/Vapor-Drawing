//
//  NotificationViewModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 14/11/25.
//

import Foundation
import Combine
import PencilKit

class NotificationViewModel: ObservableObject {
    @Published var message:[InviteResponse] = []
    private let webSocket = WS.shared
    private var cancellables = Set<AnyCancellable>()
    @Published var shareToken: String = ""
    
    @Published var notes: [Note] = []
    @Published var allNotes: NoteResponse?
    
    init() {
        getInviteFromWs()
    }
    
    func getInviteFromWs() {
        webSocket.invitePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] invite in
                self?.message.append(invite)
            }
            .store(in: &cancellables)
    }
    
    func getSharedNote() async -> PKDrawing? {
        
        return await withCheckedContinuation { continuation in
            Task {
                do {
                    try await NoteNetworkManager.shared.getSharedNote(shareToken) { result in
                        switch result {
                        case .success(let fetchedNote):
//                            print("Drawing fetched for note ID: \(noteID)")
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
}
