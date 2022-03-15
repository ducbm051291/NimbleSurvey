//
//  Protocols.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 12/03/2022.
//

import UIKit
import RxSwift

protocol ViewModelProtocol {
    associatedtype Input
    associatedtype Output
    associatedtype Dependency

    var input: Input? { get set }
    var output: Output? { get set }
    var dependency: Dependency? { get set }

    @discardableResult
    func transform(input: Input?, dependency: Dependency?) -> Output?
}

protocol RxViewController where Self: UIViewController {
    var disposeBag: DisposeBag {get set}
}
