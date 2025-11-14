//
//  NoteNetworkManager.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 26/10/25.
//

import Foundation

@MainActor
class NoteNetworkManager {
    static let shared = NoteNetworkManager()
    
    func getAllUserNotes(token:String,completetion: @escaping (Result<NoteResponse, Error>) async throws -> Void) async throws {
        
        var request = URLRequest(url: URL(string: NetworkUrls.production + "notes")!)
        
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            print( String(data: data, encoding: .utf8)!)
            let notes = try decoder.decode(NoteResponse.self, from: data)
            try await completetion(.success(notes))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }
    }
    
    func getNote(note:Note, token:String, completion: @escaping (Result<Note, Error>) async throws -> Void) async throws {
        var request = URLRequest(url: URL(string: NetworkUrls.production + "notes/get/\(note.id)")!)
        request.httpMethod = "GET"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        print( String(data: data, encoding: .utf8)!)
        
        if (200...299).contains(httpResponse.statusCode) {
            print( String(data: data, encoding: .utf8)!)
            let decoder = JSONDecoder()
            decoder.dateDecodingStrategy = .iso8601
            let note = try decoder.decode(Note.self, from: data)
            try await completion(.success(note))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }
    }
    
    func updateDrawing(Note: Note, token: String, completion: @escaping (Result<String, Error>) async throws -> Void) async throws {
        var request = URLRequest(url: URL(string: NetworkUrls.production + "notes/\(Note.id)")!)
        request.httpMethod = "PUT"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let encodedData = try encoder.encode(Note)

        let (data, response) = try await URLSession.shared.upload(for: request, from: encodedData)

        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }

        if (200...299).contains(httpResponse.statusCode) {
            print(String(data: data, encoding: .utf8) ?? "")
            try await completion(.success("Note Updated Successfully"))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }
    }


    
    func creatNotes(Note:Note, token:String, completion: @escaping (Result<String, Error>) async throws -> Void) async throws {
        
        var request = URLRequest(url: URL(string: NetworkUrls.production + "notes")!)
        
        request.httpMethod = "POST"
        request.setValue("application/json", forHTTPHeaderField: "Content-Type")
        request.setValue("Bearer \(token)", forHTTPHeaderField: "Authorization")
        
        request.httpBody = try JSONEncoder().encode(Note)
        
        let (data, response) = try await URLSession.shared.data(for: request)
        
        guard let httpResponse = response as? HTTPURLResponse else {
            throw URLError(.badServerResponse)
        }
        
        if (200...299).contains(httpResponse.statusCode) {
            print( String(data: data, encoding: .utf8)!)
            try await completion(.success("Note Created Successfully"))
        } else {
            if let serverError = try? JSONDecoder().decode(ServerErrorResponse.self, from: data) {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: serverError.reason])
            } else {
                throw NSError(domain: "", code: httpResponse.statusCode, userInfo: [NSLocalizedDescriptionKey: "Unknown error occurred"])
            }
        }

    }
}
