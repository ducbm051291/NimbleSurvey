//
//  NimbleSurveyAPITests.swift
//  NimbleSurveyAPITests
//
//  Created by Duc Bui on 15/03/2022.
//

import XCTest
import RxCocoa
import RxSwift
import RxTest
import RxBlocking

@testable import NimbleSurvey

class NimbleSurveyAPITests: XCTestCase {
    var scheduler: TestScheduler!
    var disposeBag: DisposeBag!
    let apiService = NimbleSurveyAPIService.shared
    
    override func setUp() {
        disposeBag = DisposeBag()
        scheduler = TestScheduler(initialClock: 0, resolution: 0.1)
    }
}

extension NimbleSurveyAPITests {
    func testLoginWithWrongAccount() throws {
        let expectation = expectation(description: "Login fail")
        apiService.login(email: "dev@nimblehq.co", password: "12345678910")
            .subscribe(onNext: { result in
                switch result {
                case .failure:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    func testLoginWithCorrectAccount() throws {
        let expectation = expectation(description: "Login success")
        apiService.login(email: "dev@nimblehq.co", password: "12345678")
            .subscribe(onNext: { result in
                switch result {
                case .success:
                    XCTAssertTrue(true)
                    expectation.fulfill()
                default:
                    break
                }
            })
            .disposed(by: disposeBag)
        
        waitForExpectations(timeout: 20) { error in
            if let error = error {
                XCTFail("waitForExpectations errored: \(error)")
            }
        }
    }
    func testRefreshToken() throws {
        let expectation = expectation(description: "Refresh token success")
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
                return self.apiService.refreshToken(refreshToken: auth.refreshToken ?? "")
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
    func testGetSurveyList() throws {
        let expectation = expectation(description: "Get survey list success")
        apiService.login(email: "dev@nimblehq.co", password: "12345678")
            .flatMap({ result -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                switch result {
                case .success(let auth):
                    AuthenticationManager.shared.setAuth(auth)
                    return self.apiService.getSurveyList()
                case .failure:
                    return .empty()
                }
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
