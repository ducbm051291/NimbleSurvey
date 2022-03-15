//
//  UserManager.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import RxSwift
import RxCocoa
import KeychainAccess

class UserManager {
    static private let propertyListEncoder = PropertyListEncoder()
    static private let propertyListDecoder = PropertyListDecoder()
    static private let keychain = Keychain(service: "com.ducbm.nimblesurvey")
    static let shared = UserManager()
    private let user = BehaviorRelay<NimbleSurveyUser?>(value: nil)
    private init() {
        user.accept(getUser())
    }
    private func getUser() -> NimbleSurveyUser? {
        guard let userData = Self.keychain[data: "encodedUser"] else { return nil }
        let data = try? Self.propertyListDecoder.decode(NimbleSurveyUser.self, from: userData)
        return data
    }
    private func saveUser(user: NimbleSurveyUser) {
        if let savingData = try? Self.propertyListEncoder.encode(user) {
            Self.keychain[data: "encodedUser"] = NSData(data: savingData) as Data
        }
    }
    private func removeUser() {
        Self.keychain[data: "encodedUser"] = nil
    }
    func setUser(user: NimbleSurveyUser) {
        self.saveUser(user: user)
        self.user.accept(user)
    }
    func logout() {
        // Remove user and notify change
        self.user.accept(nil)
        // Remove current user
        self.removeUser()
    }
    func isLogin() -> Bool {
        return self.user.value != nil
    }
    func isLoginObservable() -> Observable<Bool> {
        return self.user.asObservable().map { $0 != nil }
    }
    func currentUser() -> NimbleSurveyUser? {
        return self.user.value
    }
    func currentUserObservable() -> Observable<NimbleSurveyUser?> {
        return self.user.asObservable()
    }
}
