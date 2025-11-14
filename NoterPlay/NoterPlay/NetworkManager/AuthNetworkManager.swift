//
//  AuthNetworkManager.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 24/10/25.
//

import Foundation

@MainActor
final class AuthNetworkManager {
    static let shared = AuthNetworkManager()

    // using trailing closure
    func registerUser(email:String, password:String, completion: @escaping (Result<String, Error>) async throws -> Void) async throws {
        
        let parameter = RegisterRequest(email: email, password: password)
        
        var request = URLRequest(url: URL(string: NetworkUrls.production + "auth/register")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(parameter)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            
            print( String(data: data, encoding: .utf8)!)
            let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
            let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
            try await completion(.success(registerResponse.token))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }
    }
    
    func loginUser(email:String, password:String, completion: @escaping (Result<String, Error>) async throws -> Void) async throws {
        let parameter = RegisterRequest(email: email, password: password)
        
        var request = URLRequest(url: URL(string: NetworkUrls.production + "auth/login")!)
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(parameter)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
            let registerResponse = try decoder.decode(RegisterResponse.self, from: data)
        
            try await completion(.success(registerResponse.token))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }

    }

}
