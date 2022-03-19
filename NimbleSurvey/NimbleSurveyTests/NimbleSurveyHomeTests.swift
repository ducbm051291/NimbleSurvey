//
//  NimbleSurveyHomeTests.swift
//  NimbleSurveyTests
//
//  Created by Bùi Minh Đức on 18/03/2022.
//

import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import NimbleSurvey

class NimbleSurveyHomeTests: XCTestCase {
    var loginViewModel: LoginViewModel!
    var viewModel: HomeViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        disposeBag = DisposeBag()
        viewModel = HomeViewModel(
            input: HomeViewModel.Input(
                surveys: BehaviorRelay<[NimbleSurvey]>(value: [NimbleSurvey.getFakeSurvey()]),
                load: PublishRelay<()>(),
                loadMore: PublishRelay<()>(),
                page: BehaviorRelay<Int>(value: 1),
                ended: BehaviorRelay<Bool>(value: false),
                isLoading: BehaviorRelay<Bool>(value: true)
            ),
            dependency: NimbleSurveyAPIService.shared,
            disposeBag: self.disposeBag
        )
        loginViewModel = LoginViewModel(
            input: LoginViewModel.Input(
                email: BehaviorRelay<String>(value: "dev@nimblehq.co"),
                password: BehaviorRelay<String>(value: "12345678"),
                login: PublishRelay<()>(),
                isLoading: BehaviorRelay<Bool>(value: false)
            ),
            dependency: NimbleSurveyAPIService.shared,
            disposeBag: disposeBag
        )
        scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
    }
}


//MARK: Home Test
extension NimbleSurveyHomeTests {
    func testSurveyListAtStart() throws {
        XCTAssertEqual(try viewModel.input?.surveys.toBlocking().first()?.count, 1)
        XCTAssertEqual(try viewModel.input?.surveys.toBlocking().first()?.first?.isFake, true)
    }
    
    func testHomeLoadSurveyListResultSuccessWithoutLogin() throws {
        let expectation = expectation(description: "Load failed")
        AuthenticationManager.shared.logout()
        viewModel.output!.loadFail
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        viewModel.input?.load.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testHomeLoadSurveyListResultSuccessAfterLoginSuccess() throws {
        let expectation = expectation(description: "Load success")
        viewModel.output!.loadSuccess
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        loginViewModel.output!.loginSuccess
            .subscribe(onNext: { _ in
                self.viewModel.input?.load.accept(())
            }).disposed(by: disposeBag)
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
}
