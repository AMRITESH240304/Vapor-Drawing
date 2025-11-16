import Vapor
import Fluent
import FluentMongoDriver

struct RegisterRequest: Content {
    let email: String
    let password: String
}

struct AuthResponse: Content {
    let user: UserResponse
    let token: String
}

struct UserResponse: Content {
    let id: UUID
    let email: String
    let createdAt: Date?
}

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("test","github") { req async -> String in
        "github action works!"
    }

    app.get("hello", ":num") { req async -> String in
        let name = req.parameters.get("num")!
        return "Hello, \(name)!"
    }

    app.group("api", "v1") { api in
        // Register AuthenticationController
        try! api.register(collection: AuthenticationController())
        try! api.register(collection: NotesController())
        try! api.register(collection: InviteController())
    }
}
