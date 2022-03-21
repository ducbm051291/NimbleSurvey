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
        let emailValid              : PublishRelay<Bool>
        let loginEnable             : PublishRelay<Bool>
        let loginSuccess            : PublishRelay<()>
        let loginFail               : PublishRelay<String>
    }
    
    var input      : Input?
    
    var output     : Output?
    
    var dependency : Dependency?
    
    var disposeBag: DisposeBag
    
    init(input: Input, dependency: Dependency, disposeBag: DisposeBag) {
        self.input = input
        self.dependency = dependency
        self.disposeBag = disposeBag
        self.output = self.transform(input: self.input, dependency: self.dependency)
    }
    
    func transform(input: LoginViewModel.Input?, dependency: NimbleSurveyAPIService?) -> LoginViewModel.Output? {
        self.input = input
        
        self.dependency = dependency
        
        guard let ip = input, let dp = dependency else {
            return nil
        }
        
        let output = LoginViewModel.Output(
            emailValid: PublishRelay<Bool>(),
            loginEnable: PublishRelay<Bool>(),
            loginSuccess: PublishRelay<()>(),
            loginFail: PublishRelay<String>()
        )
        
        ip.login.asObservable()
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
            .subscribe(onNext: { result in
                switch result {
                case .success(let auth):
                    AuthenticationManager.shared.setAuth(auth)
                    output.loginSuccess.accept(())
                case .failure(let error):
                    output.loginFail.accept(error.description)
                }
            })
            .disposed(by: self.disposeBag)
                    
        let isValidEmail = ip.email.asObservable()
            .debounce(
                RxTimeInterval.milliseconds(500),
                scheduler: MainScheduler.instance
            )
            .map { $0.isEmpty || $0.isValidEmail() }
        
        isValidEmail.bind(to: output.emailValid).disposed(by: disposeBag)
        
        let isEmptyEmail = ip.email.asObservable().map { $0.isEmpty }
        
        let isValidPassword = ip.password.asObservable().map { not($0.isEmpty) }
        
        Observable.combineLatest(isEmptyEmail,isValidEmail,isValidPassword)
            .map { not($0.0) && $0.1 && $0.2 }
            .bind(to: output.loginEnable)
            .disposed(by: disposeBag)
        
        return output
    }
}


