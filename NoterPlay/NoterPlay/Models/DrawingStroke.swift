//
//  DrawingStroke.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 20/10/25.
//

import Foundation
import PencilKit
import UIKit

struct DrawingStroke: Codable{
    let points: [StrokePoint]
    let color: ColorData
    let width: Double
//    let toolType: String
    let timestamp: Date
//    let userId: String
    
    init(points: [StrokePoint], color: ColorData, width: Double, timestamp: Date) {
        self.points = points
        self.color = color
        self.width = width
        self.timestamp = timestamp
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
    func toDrawingStroke() -> DrawingStroke {
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
        
        let derivedWidth: Double = {
            if let firstPoint = self.path.first {
                return Double(firstPoint.size.width)
            } else {
                return 1.0
            }
        }()
        
        return DrawingStroke(
            points: points,
            color: ColorData(
                red: Double(red),
                green: Double(green),
                blue: Double(blue),
                alpha: Double(alpha)
            ),
            width: derivedWidth,
            timestamp: Date()
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
        
        let inkType: PKInkingTool.InkType = .pen
        
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

