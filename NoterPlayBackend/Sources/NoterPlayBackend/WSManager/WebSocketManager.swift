import Vapor
import Foundation
import NIOConcurrencyHelpers

final class WebSocketManager: @unchecked Sendable {
    
    private var connections: [UUID: WebSocket] = [:]
    private let lock = NIOLock()

    func addConnection(webSocket:WebSocket, userID: UUID) {
        lock.withLock {
            connections[userID] = webSocket
        }
    }
    
    func disConnect(userID: UUID) {
        let _ = lock.withLock {
            connections.removeValue(forKey: userID)
        }
    }

    func sendPersonalMessage(userID: UUID, message: String) {
        lock.withLock {
            if let ws = connections[userID] {
                ws.send(message)
            }
        }
    }

    func broadcastMessage(message: String) {
        lock.withLock {
            for (_, ws) in connections {
                ws.send(message)
            }
        }
    }
    
}