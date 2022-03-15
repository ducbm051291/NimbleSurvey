//
//  NimbleSurveyUser.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import Foundation

struct NimbleSurveyAuth: Codable {
    let id: Int?
    let type: String?
    let attributes: NimbleSurveyAuthAttributes?
}

struct NimbleSurveyAuthAttributes: Codable {
    let accessToken, tokenType: String?
    let expiresIn: Int?
    let refreshToken: String?
    let createdAt: Int?
    enum CodingKeys: String, CodingKey {
        case accessToken = "access_token"
        case tokenType = "token_type"
        case expiresIn = "expires_in"
        case refreshToken = "refresh_token"
        case createdAt = "created_at"
    }
}
