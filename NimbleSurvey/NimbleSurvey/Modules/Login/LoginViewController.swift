//
//  LoginViewController.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 15/03/2022.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD

class LoginViewController: UIViewController, RxViewController {
    
    @IBOutlet weak var emailTextField: UITextField!
    @IBOutlet weak var passwordTextField: UITextField!
    @IBOutlet weak var logInButton: UIButton!
    
    var disposeBag: DisposeBag = DisposeBag()
    var viewModel: LoginViewModel! = LoginViewModel(
        input: LoginViewModel.Input(
            email: BehaviorRelay<String>(value: ""),
            password: BehaviorRelay<String>(value: ""),
            login: PublishRelay<()>(),
            isLoading: BehaviorRelay<Bool>(value: false)
        ),
        dependency: NimbleSurveyAPIService.shared
    )
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        // Do any additional setup after loading the view.
        setupView()
        setupViewModel()
    }
    
}

extension LoginViewController {
    
    func setupView() {
        emailTextField.attributedPlaceholder = NSAttributedString(
            string: "Email",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
        )
        passwordTextField.attributedPlaceholder = NSAttributedString(
            string: "Password",
            attributes: [NSAttributedString.Key.foregroundColor: UIColor.white.withAlphaComponent(0.3)]
        )
    }
    
    func setupViewModel() {
        if let ip = self.viewModel.input {
            bindingInput(input: ip)
        }
        
        if let op = self.viewModel.output {
            bindingOutput(output: op)
        }
    }
    
    func bindingInput(input: LoginViewModel.Input) {
        input.isLoading.asDriver().drive(onNext: { isLoading in
            if isLoading {
                SVProgressHUD.show()
            } else {
                SVProgressHUD.dismiss()
            }
        }).disposed(by: disposeBag)
        
        let emailDriver = emailTextField.rx.text.orEmpty.asDriver()
        
        let passwordDriver = passwordTextField.rx.text.orEmpty.asDriver()
        
        emailDriver.drive(input.email).disposed(by: disposeBag)
        
        passwordDriver.drive(input.password).disposed(by: disposeBag)
        
        let isLoginEnableDriver = Driver.combineLatest(emailDriver,passwordDriver)
            .map { not($0.0.isEmpty) && not($0.1.isEmpty) }
        
        isLoginEnableDriver.drive(logInButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        isLoginEnableDriver.map { $0 ? .white : .white.withAlphaComponent(0.6) }
        .drive(logInButton.rx.backgroundColor)
        .disposed(by: disposeBag)
        
        logInButton.rx.tap.asObservable()
            .debounce(RxTimeInterval.microseconds(300), scheduler: MainScheduler.instance)
            .bind(to: input.login)
            .disposed(by: disposeBag)
    }
    
    func bindingOutput(output: LoginViewModel.Output) {
        output.loginResult.subscribe(onNext: { result in
            switch result {
            case .success(let auth):
                AuthenticationManager.shared.setAuth(auth)
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .success, message: "LOGIN SUCCESSFULLY!")
                    AppDelegate.openHomeScreen()
                }
            case .failure(let error):
                DispatchQueue.main.async {
                    MessageManager.shared.showMessage(messageType: .error, message: error.description)
                }
            }
        }).disposed(by: disposeBag)
    }
    
}
