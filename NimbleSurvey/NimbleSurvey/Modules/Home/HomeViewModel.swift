//
//  HomeViewModel.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import RxCocoa
import RxSwift
import RxDataSources

typealias SurveySection = SectionModel<String,NimbleSurvey>

class HomeViewModel : ViewModelProtocol {
    
    typealias Dependency = NimbleSurveyAPIService
    
    struct Input {
        let surveys                         : BehaviorRelay<[NimbleSurvey]>
        let load                            : PublishRelay<()>
        let isLoading                       : BehaviorRelay<Bool>
    }
    
    struct Output {
        let sections                        : Driver<[SurveySection]>
        let loadResult                      : Observable<Result<[NimbleSurvey],NimbleSurveyError>>
    }
    
    var input      : Input?
    
    var output     : Output?
    
    var dependency : Dependency?
    
    init(input: Input, dependency: Dependency) {
        self.input = input
        self.dependency = dependency
        self.output = self.transform(input: self.input, dependency: self.dependency)
    }
    
    func transform(input: HomeViewModel.Input?, dependency: NimbleSurveyAPIService?) -> HomeViewModel.Output? {
        self.input = input
        self.dependency = dependency
        guard let ip = input, let dp = dependency else {
            return nil
        }
        let loadResult = ip.load.asObservable()
            .debounce(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
            .do(onNext: { _ in
                ip.isLoading.accept(true)
            })
            .flatMap { _ -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                return dp.getSurveyList()
            }
            .do(onNext: { _ in
                ip.isLoading.accept(false)
            })
        let sections = ip.surveys.asDriver().map { [SurveySection(model: "survey", items: $0)] }
        return HomeViewModel.Output(sections: sections,
                                    loadResult: loadResult)
    }
    
}


