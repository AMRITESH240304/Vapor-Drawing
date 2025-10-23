import Fluent
import Vapor

import Vapor
import Fluent

final class User: Model, Content, @unchecked Sendable, Authenticatable {
    static let schema = "users"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "email")
    var email: String
    
    @Field(key: "password_hash")
    var passwordHash: String
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    @Timestamp(key: "updated_at", on: .update)
    var updatedAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, email: String, passwordHash: String) {
        self.id = id
        self.email = email
        self.passwordHash = passwordHash
    }
}

extension User {
    struct Migration: AsyncMigration {
        var name: String { "CreateUser" }
        
        func prepare(on database: any Database) async throws {
            try await database.schema("users")
                .id()
                .field("email", .string, .required)
                .field("password_hash", .string, .required)
                .unique(on: "email")
                .create()
        }

        func revert(on database: any Database) async throws {
            try await database.schema("users").delete()
        }
    }
}
