//
//  DataModel.swift
//  NoterPlay
//
//  Created by Amritesh Kumar on 24/10/25.
//

import Foundation

// Plain Codable structs — let the compiler synthesize Sendable if possible.
struct RegisterRequest: Codable {
    let email: String
    let password: String
}

struct UserResponse: Codable {
    let id: UUID
    let email: String
    let createdAt: Date?
}

struct RegisterResponse: Codable {
    let user: UserResponse
    let token: String
}

nonisolated
struct InviteResponse: Codable {
    let email: String
    let message: String
    let wssURL: String
}
