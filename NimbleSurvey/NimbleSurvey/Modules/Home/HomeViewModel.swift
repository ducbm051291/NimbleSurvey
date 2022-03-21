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
        let loadMore                        : PublishRelay<()>
        let page                            : BehaviorRelay<Int>
        let ended                           : BehaviorRelay<Bool>
        let isLoading                       : BehaviorRelay<Bool>
    }
    
    struct Output {
        let sections                        : PublishRelay<[SurveySection]>
        let loadSuccess                     : PublishRelay<()>
        let loadFail                        : PublishRelay<String>
        let loadMoreSuccess                 : PublishRelay<()>
        let loadMoreFail                    : PublishRelay<String>
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
    
    func transform(input: HomeViewModel.Input?, dependency: NimbleSurveyAPIService?) -> HomeViewModel.Output? {
        self.input = input
        self.dependency = dependency
        guard let ip = input, let dp = dependency else {
            return nil
        }
        let output = HomeViewModel.Output(
            sections: PublishRelay<[SurveySection]>(),
            loadSuccess: PublishRelay<()>(),
            loadFail: PublishRelay<String>(),
            loadMoreSuccess: PublishRelay<()>(),
            loadMoreFail: PublishRelay<String>()
        )
        
        ip.load.asObservable()
            .debounce(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
            .do(onNext: { _ in
                ip.isLoading.accept(true)
                ip.surveys.accept([NimbleSurvey.getFakeSurvey()])
                ip.page.accept(1)
                ip.ended.accept(false)
            })
            .flatMap { _ -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                return dp.getSurveyList()
            }
            .do(onNext: { _ in
                ip.isLoading.accept(false)
            })
            .subscribe(onNext: { result in
                switch result {
                case .success(let surveys):
                    ip.surveys.accept(surveys)
                    if not(surveys.isEmpty) {
                        ip.page.accept(ip.page.value + 1)
                    }
                    output.loadSuccess.accept(())
                case .failure(let error):
                    output.loadFail.accept(error.description)
                }
            })
            .disposed(by: self.disposeBag)
        
        ip.loadMore.asObservable()
            .debounce(RxTimeInterval.milliseconds(300), scheduler: MainScheduler.instance)
            .withLatestFrom(ip.ended)
            .filter { not($0) }
            .do(onNext: { _ in
                ip.isLoading.accept(true)
            })
            .withLatestFrom(ip.page)
            .flatMap { page -> Observable<Result<[NimbleSurvey],NimbleSurveyError>> in
                return dp.getSurveyList(page: page)
            }
            .do(onNext: { _ in
                ip.isLoading.accept(false)
            })
            .subscribe(onNext: { result in
                switch result {
                case .success(let surveys):
                    if not(surveys.isEmpty) {
                        var currentSurvey = ip.surveys.value
                        currentSurvey += surveys
                        ip.surveys.accept(currentSurvey)
                        ip.page.accept(ip.page.value + 1)
                    } else {
                        ip.ended.accept(true)
                    }
                    output.loadMoreSuccess.accept(())
                case .failure(let error):
                    output.loadMoreFail.accept(error.description)
                    ip.ended.accept(true)
                }
            })
            .disposed(by: self.disposeBag)
        
        ip.surveys.asObservable()
            .map { [SurveySection(model: "survey", items: $0)] }
            .bind(to: output.sections)
            .disposed(by: self.disposeBag)
        return output
    }
    
}


