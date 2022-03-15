//
//  NimbleSurveyAPIs.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import Moya
import Alamofire

enum GrantType: String {
    case password = "password"
    case refreshToken = "refresh_token"
}

struct SignInRequest: NimbleSurveyAPIRequest {
    private let grantType: String = GrantType.password.rawValue
    private let clientID: String = Constants.clientId
    private let clientSecret: String = Constants.clientSecret
    let email, password: String
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case email, password
        case clientID = "client_id"
        case clientSecret = "client_secret"
    }
}

struct RefreshTokenRequest: NimbleSurveyAPIRequest {
    private let grantType: String = GrantType.refreshToken.rawValue
    private let clientID: String = Constants.clientId
    private let clientSecret: String = Constants.clientSecret
    let refreshToken: String
    
    enum CodingKeys: String, CodingKey {
        case grantType = "grant_type"
        case refreshToken = "refresh_token"
        case clientID = "client_id"
        case clientSecret = "client_secret"
    }
}

struct SurveyListRequest: NimbleSurveyAPIRequest {
    let page, limit: Int
    
    enum CodingKeys: String, CodingKey {
        case page = "page[number]"
        case limit = "page[size]"
    }
}

enum NimbleSurveyAPI {
    case signIn(NimbleSurveyAPIRequest)
    case refreshToken(NimbleSurveyAPIRequest)
    case surveyList(NimbleSurveyAPIRequest)
}

extension NimbleSurveyAPI : TargetType {
    
    public var baseURL: URL {
        return URL(string: Constants.apiBaseURL)!
    }
    
    public var path: String {
        switch self {
        case .signIn, .refreshToken:
            return "/api/v1/oauth/token"
        case .surveyList:
            return "/api/v1/surveys"
        }
    }
    
    public var url : String {
        return "\(baseURL)\(path)"
    }
    
    public var encoding : ParameterEncoding {
        switch self {
        case .signIn, .refreshToken:
            return JSONEncoding.default
        case .surveyList:
            return URLEncoding.default
        }
    }
    
    public var method: Moya.Method {
        switch self {
        case .signIn, .refreshToken:
            return .post
        case .surveyList:
            return .get
        }
    }
    
    public var sampleData: Data {
        return Data()
    }
    
    public var task: Task {
        switch self {
        case .signIn(let nimbleSurveyAPIRequest), .refreshToken(let nimbleSurveyAPIRequest):
            return .requestParameters(parameters: nimbleSurveyAPIRequest.toParameters(), encoding: JSONEncoding.default)
        case .surveyList(let nimbleSurveyAPIRequest):
            return .requestParameters(parameters: nimbleSurveyAPIRequest.toParameters(), encoding: URLEncoding.default)
        }
    }
    public var headers: [String : String]? {
        var defaultHeaders = ["Accept": "application/json"]
        switch self {
        case .surveyList:
            if let tokenType = UserManager.shared.currentUser()?.attributes?.tokenType,
               let token = UserManager.shared.currentUser()?.attributes?.accessToken {
                defaultHeaders["Authorization"] = "\(tokenType) \(token)"
            }
        default:
            break
        }
        return defaultHeaders
    }
}

protocol NimbleSurveyAPIRequest: Codable {
    func toParameters() -> [String:Any]
}

extension NimbleSurveyAPIRequest {
    public func toParameters() -> [String : Any] {
        return try! self.asDictionary()
    }
}

enum NimbleSurveyError: Error, Equatable {
    static func == (lhs: NimbleSurveyError, rhs: NimbleSurveyError) -> Bool {
        lhs.description == rhs.description
    }
    
    case invalidData
    case custom(Error)
    case unknown
}

extension NimbleSurveyError: CustomStringConvertible {
    public var description: String {
        switch self {
        case .invalidData:
            return "Response data is not valid."
        case .custom(let error):
            return error.localizedDescription
        case .unknown:
            return "An unknown error occurred."
        }
    }
}
