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
import RxReachability
import Reachability
import SVProgressHUD

typealias SurveyDataSource = RxCollectionViewSectionedReloadDataSource<SurveySection>

class HomeViewController: UIViewController, RxViewController {
    @IBOutlet weak var collectionView: UICollectionView!
    @IBOutlet weak var pageControl: UIPageControl!
    @IBOutlet weak var refreshButton: UIButton!
    @IBOutlet weak var detailButton: UIButton!
    var disposeBag: DisposeBag = DisposeBag()
    var viewModel: HomeViewModel!
    var dataSource: SurveyDataSource!
    var reachability: Reachability?
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view.
        registerCell()
        configDataSource()
        setupView()
        setupViewModel()
        bindReachability()
    }
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        try? reachability?.startNotifier()
    }
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        reachability?.stopNotifier()
    }
    override var preferredStatusBarStyle: UIStatusBarStyle {
        return .lightContent
    }
    @IBAction func refreshTapped(_ sender: Any) {
        viewModel.input?.load.accept(())
    }
    @IBAction func detailTapped(_ sender: Any) {
        let detailVC = SurveyDetailViewController()
        navigationController?.pushViewController(detailVC, animated: true)
    }
}

extension HomeViewController {
    func setupView() {
        reachability = try? Reachability()
        viewModel = HomeViewModel(
            input: HomeViewModel.Input(
                surveys: BehaviorRelay<[NimbleSurvey]>(value: [NimbleSurvey.getFakeSurvey()]),
                load: PublishRelay<()>(),
                loadMore: PublishRelay<()>(),
                page: BehaviorRelay<Int>(value: 1),
                ended: BehaviorRelay<Bool>(value: false),
                isLoading: BehaviorRelay<Bool>(value: true)
            ),
            dependency: NimbleSurveyAPIService.shared,
            disposeBag: self.disposeBag
        )
        automaticallyAdjustsScrollViewInsets = false
        collectionView.allowsSelection = false
        collectionView.rx.setDelegate(self).disposed(by: disposeBag)
        Driver.merge(
            collectionView.rx.didScroll.asDriver().throttle(RxTimeInterval.milliseconds(300))
            ,collectionView.rx.didEndDecelerating.asDriver()
        )
        .flatMap { [weak self] _ -> Driver<Int> in
            guard let self = self else { return Driver.empty() }
            let pageWidth = self.collectionView.frame.size.width
            let page = Int(floor((self.collectionView.contentOffset.x - pageWidth / 2) / pageWidth) + 1)
            debugPrint("page = \(page)")
            return Driver.just(page)
        }
        .drive(pageControl.rx.currentPage).disposed(by: disposeBag)
        pageControl.addTarget(self, action: #selector(pageControlHandle), for: .valueChanged)
    }
    @objc private func pageControlHandle(sender: UIPageControl){
        collectionView.scrollToItem(at: IndexPath(row: sender.currentPage, section: 0), at: .centeredHorizontally, animated: true)
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
        input.surveys.asDriver().map { $0.count == 1 && $0.first?.isFake ?? false }
            .drive(pageControl.rx.isHidden)
            .disposed(by: disposeBag)
        input.surveys.asDriver().map { $0.count }
            .drive(pageControl.rx.numberOfPages)
            .disposed(by: disposeBag)
        input.load.accept(())
    }
    private func bindingOutput(output: HomeViewModel.Output) {
        output.sections.asDriver(onErrorJustReturn: [])
            .drive(self.collectionView.rx.items(dataSource: self.dataSource))
            .disposed(by: disposeBag)
        output.loadFail.asObservable()
            .subscribe(onNext: { error in
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .error, message: error)
                }
            }).disposed(by: disposeBag)
        output.loadMoreFail.asObservable()
            .subscribe(onNext: { error in
                // Nothing to do here
            }).disposed(by: disposeBag)
    }
    func bindReachability() {
        reachability?.rx.isConnected
            .skip(1)
            .subscribe(onNext: { [weak self] in
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .success, message: "INTERNET CONNECTION RESTORED")
                }
                guard let self = self else { return }
                guard let input = self.viewModel.input else { return }
                if input.surveys.value.isEmpty || (input.surveys.value.count == 1 && input.surveys.value.first?.isFake ?? false) {
                    input.load.accept(())
                }
            })
            .disposed(by: disposeBag)
        reachability?.rx.isDisconnected
            .subscribe(onNext: { _ in
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .warning, message: "INTERNET CONNECTION LOST")
                }
            })
            .disposed(by: disposeBag)
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

extension HomeViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, willDisplay cell: UICollectionViewCell, forItemAt indexPath: IndexPath) {
        if let surveyCell = cell as? SurveyCell, let survey = surveyCell.survey, survey.isFake {
            cell.setTemplateWithSubviews(
                true,
                color: .darkGray,
                animate: true,
                viewBackgroundColor: UIColor.black
            )
        } else {
            cell.setTemplateWithSubviews(false)
            if indexPath.row == (self.viewModel.input?.surveys.value ?? []).count - 1 {
                viewModel.input?.loadMore.accept(())
            }
        }
    }
}
extension HomeViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return collectionView.frame.size
    }
}
