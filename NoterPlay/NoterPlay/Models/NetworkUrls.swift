//
//  NetworkUrls.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 25/10/25.
//

import Foundation

struct NetworkUrls {
    static let baseUrl = ""
    static let production = "https://noterplay-backend-latest.onrender.com/api/v1/"
    static let localHost = "https://noterplay-backend-latest.onrender.com/api/v1/"
    static let wsURL = "wss://noterplay-backend-latest.onrender.com/api/v1/auth/handleInvite"
}

struct ServerErrorResponse: Codable {
    let reason: String
    let error: Bool
}

