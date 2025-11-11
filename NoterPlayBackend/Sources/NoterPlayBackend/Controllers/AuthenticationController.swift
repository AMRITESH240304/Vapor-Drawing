import Vapor
import Fluent
import JWT

struct AuthenticationController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let authRoutes = routes.grouped("auth")

        authRoutes.post("register", use: register)
        authRoutes.post("login", use: login)

        let protected = authRoutes.grouped(AuthMiddleware())
        protected.get("me", use: getCurrentUser)
        protected.webSocket("handleInvite", onUpgrade: handleInvite)
    }

    func handleInvite(req: Request, ws: WebSocket) async {
        let user = try! req.auth.require(User.self)
        let websocketManager = req.application.webSocketManager

        websocketManager.addConnection(webSocket: ws, userID: user.id!)
    }

    func register(req: Request) async throws -> AuthResponse {
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

    func login(req: Request) async throws -> AuthResponse {
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

    func getCurrentUser(req: Request) async throws -> UserResponse {
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