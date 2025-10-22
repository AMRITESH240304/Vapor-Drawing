import Vapor

func routes(_ app: Application) throws {
    app.get { req async in
        "It works!"
    }

    app.get("hello",":num") { req async -> String in
        let name = req.parameters.get("num")!
        return "Hello, \(name)!"
    }
}
