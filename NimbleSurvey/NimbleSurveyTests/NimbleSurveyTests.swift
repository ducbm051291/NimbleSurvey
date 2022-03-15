//
//  NimbleSurveyTests.swift
//  NimbleSurveyTests
//
//  Created by Duc Bui on 15/03/2022.
//

import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import NimbleSurvey

class NimbleSurveyTests: XCTestCase {
    var loginViewModel: LoginViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        loginViewModel = LoginViewModel(
            input: LoginViewModel.Input(
                email: BehaviorRelay<String>(value: ""),
                password: BehaviorRelay<String>(value: ""),
                login: PublishRelay<()>(),
                isLoading: BehaviorRelay<Bool>(value: false)
            ),
            dependency: NimbleSurveyAPIService.shared
        )
        scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
        disposeBag = DisposeBag()
    }
    
    func testEmailAtStart() throws {
        XCTAssertEqual(try loginViewModel.input?.email.toBlocking().first(), "")
    }
    
    func testPasswordAtStart() throws {
        XCTAssertEqual(try loginViewModel.input?.password.toBlocking().first(), "")
    }
    
    func testLoadingAtStart() throws {
        XCTAssertEqual(try loginViewModel.input?.isLoading.toBlocking().first(), false)
    }
    
    func testLoginTapped() throws {
        let tap = scheduler.createObserver(Bool.self)
        
        loginViewModel.input!.login
            .map { true }
            .bind(to: tap)
            .disposed(by: disposeBag)

        scheduler.createColdObservable([.next(1, ())])
                 .bind(to: loginViewModel.input!.login)
                 .disposed(by: disposeBag)

        scheduler.start()

        XCTAssertEqual(tap.events, [
          .next(1, true)
        ])
    }
}
