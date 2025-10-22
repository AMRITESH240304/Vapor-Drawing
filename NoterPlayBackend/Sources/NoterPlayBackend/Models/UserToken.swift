import Vapor
import JWT

struct UserToken: JWTPayload {
    var userID: UUID
    var email: String

    var exp: ExpirationClaim
    var iat: IssuedAtClaim

    func verify(using signer: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }

    init(with user: User) {
        self.userID = try! user.requireID()
        self.email = user.email
        self.exp = ExpirationClaim(value: Date().addingTimeInterval(60 * 60 * 24 * 7))
        self.iat = IssuedAtClaim(value: Date())
    }
}

extension User {
    convenience init(from payload: UserToken) {
        self.init(id: payload.userID, email: payload.email, passwordHash: "")
    }
}