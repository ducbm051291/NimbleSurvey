//
//  NimbleSurveyLoginTests.swift
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

class NimbleSurveyLoginTests: XCTestCase {
    var viewModel: LoginViewModel!
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    
    override func setUp() {
        disposeBag = DisposeBag()
        viewModel = LoginViewModel(
            input: LoginViewModel.Input(
                email: BehaviorRelay<String>(value: ""),
                password: BehaviorRelay<String>(value: ""),
                login: PublishRelay<()>(),
                isLoading: BehaviorRelay<Bool>(value: false)
            ),
            dependency: NimbleSurveyAPIService.shared,
            disposeBag: disposeBag
        )
        scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
    }
}

//MARK: Login Test
extension NimbleSurveyLoginTests {
    func testEmailAtStart() throws {
        XCTAssertEqual(try viewModel.input?.email.toBlocking().first(), "")
    }
    
    func testPasswordAtStart() throws {
        XCTAssertEqual(try viewModel.input?.password.toBlocking().first(), "")
    }
    
    func testLoginLoadingAtStart() throws {
        XCTAssertEqual(try viewModel.input?.isLoading.toBlocking().first(), false)
    }
    
    func testLoginTapped() throws {
        let tap = scheduler.createObserver(Bool.self)
        
        viewModel.input!.login
            .map { true }
            .bind(to: tap)
            .disposed(by: disposeBag)
        
        scheduler.createColdObservable([.next(1, ())])
            .bind(to: viewModel.input!.login)
            .disposed(by: disposeBag)
        
        scheduler.start()
        
        XCTAssertEqual(tap.events, [
            .next(1, true)
        ])
    }
    
    func testLoginWithEmptyAndEmptyPassword() throws {
        let expectation = expectation(description: "Login failed")
        viewModel.output!.loginFail
            .subscribe(onNext: { result in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        viewModel.input?.email.accept("")
        viewModel.input?.password.accept("")
        viewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithWrongEmailAndWrongPassword() throws {
        let expectation = expectation(description: "Login failed")
        viewModel.output!.loginFail
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        viewModel.input?.email.accept("1234")
        viewModel.input?.password.accept("abcd")
        viewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithCorrectEmailAndWrongPassword() throws {
        let expectation = expectation(description: "Login failed")
        viewModel.output!.loginFail
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        viewModel.input?.email.accept("dev@nimblehq.co")
        viewModel.input?.password.accept("abcd")
        viewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithCorrectEmailAndCorrectPassword() throws {
        let expectation = expectation(description: "Login success")
        viewModel.output!.loginSuccess
            .subscribe(onNext: { _ in
                XCTAssertTrue(true)
                expectation.fulfill()
            }).disposed(by: disposeBag)
        viewModel.input?.email.accept("dev@nimblehq.co")
        viewModel.input?.password.accept("12345678")
        viewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
}
