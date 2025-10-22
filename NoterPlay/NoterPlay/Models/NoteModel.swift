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
    let dateCreated: Date
    var strokes: [DrawingStroke] = []
    
    // Convert to dictionary for MongoDB
    func toMongoDocument() -> [String: Any] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        
        let strokesData = (try? encoder.encode(strokes)) ?? Data()
        let strokesJSON = (try? JSONSerialization.jsonObject(with: strokesData)) as? [[String: Any]] ?? []
        
        return [
            "id": id.uuidString,
            "title": title,
            "dateCreated": ISO8601DateFormatter().string(from: dateCreated),
            "strokes": strokesJSON
        ]
    }
    
    // Initialize from MongoDB document
    static func fromMongoDocument(_ doc: [String: Any]) -> Note? {
        guard let idString = doc["id"] as? String,
              let id = UUID(uuidString: idString),
              let title = doc["title"] as? String,
              let dateString = doc["dateCreated"] as? String,
              let date = ISO8601DateFormatter().date(from: dateString) else {
            return nil
        }
        
        var note = Note(id: id, title: title, dateCreated: date)
        
        if let strokesArray = doc["strokes"] as? [[String: Any]] {
            let strokesData = try? JSONSerialization.data(withJSONObject: strokesArray)
            if let data = strokesData {
                let decoder = JSONDecoder()
                decoder.dateDecodingStrategy = .iso8601
                note.strokes = (try? decoder.decode([DrawingStroke].self, from: data)) ?? []
            }
        }
        
        return note
    }
    
    // Convert strokes to PKDrawing for display
    func toPKDrawing() -> PKDrawing {
        var drawing = PKDrawing()
        let pkStrokes = strokes.compactMap { $0.toPKStroke() }
        drawing.strokes = pkStrokes
        return drawing
    }
}

