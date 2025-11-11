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
}

struct PersonalResponse: Content {
    let email: String
    let message: String
    let wssURL: String
}

struct InviteController: RouteCollection {
    func boot(routes: any RoutesBuilder) throws {
        let inviteRoute = routes.grouped("invite").grouped(AuthMiddleware())
        inviteRoute.post(use: sendInvite)
        // inviteRoute.get(use:getInvites)
    }

    func sendInvite(req: Request,) async throws -> InviteResponse {
        let user = try req.auth.require(User.self)
        let inviteRequest = try req.content.decode(InviteRequest.self)

        let findEmail = try await User.query(on: req.db)
            .filter(\.$email == inviteRequest.email)
            .first()

        let note = try await NotesModel.find(inviteRequest.noteID, on: req.db)

        let wssURL = "ws://127.0.0.1:8080/api/v1/notes/\(note!.id!)"
        let ws = req.application.webSocketManager

        let personalMessage = PersonalResponse(email: user.email, message: "Invite you collaborate on Vapor drawing", wssURL: wssURL)

        ws.sendPersonalMessage(userID: findEmail!.id!, message: "\(personalMessage)")

        let createInvite = InviteModel(
            wssURL: wssURL,
            inviteFromID: user.id!,
            inviteToID: findEmail!.id!
        )

        try await createInvite.save(on: req.db)

        return InviteResponse(
            wssURL: wssURL,
            inviteFrom: user.id!,
            inviteTo: findEmail!.id!
        )
    }
}