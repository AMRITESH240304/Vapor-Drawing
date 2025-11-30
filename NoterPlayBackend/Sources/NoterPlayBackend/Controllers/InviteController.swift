import Vapor
import Fluent

struct InviteRequest: Content {
    let email: String
    let noteID: UUID
}

struct InviteResponse: Content {
    let wssURL: String
    let inviteFrom: UUID
    let inviteTo: UUID
    let shareToken: String
}
struct SendInvite: Content {
    let email: String
    let message: String
    let wssURL: String
    let shareToken: String
}

struct InviteController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let inviteRoute: any RoutesBuilder = routes.grouped("invite").grouped(AuthMiddleware())
        inviteRoute.post(use: sendInvite)
        // inviteRoute.get(use:getInvites)
    }

    func sendInvite(req: Request) async throws -> InviteResponse {
        do {
            let user = try req.auth.require(User.self)
            let inviteRequest = try req.content.decode(InviteRequest.self)

            guard let findEmail = try await User.query(on: req.db)
                .filter(\.$email == inviteRequest.email)
                .first()
            else {
                throw Abort(.notFound, reason: "User with email \(inviteRequest.email) not found")
            }

            // find note and verify ownership
            guard let note = try await NotesModel.query(on: req.db)
                .filter(\.$id == inviteRequest.noteID)
                .filter(\.$user.$id == user.id!)
                .first()
            else {
                throw Abort(.notFound, reason: "Note not found or you do not have permission to share this note")
            }

            // let note = try await NotesModel.find(inviteRequest.noteID, on: req.db)

            let expireAt = Date().addingTimeInterval(30*24*60*60)
            let payload = ShareTokenPayload(
                noteID: note.id!, invitedBy: user.id!, invitedEmail: inviteRequest.email, exp: .init(value: expireAt)
            )

            let shareToken = try await req.jwt.sign(payload)

            // append share toekn to note
            if !note.shareTokens.contains(shareToken) {
                note.shareTokens.append(shareToken)
                try await note.save(on: req.db)
            }

            let wssURL = "ws://127.0.0.1:8080/api/v1/notes/\(shareToken)"
            let ws = req.application.webSocketManager

            let personalMessage = SendInvite(email: user.email, message: "Invite you collaborate on Vapor drawing", wssURL: wssURL, shareToken: shareToken)

            let encoder = JSONEncoder()

            if let jsonData = try? encoder.encode(personalMessage),
               let jsonString = String(data: jsonData, encoding: .utf8) {
                ws.sendPersonalMessage(userID: findEmail.id!, message: jsonString)
            }

            let createInvite = InviteModel(
                wssURL: wssURL,
                inviteFromID: user.id!,
                inviteToID: findEmail.id!
            )

            try await createInvite.save(on: req.db)

            return InviteResponse(
                wssURL: wssURL,
                inviteFrom: user.id!,
                inviteTo: findEmail.id!,
                shareToken: shareToken
            )
        }
        catch {
            req.logger.error("Error in sendInvite endpoint: \(error.localizedDescription)")
            throw error
        }
        
    }
}