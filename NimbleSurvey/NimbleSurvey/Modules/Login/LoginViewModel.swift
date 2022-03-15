//
//  LoginViewModel.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import RxCocoa
import RxSwift

class LoginViewModel : ViewModelProtocol {
    
    typealias Dependency = NimbleSurveyAPIService
    
    struct Input {
        let email                   : BehaviorRelay<String>
        let password                : BehaviorRelay<String>
        let login                   : PublishRelay<()>
        let isLoading               : BehaviorRelay<Bool>
    }
    
    struct Output {
        let loginResult             : Observable<Result<NimbleSurveyAuth,NimbleSurveyError>>
    }
    
    var input      : Input?
    
    var output     : Output?
    
    var dependency : Dependency?
    
    init(input: Input, dependency: Dependency) {
        self.input = input
        self.dependency = dependency
        self.output = self.transform(input: self.input, dependency: self.dependency)
    }
    
    func transform(input: LoginViewModel.Input?, dependency: NimbleSurveyAPIService?) -> LoginViewModel.Output? {
        self.input = input
        
        self.dependency = dependency
        
        guard let ip = input, let dp = dependency else {
            return nil
        }
        
        let loginResult = ip.login.asObservable()
            .do(onNext: { _ in
                ip.isLoading.accept(true)
            })
            .withLatestFrom(Observable.combineLatest(ip.email, ip.password))
            .flatMap { (email,password) -> Observable<Result<NimbleSurveyAuth,NimbleSurveyError>> in
                return dp.login(email: email, password: password)
            }
            .do(onNext: { _ in
                ip.isLoading.accept(false)
            })
        
        return LoginViewModel.Output(loginResult: loginResult)
    }
    
}


