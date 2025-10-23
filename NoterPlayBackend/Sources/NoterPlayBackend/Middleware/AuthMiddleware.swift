import Vapor
import Fluent
import JWT

struct AuthMiddleware: AsyncMiddleware {
    func respond(to request: Request, chainingTo next: any AsyncResponder) async throws -> Response {
        do{
            let payload: UserToken = try await request.jwt.verify(as: UserToken.self)

            guard let user = try await User.find(payload.userID, on: request.db) else {
                throw Abort(.unauthorized, reason: "User not found")
            }
            request.auth.login(user)
            
            return try await next.respond(to: request)
        }
        catch{
            request.logger.error("Error in AuthMiddleware: \(error.localizedDescription)")
            throw error
        }
        
    }
}