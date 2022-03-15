//
//  NimbleSurveyItem.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import Foundation

struct NimbleSurvey: Codable {
    let id, type: String?
    let attributes: NimbleSurveyDetails?
}

struct NimbleSurveyDetails: Codable {
    let title, desc: String?
    let coverImageURL: String?
    
    enum CodingKeys: String, CodingKey {
        case title
        case desc = "description"
        case coverImageURL = "cover_image_url"
    }
    
    func getLargeCoverImage() -> String {
        let imageUrl = coverImageURL ?? ""
        return "\(imageUrl)l"
    }
}
