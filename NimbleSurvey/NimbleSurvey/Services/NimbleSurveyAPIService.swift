//
//  RepositoryServicec.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import Moya
import Alamofire
import RxSwift

class NimbleSurveyData<T:Codable>: Codable {
    let data: T
}

class NimbleSurveyAPIService {
    // MARK: Singleton
    static let shared = NimbleSurveyAPIService()
    let provider = MoyaProvider<NimbleSurveyAPI>()
    private var refreshTokenObservable: Observable<Bool>
    private init() {
        // Refresh token observable
        self.refreshTokenObservable = Observable.deferred {
            if let token = UserManager.shared.currentUser()?.attributes?.refreshToken, not(token.isEmpty) {
                //return NimbleSurveyAPIService.shared.refreshToken(refreshToken: token).map { result -> Bool in
                //    if result.result() != nil {
                //        return true
                //    }
                //    return false
                //}
                return Observable.just(true)
            } else {
                return Observable.just(false)
            }
        }
        .share(replay: 1, scope: .whileConnected)
    }
    // This is a generic wrapper function for API request. All API request must be called through this.
    func request<T: Codable>(_ api: NimbleSurveyAPI) -> Observable<Result<T,NimbleSurveyError>> {
        return provider.rx.request(api).asObservable()
            .flatMap({ response -> Observable<Result<T,NimbleSurveyError>> in
                Self.prettyPrintJsonData(response.data)
                let decoder = JSONDecoder()
                if let data = try? decoder.decode(NimbleSurveyData<T>.self, from: response.data) {
                    return Observable.just(.success(data.data))
                }
                return Observable.just(.failure(NimbleSurveyError.invalidData))
            })
            .catchError{ error in
                return Observable.just(.failure(NimbleSurveyError.custom(error)))
            }
    }
    static func prettyPrintJsonData(_ data: Data) {
        let stringData = String(data: data, encoding: .utf8) ?? ""
        debugPrint(stringData)
    }
}

extension NimbleSurveyAPIService {
    func login(email: String, password: String) -> Observable<Result<NimbleSurveyUser,NimbleSurveyError>> {
        return self.request(.signIn(SignInRequest(
            email: email,
            password: password
        )))
    }
    func refreshToken(refreshToken: String) -> Observable<Result<[NimbleSurveyUser],NimbleSurveyError>> {
        return self.request(.refreshToken(RefreshTokenRequest(refreshToken: refreshToken)))
    }
    func getSurveyList(page: Int, limit: Int = 4) -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> {
        return self.request(.surveyList(SurveyListRequest(page: page, limit: limit)))
    }
}
