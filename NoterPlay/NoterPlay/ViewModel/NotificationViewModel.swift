//
//  NotificationViewModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 14/11/25.
//

import Foundation
import Combine

class NotificationViewModel: ObservableObject {
    @Published var message:[InviteResponse] = []
    private let webSocket = WS.shared
    private var cancellables = Set<AnyCancellable>()
    
    func getInviteFromWs() {
        webSocket.invitePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] invite in
                self?.message.append(invite)
            }
            .store(in: &cancellables)
    }
}
