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
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var detailButton: UIButton!
    @IBOutlet weak var loadingImageView: UIImageView!
    var disposeBag: DisposeBag = DisposeBag()
    var viewModel: HomeViewModel = HomeViewModel(
        input: HomeViewModel.Input(
            surveys: BehaviorRelay<[NimbleSurvey]>(value: []),
            load: PublishRelay<()>(),
            isLoading: BehaviorRelay<Bool>(value: true)
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
    @IBAction func detailTapped(_ sender: Any) {
        let detailVC = SurveyDetailViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension HomeViewController {
    func setupView() {
        collectionView.allowsSelection = false
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        collectionView.rx.didEndDecelerating.asDriver()
            .flatMap { [weak self] _ -> Driver<Int> in
                guard let self = self else { return Driver.empty() }
                let pageWidth = self.collectionView.frame.size.width
                let page = Int(floor((self.collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
                debugPrint("page = \(page)")
                return Driver.just(page)
            }
            .drive(pageControl.rx.currentPage).disposed(by: disposeBag)
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
        input.isLoading.asDriver().drive(onNext: { [weak self] isLoading in
            guard let self = self else { return }
            if isLoading {
                SVProgressHUD.show()
                self.loadingImageView.isHidden = false
            } else {
                self.loadingImageView.isHidden = true
                SVProgressHUD.dismiss()
            }
        }).disposed(by: disposeBag)
        input.surveys.asDriver().map { $0.count }.drive(pageControl.rx.numberOfPages).disposed(by: disposeBag)
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
