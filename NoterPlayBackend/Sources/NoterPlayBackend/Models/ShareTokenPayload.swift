import Vapor
import JWT

struct ShareTokenPayload: JWTPayload {
    let noteID: UUID
    let invitedBy: UUID
    let invitedEmail: String
    let exp: ExpirationClaim
    
    func verify(using algorithm: some JWTAlgorithm) throws {
        try self.exp.verifyNotExpired()
    }
}