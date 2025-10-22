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

    app.get("hello", ":num") { req async -> String in
        let name = req.parameters.get("num")!
        return "Hello, \(name)!"
    }

    // 👇 Register endpoint
    app.post("register") { req async throws -> AuthResponse in
        do {
            let register = try req.content.decode(RegisterRequest.self)

            let existingUser = try await User.query(on: req.db)
                .filter(\.$email == register.email)
                .first()

            if existingUser != nil {
                throw Abort(.conflict, reason: "User already exists")
            }

            // Hash password
            let hash = try Bcrypt.hash(register.password)

            // Create user
            let user = User(email: register.email, passwordHash: hash)
            try await user.save(on: req.db)

            let payload = UserToken(with: user)
            let token = try await req.jwt.sign(payload)
            return AuthResponse(user: UserResponse(id: user.id!, email: user.email, createdAt: user.createdAt), token: token)
        }
        catch{
            req.logger.error("Error in register endpoint: \(error.localizedDescription)")
            throw error
        }
    }
}
