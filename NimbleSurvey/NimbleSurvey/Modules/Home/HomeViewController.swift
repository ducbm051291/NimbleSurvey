//
//  HomeViewController.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import RxSwift
import RxCocoa
import RxDataSources
import SVProgressHUD

typealias SurveyDataSource = RxCollectionViewSectionedReloadDataSource<SurveySection>

class HomeViewController: UIViewController, RxViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var detailButton: UIButton!
    var disposeBag: DisposeBag = DisposeBag()
    var viewModel: HomeViewModel = HomeViewModel(
        input: HomeViewModel.Input(
            surveys: BehaviorRelay<[NimbleSurvey]>(value: []),
            page: BehaviorRelay<Int>(value: 1),
            ended: BehaviorRelay<Bool>(value: false),
            load: PublishRelay<()>(),
            loadMore: PublishRelay<()>(),
            isLoading: BehaviorRelay<Bool>(value: false)
        ),
        dependency: NimbleSurveyAPIService.shared
    )
    var dataSource: SurveyDataSource!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        registerCell()
        configDataSource()
        setupView()
        setupViewModel()
    }
    
}

extension HomeViewController {
    func setupView() {
        collectionView.allowsSelection = false
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
    }
    func setupViewModel() {
        if let op = self.viewModel.output {
            bindingOutput(output: op)
        }
        
        if let ip = self.viewModel.input {
            bindingInput(input: ip)
        }
    }
    private func bindingInput(input: HomeViewModel.Input) {
        input.isLoading.asDriver().drive(onNext: { isLoading in
            if isLoading {
                SVProgressHUD.show()
            } else {
                SVProgressHUD.dismiss()
            }
        }).disposed(by: disposeBag)
        input.load.accept(())
    }
    private func bindingOutput(output: HomeViewModel.Output) {
        output.sections
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        output.loadResult.subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let surveys):
                self.viewModel.input?.surveys.accept(surveys)
            case .failure(let error):
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .error, message: error.description)
                }
            }
        }).disposed(by: disposeBag)
        output.loadMoreResult.subscribe(onNext: { [weak self] result in
            guard let self = self else { return }
            switch result {
            case .success(let surveys):
                if surveys.isEmpty {
                    self.viewModel.input?.ended.accept(true)
                } else {
                    var currentSurveys = self.viewModel.input?.surveys.value ?? []
                    currentSurveys += surveys
                    self.viewModel.input?.surveys.accept(currentSurveys)
                    // Increase page
                    var currentPage = self.viewModel.input?.page.value ?? 1
                    currentPage += 1
                    self.viewModel.input?.page.accept(currentPage)
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .error, message: error.description)
                }
            }
        }).disposed(by: disposeBag)
    }
}

extension HomeViewController {
    func registerCell() {
        collectionView.register(UINib(nibName: SurveyCell.cellIdentifier, bundle: nil), forCellWithReuseIdentifier: SurveyCell.cellIdentifier)
    }
    func configDataSource() {
        let ds: SurveyDataSource = SurveyDataSource(configureCell: { (dataSource, cv, indexPath, survey) in
            let cell: SurveyCell = cv.dequeueReusableCell(withReuseIdentifier: SurveyCell.cellIdentifier, for: indexPath) as! SurveyCell
            cell.survey = survey
            return cell
        })
        dataSource = ds
    }
}
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: collectionView.bounds.width, height: collectionView.bounds.height)
    }
}
