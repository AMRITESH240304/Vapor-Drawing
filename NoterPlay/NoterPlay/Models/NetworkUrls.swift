//
//  NetworkUrls.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 25/10/25.
//

import Foundation

struct NetworkUrls {
    static let baseUrl = ""
    static let localHost = "http://127.0.0.1:8080/api/v1/"
}

struct ServerErrorResponse: Codable {
    let reason: String
    let error: Bool
}

