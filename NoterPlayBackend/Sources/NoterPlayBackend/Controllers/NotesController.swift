import Vapor
import Fluent

// MARK: - Note Request DTOs
struct CreateNoteRequest: Content {
    let id: UUID?
    let title: String
    let strokes: [DrawingStroke]?
}

struct UpdateNoteRequest: Content {
    let title: String?
    let strokes: [DrawingStroke]?
}

// MARK: - Note Response DTOs
struct NoteResponse: Content {
    let id: UUID
    let title: String
    let strokes: [DrawingStroke]
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from note: NotesModel) {
        self.id = note.id!
        self.title = note.title
        self.strokes = note.strokes
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
    }
}

struct NotesListResponse: Content {
    let notes: [NoteListItem]
    let total: Int
}

struct NoteListItem: Content {
    let id: UUID
    let title: String
    let createdAt: Date?
    let updatedAt: Date?
    
    init(from note: NotesModel) {
        self.id = note.id!
        self.title = note.title
        self.createdAt = note.createdAt
        self.updatedAt = note.updatedAt
    }
}

struct NotesController: RouteCollection {

    func boot(routes: any RoutesBuilder) throws {
        let notesRoute = routes.grouped("notes").grouped(AuthMiddleware())

        notesRoute.post(use: createNote)
        notesRoute.get(use: getAllNotes)
        notesRoute.get(":id", use: getNote)
        notesRoute.on(.PUT, ":id", body: .collect(maxSize: "2mb"), use: updateNote)
        notesRoute.delete(":id", use: deleteNote)
        notesRoute.webSocket(":id", onUpgrade: handleNoteWebSocket)

    }

    func handleNoteWebSocket(req: Request, ws: WebSocket) {
        guard let noteIDString = req.parameters.get("id"),
            let noteID = UUID(uuidString: noteIDString) else {
            ws.close(promise: nil)
            return
        }

        ws.send("Connected to note \(noteID)")
        ws.onText { ws, text in
            ws.send("Echo: we are connected")
        }
        ws.onClose.whenComplete { _ in
        }
    }

    func getAllNotes(req: Request) async throws -> NotesListResponse {
        let user = try req.auth.require(User.self)

        let notes = try await NotesModel.query(on: req.db)
            .filter(\.$user.$id == user.id!)
            .sort(\.$updatedAt, .descending)
            .all()
        
        let noteItems = notes.map { NoteListItem(from: $0) }
        
        return NotesListResponse(notes: noteItems, total: notes.count)
    }

    func createNote(req: Request) async throws -> NoteResponse {
        let user = try req.auth.require(User.self)
        let createRequest = try req.content.decode(CreateNoteRequest.self)
        
        let note = NotesModel(
            id: createRequest.id,
            title: createRequest.title,
            strokes: createRequest.strokes ?? [],
            userID: user.id!
        )
        
        try await note.save(on: req.db)
        
        return NoteResponse(from: note)
    }

    // MARK: - Get Single Note
    func getNote(req: Request) async throws -> NoteResponse {
        let user = try req.auth.require(User.self)
        do{
            guard let note = try await NotesModel.query(on: req.db)
                .filter(\.$id == req.parameters.get("id")!)
                .filter(\.$user.$id == user.id!)
                .first()
            else {
                throw Abort(.notFound, reason: "Note not found")
            }
            
            return NoteResponse(from: note)
        }
        catch {
            print(error)
            throw Abort(.internalServerError, reason: "Failed to update note: \(error.localizedDescription)")
        }
        
        // guard let noteID = req.parameters.get("noteID", as: UUID.self) else {
        //     throw Abort(.badRequest, reason: "Invalid note ID")
        // }
        
        
    }
    
    // MARK: - Update Note
    func updateNote(req: Request) async throws -> NoteResponse {
        let user = try req.auth.require(User.self)
        let updateRequest = try req.content.decode(UpdateNoteRequest.self)
        
        // guard let noteID = req.parameters.get("noteID", as: UUID.self) else {
        //     // print(noteID)
        //     throw Abort(.badRequest, reason: "Invalid note ID")
        // }
        
        do {
            guard let note = try await NotesModel.query(on: req.db)
                        .filter(\.$id == req.parameters.get("id")!)
                        .filter(\.$user.$id == user.id!)
                        .first()
            else {
                throw Abort(.notFound, reason: "Note not found")
            }
            
            if let title = updateRequest.title {
                note.title = title
            }
            
            if let strokes = updateRequest.strokes {
                note.strokes = strokes
            }
            
            try await note.save(on: req.db)
            
            return NoteResponse(from: note)
        }
        catch {
            print(error)
            throw Abort(.internalServerError, reason: "Failed to update note: \(error.localizedDescription)")
        }
        
    }
    
    // MARK: - Delete Note
    func deleteNote(req: Request) async throws -> HTTPStatus {
        let user = try req.auth.require(User.self)
        
        guard let noteID = req.parameters.get("noteID", as: UUID.self) else {
            throw Abort(.badRequest, reason: "Invalid note ID")
        }
        
        guard let note = try await NotesModel.query(on: req.db)
            .filter(\.$id == noteID)
            .filter(\.$user.$id == user.id!)
            .first()
        else {
            throw Abort(.notFound, reason: "Note not found")
        }
        
        try await note.delete(on: req.db)
        
        return .noContent
    }
}