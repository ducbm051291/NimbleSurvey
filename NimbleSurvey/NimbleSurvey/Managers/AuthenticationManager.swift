//
//  AuthenticationManager.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import RxSwift
import RxCocoa
import KeychainAccess

class AuthenticationManager {
    static private let propertyListEncoder = PropertyListEncoder()
    static private let propertyListDecoder = PropertyListDecoder()
    static private let keychain = Keychain(service: "com.ducbm.nimblesurvey")
    static let shared = AuthenticationManager()
    private let auth = BehaviorRelay<NimbleSurveyAuth?>(value: nil)
    private init() {
        auth.accept(getAuth())
    }
    private func getAuth() -> NimbleSurveyAuth? {
        guard let authData = Self.keychain[data: "encodedUser"] else { return nil }
        let data = try? Self.propertyListDecoder.decode(NimbleSurveyAuth.self, from: authData)
        return data
    }
    private func saveAuth(_ auth: NimbleSurveyAuth) {
        if let savingData = try? Self.propertyListEncoder.encode(auth) {
            Self.keychain[data: "encodedUser"] = NSData(data: savingData) as Data
        }
    }
    private func removeAuth() {
        Self.keychain[data: "encodedUser"] = nil
    }
    func setAuth(_ auth: NimbleSurveyAuth) {
        self.saveAuth(auth)
        self.auth.accept(auth)
    }
    func logout() {
        // Remove auth and notify change
        self.auth.accept(nil)
        // Remove current auth
        self.removeAuth()
    }
    func isLogin() -> Bool {
        return self.auth.value != nil
    }
    func isLoginObservable() -> Observable<Bool> {
        return self.auth.asObservable().map { $0 != nil }
    }
    func currentAuth() -> NimbleSurveyAuth? {
        return self.auth.value
    }
    func currentAuthObservable() -> Observable<NimbleSurveyAuth?> {
        return self.auth.asObservable()
    }
}
