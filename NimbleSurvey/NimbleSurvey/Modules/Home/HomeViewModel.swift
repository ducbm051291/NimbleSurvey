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
        //Variables
        let surveys                         : BehaviorRelay<[NimbleSurvey]>
        let page                            : BehaviorRelay<Int>
        let ended                           : BehaviorRelay<Bool>
        
        //Trigger
        let load                            : PublishRelay<()>
        let loadMore                        : PublishRelay<()>
        
        let isLoading                       : BehaviorRelay<Bool>
    }
    
    struct Output {
        let sections                        : Driver<[SurveySection]>
        let loadResult                      : Observable<Result<[NimbleSurvey],NimbleSurveyError>>
        let loadMoreResult                  : Observable<Result<[NimbleSurvey],NimbleSurveyError>>
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
                ip.surveys.accept([])
                ip.page.accept(2)
                ip.ended.accept(false)
            })
            .flatMap { _ -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                return dp.getSurveyList(page: 1)
            }
            .do(onNext: { _ in
                ip.isLoading.accept(false)
            })
        let loadMoreResult = ip.loadMore.asObservable()
            .debounce(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
            .withLatestFrom(Observable.combineLatest(ip.page, ip.ended))
            .flatMap { (page, ended) -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                guard not(ended) else { return .empty() }
                return dp.getSurveyList(page: page)
            }
        let sections = ip.surveys.asDriver().map { [SurveySection(model: "repo", items: $0)] }
        return HomeViewModel.Output(sections: sections,
                                    loadResult: loadResult,
                                    loadMoreResult: loadMoreResult)
    }
    
}


