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
    private var refreshTokenObservable: Observable<Bool> = Observable.empty()
    private init() {
        // Refresh token observable
        self.refreshTokenObservable = Observable.deferred {
            let token = AuthenticationManager.shared.currentAuth()?.attributes?.refreshToken ?? ""
            if token.isEmpty {
                return Observable.just(false)
            } else {
                return self.refreshToken(refreshToken: token).flatMap { result -> Observable<Bool> in
                    switch result {
                    case .success(let auth):
                        AuthenticationManager.shared.setAuth(auth)
                        return Observable.just(true)
                    case .failure:
                        return Observable.just(false)
                    }
                }
            }
        }
        .share(replay: 1, scope: .whileConnected)
    }
    // This is a generic wrapper function for API request. All API request must be called through this.
    func request<T: Codable>(_ api: NimbleSurveyAPI) -> Observable<Result<T,NimbleSurveyError>> {
        return provider.rx.request(api).asObservable()
            .flatMap({ response -> Observable<Response> in
                if response.statusCode == 401 {
                    return self.refreshTokenObservable.flatMap { success -> Observable<Response> in
                        if success {
                            // Re-call API
                            return self.provider.rx.request(api).asObservable()
                        } else {
                            return Observable.just(response)
                        }
                    }
                } else {
                    return Observable.just(response)
                }
            })
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
    func login(email: String, password: String) -> Observable<Result<NimbleSurveyAuth,NimbleSurveyError>> {
        return self.request(.signIn(SignInRequest(
            email: email,
            password: password
        )))
    }
    func refreshToken(refreshToken: String) -> Observable<Result<NimbleSurveyAuth,NimbleSurveyError>> {
        return self.request(.refreshToken(RefreshTokenRequest(refreshToken: refreshToken)))
    }
    func getSurveyList(page: Int, limit: Int = 4) -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> {
        return self.request(.surveyList(SurveyListRequest(page: page, limit: limit)))
    }
}
