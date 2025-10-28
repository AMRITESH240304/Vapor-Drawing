//
//  DrawingStroke.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 20/10/25.
//

import Foundation
import PencilKit
import UIKit

struct DrawingStroke: Codable, Identifiable {
    let id: UUID
    let points: [StrokePoint]
    let color: ColorData
    let width: Double
    let toolType: String
    let timestamp: Date
    let userId: String
    
    // Standard initializer
    init(id: UUID, points: [StrokePoint], color: ColorData, width: Double, toolType: String, timestamp: Date, userId: String) {
        self.id = id
        self.points = points
        self.color = color
        self.width = width
        self.toolType = toolType
        self.timestamp = timestamp
        self.userId = userId
    }
    
    // Custom decoder to handle missing fields from server
    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        
        // Handle missing ID - generate new one
        if let decodedId = try? container.decode(UUID.self, forKey: .id) {
            self.id = decodedId
        } else {
            self.id = UUID()
        }
        
        self.points = try container.decode([StrokePoint].self, forKey: .points)
        self.color = try container.decode(ColorData.self, forKey: .color)
        self.width = try container.decode(Double.self, forKey: .width)
        
        // Handle missing toolType - default to "pen"
        if let decodedToolType = try? container.decode(String.self, forKey: .toolType) {
            self.toolType = decodedToolType
        } else {
            self.toolType = "pen"
        }
        
        self.timestamp = try container.decode(Date.self, forKey: .timestamp)
        
        // Handle missing userId - generate default
        if let decodedUserId = try? container.decode(String.self, forKey: .userId) {
            self.userId = decodedUserId
        } else {
            self.userId = "unknown"
        }
    }
    
    private enum CodingKeys: String, CodingKey {
        case id, points, color, width, toolType, timestamp, userId
    }
}

struct StrokePoint: Codable {
    let x: Double
    let y: Double
    let force: Double
    let azimuth: Double
    let altitude: Double
}

struct ColorData: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
}

extension PKStroke {
    func toDrawingStroke(userId: String) -> DrawingStroke {
        let points = self.path.map { point in
            StrokePoint(
                x: Double(point.location.x),
                y: Double(point.location.y),
                force: Double(point.force),
                azimuth: Double(point.azimuth),
                altitude: Double(point.altitude)
            )
        }
        
        let color = self.ink.color
        var red: CGFloat = 0, green: CGFloat = 0, blue: CGFloat = 0, alpha: CGFloat = 0
        color.getRed(&red, green: &green, blue: &blue, alpha: &alpha)
        
        let toolType: String
        switch self.ink.inkType {
        case .pen: toolType = "pen"
        case .pencil: toolType = "pencil"
        case .marker: toolType = "marker"
        default: toolType = "pen"
        }
        
        let derivedWidth: Double = {
            if let firstPoint = self.path.first {
                return Double(firstPoint.size.width)
            } else {
                return 1.0
            }
        }()
        
        return DrawingStroke(
            id: UUID(),
            points: points,
            color: ColorData(
                red: Double(red),
                green: Double(green),
                blue: Double(blue),
                alpha: Double(alpha)
            ),
            width: derivedWidth,
            toolType: toolType,
            timestamp: Date(),
            userId: userId
        )
    }
}

extension DrawingStroke {
    func toPKStroke() -> PKStroke? {
        let cgPoints = points.map { point in
            PKStrokePoint(
                location: CGPoint(x: point.x, y: point.y),
                timeOffset: 0,
                size: CGSize(width: width, height: width),
                opacity: CGFloat(color.alpha),
                force: CGFloat(point.force),
                azimuth: CGFloat(point.azimuth),
                altitude: CGFloat(point.altitude)
            )
        }
        
        let path = PKStrokePath(controlPoints: cgPoints, creationDate: timestamp)
        
        let inkType: PKInkingTool.InkType
        switch toolType {
        case "pen": inkType = .pen
        case "pencil": inkType = .pencil
        case "marker": inkType = .marker
        default: inkType = .pen
        }
        
        let uiColor = UIColor(
            red: CGFloat(color.red),
            green: CGFloat(color.green),
            blue: CGFloat(color.blue),
            alpha: CGFloat(color.alpha)
        )
        
        let ink = PKInk(inkType, color: uiColor)
        return PKStroke(ink: ink, path: path)
    }
}

