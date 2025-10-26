//
//  NotesModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 18/10/25.
//

import Foundation
import PencilKit

struct Note: Identifiable, Codable {
    let id: UUID
    let title: String
    let createdAt: Date?
    let updatedAt: Date?
    var strokes: [DrawingStroke] = []
    
    // Custom initializer for decoding
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle ID as either UUID or String
        if let uuidString = try? container.decode(String.self, forKey: .id) {
            guard let uuid = UUID(uuidString: uuidString) else {
                throw DecodingError.dataCorruptedError(forKey: .id, in: container, debugDescription: "Invalid UUID string")
            }
            self.id = uuid
        } else {
            self.id = try container.decode(UUID.self, forKey: .id)
        }
        
        self.title = try container.decode(String.self, forKey: .title)
        self.createdAt = try container.decodeIfPresent(Date.self, forKey: .createdAt)
        self.updatedAt = try container.decodeIfPresent(Date.self, forKey: .updatedAt)
        self.strokes = try container.decodeIfPresent([DrawingStroke].self, forKey: .strokes) ?? []
    }
    
    // Regular initializer for creating new notes
    init(id: UUID = UUID(), title: String, createdAt: Date? = nil, updatedAt: Date? = nil, strokes: [DrawingStroke] = []) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
        self.strokes = strokes
    }
    
    // Custom encoding - always encode ID as string
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id.uuidString, forKey: .id)
        try container.encode(title, forKey: .title)
        try container.encodeIfPresent(createdAt, forKey: .createdAt)
        try container.encodeIfPresent(updatedAt, forKey: .updatedAt)
        try container.encode(strokes, forKey: .strokes)
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, title, createdAt, updatedAt, strokes
    }
    
    // Convert strokes to PKDrawing for display
    func toPKDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        let pkStrokes = strokes.compactMap { $0.toPKStroke() }
        drawing.strokes = pkStrokes
        return drawing
    }
}

struct NoteResponse: Codable {
    let notes: [Note]
    let total: Int
}
