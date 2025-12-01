import Vapor
import Foundation
import NIOConcurrencyHelpers

final class WebSocketManager: @unchecked Sendable {
    
    private let lock = NIOLock()
    private var connections: [UUID: WebSocket] = [:]
    private var noteCollaborators: [UUID: Set<UUID>] = [:]

    func addConnection(webSocket:WebSocket, userID: UUID) {
        lock.withLock {
            connections[userID] = webSocket
        }
    }
    
    func disConnect(userID: UUID) {
        let _ = lock.withLock {
            connections.removeValue(forKey: userID)

            for noteID: UUID in noteCollaborators.keys {
                noteCollaborators[noteID]?.remove(userID)
            }
        }
    }

    func joinNoteSession(noteID: UUID, userID: UUID){
        lock.withLock {
            if noteCollaborators[noteID] == nil {
                noteCollaborators[noteID] = Set<UUID>()
            }
            noteCollaborators[noteID]?.insert(userID)
        }
    }

    func leaveNoteSession(noteID: UUID, userID: UUID){
        lock.withLock{
            noteCollaborators[noteID]?.remove(userID)
            if noteCollaborators[noteID]?.isEmpty == true {
                noteCollaborators.removeValue(forKey: noteID)
            }
        }
    }

    func sendPersonalMessage(userID: UUID, message: String) {
        lock.withLock {
            if let ws = connections[userID] {
                ws.send(message)
            }
        }
    }

    func broadcastToNote(noteID: UUID, message: String, excludeUserID: UUID? = nil) {
        lock.withLock {
            guard let collaborators = noteCollaborators[noteID] else { return }

            for userID in collaborators {
                if let excludeID = excludeUserID, userID == excludeID {
                    continue
                }
                if let ws = connections[userID] {
                    ws.send(message)
                }
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