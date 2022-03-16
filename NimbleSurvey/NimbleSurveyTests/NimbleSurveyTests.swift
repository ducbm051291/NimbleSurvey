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
    var homeViewModel: HomeViewModel!
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
        homeViewModel = HomeViewModel(
            input: HomeViewModel.Input(
                surveys: BehaviorRelay<[NimbleSurvey]>(value: []),
                load: PublishRelay<()>(),
                isLoading: BehaviorRelay<Bool>(value: true)
            ),
            dependency: NimbleSurveyAPIService.shared
        )
        scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
        disposeBag = DisposeBag()
    }
}

//MARK: Login Test
extension NimbleSurveyTests {
    func testEmailAtStart() throws {
        XCTAssertEqual(try loginViewModel.input?.email.toBlocking().first(), "")
    }
    
    func testPasswordAtStart() throws {
        XCTAssertEqual(try loginViewModel.input?.password.toBlocking().first(), "")
    }
    
    func testLoginLoadingAtStart() throws {
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
    
    func testLoginWithWrongEmptyAndEmptyPassword() throws {
        let expectation = expectation(description: "Login failed")
        loginViewModel.output!.loginResult
            .subscribe(onNext: { result in
                switch result {
                case .failure:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.input?.email.accept("")
        loginViewModel.input?.password.accept("")
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithWrongEmailAndWrongPassword() throws {
        let expectation = expectation(description: "Login failed")
        loginViewModel.output!.loginResult
            .subscribe(onNext: { result in
                switch result {
                case .failure:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.input?.email.accept("1234")
        loginViewModel.input?.password.accept("abcd")
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithCorrectEmailAndWrongPassword() throws {
        let expectation = expectation(description: "Login failed")
        loginViewModel.output!.loginResult
            .subscribe(onNext: { result in
                switch result {
                case .failure:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.input?.email.accept("dev@nimblehq.co")
        loginViewModel.input?.password.accept("abcd")
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testLoginWithCorrectEmailAndCorrectPassword() throws {
        let expectation = expectation(description: "Login success")
        loginViewModel.output!.loginResult
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.input?.email.accept("dev@nimblehq.co")
        loginViewModel.input?.password.accept("12345678")
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 10) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
}

//MARK: Home Test
extension NimbleSurveyTests {
    func testSurveyListAtStart() throws {
        XCTAssertEqual(homeViewModel.input?.surveys.value.count, 0)
    }
    
    func testHomeLoadingAtStart() throws {
        XCTAssertEqual(try homeViewModel.input?.isLoading.toBlocking().first(), true)
    }
    
    func testHomeLoadSurveyListResultSuccessWithoutLogin() throws {
        let expectation = expectation(description: "Load failed")
        AuthenticationManager.shared.logout()
        homeViewModel.output!.loadResult
            .subscribe(onNext: { result in
                switch result {
                case .failure:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        homeViewModel.input?.load.accept(())
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    
    func testHomeLoadSurveyListResultSuccessAfterLoginSuccess() throws {
        let expectation = expectation(description: "Load success")
        homeViewModel.output!.loadResult
            .subscribe(onNext: { result in
                switch result {
                case .success(let surveys):
                    XCTAssertTrue(surveys.count == 10)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.output!.loginResult
            .subscribe(onNext: { result in
                switch result {
                case .success(let auth):
                    AuthenticationManager.shared.setAuth(auth)
                    self.homeViewModel.input?.load.accept(())
                default:
                    break
                }
            }).disposed(by: disposeBag)
        loginViewModel.input?.email.accept("dev@nimblehq.co")
        loginViewModel.input?.password.accept("12345678")
        loginViewModel.input?.login.accept(())
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
}

//MARK: Refresh Token Test
extension NimbleSurveyTests {
    func testRefreshToken() throws {
        let expectation = expectation(description: "Refresh token success")
        let apiService = NimbleSurveyAPIService.shared
        apiService.login(email: "dev@nimblehq.co", password: "12345678")
            .flatMap({ result -> Observable<NimbleSurveyAuth> in
                switch result {
                case .success(let auth):
                    return Observable.just(auth)
                case .failure:
                    return .empty()
                }
            })
            .flatMap({ auth -> Observable<Result<NimbleSurveyAuth,NimbleSurveyError>> in
                return apiService.refreshToken(refreshToken: auth.attributes?.refreshToken ?? "")
            })
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            }).disposed(by: disposeBag)
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
}
