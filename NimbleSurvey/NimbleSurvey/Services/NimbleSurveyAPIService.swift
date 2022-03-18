//
//  NimbleSurveyAPIService.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import Moya
import Alamofire
import RxSwift
import Japx

struct NimbleSurveyErrorDetail: Codable {
    let detail: String
    let code: String
}

struct JapxResponse<T: Codable>: Codable {
    var data: T?
}

struct JapxResponseArray<T: Codable>: Codable {
    var data: [T]?
}

struct ErrorResponse: Codable {
    var errors: [NimbleSurveyErrorDetail]?
}

class NimbleSurveyAPIService {
    // MARK: Singleton
    static let shared = NimbleSurveyAPIService()
    let provider = MoyaProvider<NimbleSurveyAPI>()
    private var refreshTokenObservable: Observable<Bool> = Observable.empty()
    private init() {
        // Refresh token observable
        self.refreshTokenObservable = Observable.deferred {
            let token = AuthenticationManager.shared.currentAuth()?.refreshToken ?? ""
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
    func request<T: JapxCodable>(_ api: NimbleSurveyAPI) -> Observable<Result<T,NimbleSurveyError>> {
        return provider.rx.request(api).asObservable()
            .flatMap({ response -> Observable<Response> in
                return self.checkExpireToken(response, api)
            })
            .flatMap({ response -> Observable<Result<T,NimbleSurveyError>> in
                Self.prettyPrintJsonData(response.data)
                if let responseData = try? JapxDecoder().decode(JapxResponse<T>.self, from: response.data),
                   let data = responseData.data {
                    return Observable.just(.success(data))
                } else if let responseError = try? JSONDecoder().decode(ErrorResponse.self, from: response.data),
                          let error = responseError.errors?.first?.detail{
                    return Observable.just(.failure(NimbleSurveyError.custom(error)))
                }
                return Observable.just(.failure(NimbleSurveyError.invalidData))
            })
            .catchError{ error in
                return Observable.just(.failure(NimbleSurveyError.custom(error.localizedDescription)))
            }
    }
    func request<T: JapxCodable>(_ api: NimbleSurveyAPI) -> Observable<Result<[T],NimbleSurveyError>> {
        return provider.rx.request(api).asObservable()
            .flatMap({ response -> Observable<Response> in
                return self.checkExpireToken(response, api)
            })
            .flatMap({ response -> Observable<Result<[T],NimbleSurveyError>> in
                Self.prettyPrintJsonData(response.data)
                if let responseData = try? JapxDecoder().decode(JapxResponseArray<T>.self, from: response.data),
                   let data = responseData.data {
                    return Observable.just(.success(data))
                } else if let responseError = try? JSONDecoder().decode(ErrorResponse.self, from: response.data),
                          let error = responseError.errors?.first?.detail{
                    return Observable.just(.failure(NimbleSurveyError.custom(error)))
                }
                return Observable.just(.failure(NimbleSurveyError.invalidData))
            })
            .catchError{ error in
                return Observable.just(.failure(NimbleSurveyError.custom(error.localizedDescription)))
            }
    }
    func checkExpireToken(_ response: Response,_ api: NimbleSurveyAPI) -> Observable<Response> {
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
    func getSurveyList(page: Int = 1, limit: Int = 10) -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> {
        return self.request(.surveyList(SurveyListRequest(page: page, limit: limit)))
    }
}
