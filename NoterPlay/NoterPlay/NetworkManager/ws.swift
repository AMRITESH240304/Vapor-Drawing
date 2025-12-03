import Foundation
import Combine

// Mirror of backend message struct
struct WebSocketMessage: Codable {
    let type: String
    let noteID: UUID?
    let payload: String?
}

class WS: ObservableObject {
    static let shared = WS()
    
    private var urlSession: URLSession?
    private var webSocketTask: URLSessionWebSocketTask?
    
    // Existing invite publisher
    let invitePublisher = PassthroughSubject<InviteResponse, Never>()
    
    // New publisher to send note updates to canvas coordinators
    let noteUpdatePublisher = PassthroughSubject<WebSocketMessage, Never>()
    
    private var receiveCancellable: AnyCancellable?
    
    init() {}
    
    func start() {
        connect()
        recieveData()
    }
    
    func connect() {
        guard let url = URL(string: NetworkUrls.wsURL) else {
            print("Invalid WebSocket URL")
            return
        }

        var request = URLRequest(url: url)
        request.timeoutInterval = 10
        if let token = UserDefaults.standard.string(forKey: "authToken") {
            request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        }
        
        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        print("WebSocket connected with Authorization header")
    }
    
    func recieveData() {
        webSocketTask?.receive { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
                // optionally attempt reconnect or inform UI
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Received data: \(data)")
                case .string(let text):
                    self.handleIncomingText(text)
                @unknown default:
                    print("Received unknown message")
                }
                // Continue receiving
                self.recieveData()
            }
        }
    }
    
    private func handleIncomingText(_ text: String) {
        // Try InviteResponse first (existing behavior)
        if let jsonData = text.data(using: .utf8) {
            let decoder = JSONDecoder()
            if let personalResponse = try? decoder.decode(InviteResponse.self, from: jsonData) {
                DispatchQueue.main.async { [weak self] in
                    self?.invitePublisher.send(personalResponse)
                }
                return
            }
            
            // Try WebSocketMessage (note updates or control messages)
            if let wsMessage = try? decoder.decode(WebSocketMessage.self, from: jsonData) {
                // If it's a note update, forward to the canvas coordinator
                DispatchQueue.main.async { [weak self] in
                    self?.noteUpdatePublisher.send(wsMessage)
                }
                return
            }
            
            // Unknown JSON
            print("Received unrecognized JSON message: \(text)")
        }
    }
    
    func sendMessage(_ msg: WebSocketMessage) {
        let encoder = JSONEncoder()
        guard let data = try? encoder.encode(msg),
              let text = String(data: data, encoding: .utf8) else {
            print("Failed to encode WebSocketMessage")
            return
        }
        webSocketTask?.send(.string(text)) { error in
            if let error = error {
                print("WebSocket send error: \(error)")
            }
        }
    }
    
    // Convenience helpers
    func sendJoin(noteID: UUID) {
        let msg = WebSocketMessage(type: "joinNote", noteID: noteID, payload: nil)
        sendMessage(msg)
    }
    
    func sendLeave(noteID: UUID) {
        let msg = WebSocketMessage(type: "leaveNote", noteID: noteID, payload: nil)
        sendMessage(msg)
    }
    
    func sendNoteUpdate(noteID: UUID, base64DrawingPayload: String) {
        let msg = WebSocketMessage(type: "noteUpdate", noteID: noteID, payload: base64DrawingPayload)
        sendMessage(msg)
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        urlSession = nil
        webSocketTask = nil
    }
}
