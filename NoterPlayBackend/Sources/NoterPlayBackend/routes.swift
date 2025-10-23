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

            let existingUser: User? = try await User.query(on: req.db)
                .filter(\.$email == register.email)
                .first()

            if existingUser != nil {
                throw Abort(.conflict, reason: "User already exists")
            }

            // Hash password
            let hash: String = try Bcrypt.hash(register.password)

            // Create user
            let user: User = User(email: register.email, passwordHash: hash)
            try await user.save(on: req.db)

            let payload: UserToken = UserToken(with: user)
            let token: String = try await req.jwt.sign(payload)
            return AuthResponse(user: UserResponse(id: user.id!, email: user.email, createdAt: user.createdAt), token: token)
        }
        catch{
            req.logger.error("Error in register endpoint: \(error.localizedDescription)")
            throw error
        }
    }

    app.post("login") { req async throws -> AuthResponse in 
        do{
            let login = try req.content.decode(RegisterRequest.self)
            guard let user: User = try await User.query(on: req.db)
                .filter(\.$email == login.email)
                .first()
            else {
                throw Abort(.unauthorized, reason: "Invalid email or password")
            }

            if try Bcrypt.verify(login.password, created: user.passwordHash) {
                let payload: UserToken = UserToken(with: user)
                let token: String = try await req.jwt.sign(payload)
                return AuthResponse(user: UserResponse(id: user.id!, email: user.email, createdAt: user.createdAt), token: token)
            } else {
                throw Abort(.unauthorized, reason: "Invalid email or password")
            }
        }
        catch {
            req.logger.error("Error in login endpoint: \(error.localizedDescription)")
            throw error
        }
    }

    let protected = app.grouped(AuthMiddleware())

    protected.get("me") { req async throws -> UserResponse in
        do{
            let user = try req.auth.require(User.self)
            return UserResponse(id: user.id!, email: user.email, createdAt: user.createdAt)
        }
        catch {
            req.logger.error("Error in me endpoint: \(error.localizedDescription)")
            throw error
        }
    }
}
