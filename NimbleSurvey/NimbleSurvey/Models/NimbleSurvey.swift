//
//  NimbleSurveyItem.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import Foundation
import Japx

struct NimbleSurvey: JapxCodable {
    var type: String    
    var id: String
    let title, desc: String?
    let coverImageURL: String?
    
    var isFake: Bool = false
    
    enum CodingKeys: String, CodingKey {
        case id, type, title
        case desc = "description"
        case coverImageURL = "cover_image_url"
    }
    
    func getLargeCoverImage() -> String {
        let imageUrl = coverImageURL ?? ""
        return "\(imageUrl)l"
    }
    
    static func getFakeSurvey() -> NimbleSurvey {
        return NimbleSurvey(
            type: "",
            id: "",
            title: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            desc: "Lorem ipsum dolor sit amet, consectetur adipiscing elit.",
            coverImageURL: "",
            isFake: true
        )
    }
}
