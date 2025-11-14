import Foundation
import Combine

class WS: ObservableObject{
    static let shared = WS()
    
    private var urlSession: URLSession?
    
    private var webSocketTask: URLSessionWebSocketTask?
    
    let invitePublisher = PassthroughSubject<InviteResponse, Never>()
    
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
        let token = UserDefaults.standard.string(forKey: "authToken")!
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        urlSession = URLSession(configuration: .default)
        webSocketTask = urlSession?.webSocketTask(with: request)
        webSocketTask?.resume()
        
        print("WebSocket connected with Authorization header")
    }
    
    func recieveData() {
        webSocketTask?.receive { [weak self] result in
            switch result {
            case .failure(let error):
                print("WebSocket receive error: \(error)")
            case .success(let message):
                switch message {
                case .data(let data):
                    print("Received data: \(data)")
                case .string(let text):
                    print("Received text: \(text)")
                    
                    if let jsonData = text.data(using: .utf8) {
                        do {
                            let decoder = JSONDecoder()
                            if let personalResponse = try? decoder.decode(InviteResponse.self, from: jsonData) {
                                DispatchQueue.main.async { [weak self] in
                                    self?.invitePublisher.send(personalResponse)
                                }
                            }
                        }
                        catch {
                            print("Failed to decode JSON: \(error)")
                        }
                    }
                @unknown default:
                    print("Received unknown message")
                }
                // Continue receiving
                self?.recieveData()
            }
        }
    }
    
    func disconnect() {
        webSocketTask?.cancel(with: .goingAway, reason: nil)
        urlSession = nil
        webSocketTask = nil
    }
}
