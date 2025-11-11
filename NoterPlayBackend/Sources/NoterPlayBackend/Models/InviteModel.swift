import Vapor
import Fluent

final class InviteModel: Model, Content, @unchecked Sendable {
    static let schema = "invites"
    
    @ID(key: .id)
    var id: UUID?
    
    @Field(key: "wss_url")
    var wssURL: String
    
    @Parent(key: "invite_from")
    var inviteFrom: User
    
    @Parent(key: "invite_to")
    var inviteTo: User
    
    @Timestamp(key: "created_at", on: .create)
    var createdAt: Date?
    
    init() { }
    
    init(id: UUID? = nil, wssURL: String, inviteFromID: UUID, inviteToID: UUID) {
        self.id = id
        self.wssURL = wssURL
        self.$inviteFrom.id = inviteFromID
        self.$inviteTo.id = inviteToID
    }
}