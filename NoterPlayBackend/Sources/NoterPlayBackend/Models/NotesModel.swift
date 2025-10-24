import Vapor
import Fluent

final class NotesModel:Model,Content, @unchecked Sendable {
    static let schema = "notes"

    @ID(key: .id)
    var id: UUID?

    @Field(key: "title")
    var title: String

    @Field(key: "strokes")
    var strokes: [DrawingStroke]
    
    @Parent(key: "user_id")
    var user: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, title: String, strokes: [DrawingStroke] = [], userID: UUID) {
        self.id = id
        self.title = title
        self.strokes = strokes
        self.$user.id = userID
    }
}

struct DrawingStroke: Codable {
    let points: [DrawingPoint]
    let color: DrawingColor
    let width: Double
    let timestamp: Date
    
    init(points: [DrawingPoint], color: DrawingColor, width: Double, timestamp: Date = Date()) {
        self.points = points
        self.color = color
        self.width = width
        self.timestamp = timestamp
    }
}

struct DrawingPoint: Codable {
    let x: Double
    let y: Double
    let pressure: Double
    let timestamp: Date
    
    init(x: Double, y: Double, pressure: Double = 1.0, timestamp: Date = Date()) {
        self.x = x
        self.y = y
        self.pressure = pressure
        self.timestamp = timestamp
    }
}

// MARK: - DrawingColor Model
struct DrawingColor: Codable {
    let red: Double
    let green: Double
    let blue: Double
    let alpha: Double
    
    init(red: Double, green: Double, blue: Double, alpha: Double = 1.0) {
        self.red = red
        self.green = green
        self.blue = blue
        self.alpha = alpha
    }
}

// MARK: - Migration
extension NotesModel {
    struct Migration: AsyncMigration {
        var name: String { "CreateNote" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("notes")
                .id()
                .field("title", .string, .required)
                .field("strokes", .json, .required)
                .field("user_id", .uuid, .required)
                .field("created_at", .datetime)
                .field("updated_at", .datetime)
                .foreignKey("user_id", references: "users", "id", onDelete: .cascade)
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("notes").delete()
        }
    }
}