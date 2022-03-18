//
//  NimbleSurveyHomeTests.swift
//  NimbleSurveyTests
//
//  Created by Bùi Minh Đức on 18/03/2022.
//

import XCTest

class NimbleSurveyHomeTests: XCTestCase {


}


////MARK: Home Test
//extension NimbleSurveyTests {
//    func testSurveyListAtStart() throws {
//        XCTAssertEqual(homeViewModel.input?.surveys.value.count, 0)
//    }
//
//    func testHomeLoadingAtStart() throws {
//        XCTAssertEqual(try homeViewModel.input?.isLoading.toBlocking().first(), true)
//    }
//
//    func testHomeLoadSurveyListResultSuccessWithoutLogin() throws {
//        let expectation = expectation(description: "Load failed")
//        AuthenticationManager.shared.logout()
//        homeViewModel.output!.loadResult
//            .subscribe(onNext: { result in
//                switch result {
//                case .failure:
//                    XCTAssertTrue(true)
//                    expectation.fulfill()
//                default:
//                    break
//                }
//            }).disposed(by: disposeBag)
//        homeViewModel.input?.load.accept(())
//
//        waitForExpectations(timeout: 20) { error in
//            if let error = error {
//                XCTFail("waitForExpectations errored: \(error)")
//            }
//        }
//    }
//
//    func testHomeLoadSurveyListResultSuccessAfterLoginSuccess() throws {
//        let expectation = expectation(description: "Load success")
//        homeViewModel.output!.loadResult
//            .subscribe(onNext: { result in
//                switch result {
//                case .success(let surveys):
//                    XCTAssertTrue(surveys.count == 10)
//                    expectation.fulfill()
//                default:
//                    break
//                }
//            }).disposed(by: disposeBag)
//        loginViewModel.output!.loginResult
//            .subscribe(onNext: { result in
//                switch result {
//                case .success(let auth):
//                    AuthenticationManager.shared.setAuth(auth)
//                    self.homeViewModel.input?.load.accept(())
//                default:
//                    break
//                }
//            }).disposed(by: disposeBag)
//        loginViewModel.input?.email.accept("dev@nimblehq.co")
//        loginViewModel.input?.password.accept("12345678")
//        loginViewModel.input?.login.accept(())
//
//        waitForExpectations(timeout: 20) { error in
//            if let error = error {
//                XCTFail("waitForExpectations errored: \(error)")
//            }
//        }
//    }
//}
