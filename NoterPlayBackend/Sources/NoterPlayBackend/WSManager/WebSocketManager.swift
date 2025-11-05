import Vapor
import Foundation
import NIOConcurrencyHelpers

final class WebSocketManager {
    private var connections: [WebSocket] = []
    private let lock = NIOLock()
    
    
}