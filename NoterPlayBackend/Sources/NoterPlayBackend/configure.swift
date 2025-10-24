import Vapor
import Fluent
import FluentMongoDriver
import JWT

// configures your application
public func configure(_ app: Application) async throws {
    // Configure MongoDB database
    try app.databases.use(
        .mongo(
            connectionString: Environment.get("MONGODB_URI") ?? "mongodb://localhost:27017",
        ),
        as: .mongo
    )

    // configure jwt
    await app.jwt.keys.add(hmac: HMACKey(stringLiteral: Environment.get("JWT_SECRET") ?? "super-secret-key"), digestAlgorithm: .sha256)

    app.migrations.add(User.Migration())
    app.migrations.add(NotesModel.Migration())
    
    // Run migrations
    if app.environment == .production {
        try await app.autoMigrate()
        Logger(label: "configure").info("Migrations ran successfully.")
    }
    
    // uncomment to serve files from /Public folder
    // app.middleware.use(FileMiddleware(publicDirectory: app.directory.publicDirectory))

    // register routes
    try routes(app)
}
