//
//  AppDelegate.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import UIKit
import RxSwift
import RxCocoa
import SVProgressHUD
import IQKeyboardManagerSwift

@main
class AppDelegate: UIResponder, UIApplicationDelegate {
    var window: UIWindow?
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        // SVProgressHUD
        SVProgressHUD.setDefaultStyle(.custom)
        SVProgressHUD.setDefaultMaskType(.custom)
        SVProgressHUD.setForegroundColor(UIColor.white)                                //Ring Color
        SVProgressHUD.setBackgroundColor(UIColor.black)                                //HUD Color
        SVProgressHUD.setBackgroundLayerColor(UIColor.black.withAlphaComponent(0.6))   //Background Color
        
        // Keyboard
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        
        let userDefaults = UserDefaults.standard
        if userDefaults.object(forKey: "FirstRun") == nil {
            // Delete values from keychain here
            userDefaults.setValue("1strun", forKey: "FirstRun")
            UserManager.shared.logout()
        }
        
        if UserManager.shared.isLogin() {
            Self.openHomeScreen()
        } else {
            Self.openLoginScreen()
        }
        return true
    }
}

extension AppDelegate {
    
    static func setRootViewController(_ controller: UIViewController) {
        guard let appDelegate = UIApplication.shared.delegate as? AppDelegate else {
            return
        }
        
        guard let window = appDelegate.window else { return }
        
        window.rootViewController = controller
        window.makeKeyAndVisible()
        
        // A mask of options indicating how you want to perform the animations.
        let options: UIView.AnimationOptions = .transitionCrossDissolve
        
        // The duration of the transition animation, measured in seconds.
        let duration: TimeInterval = 0.3
        
        // Creates a transition animation.
        // Though `animations` is optional, the documentation tells us that it must not be nil. ¯\_(ツ)_/¯
        UIView.transition(with: window, duration: duration, options: options, animations: {}, completion:
                            { completed in
            // Maybe do something on completion here
        })
    }
    
    static func openHomeScreen() {
        let homeVC = HomeViewController()
        let homeNC = UINavigationController(rootViewController: homeVC)
        homeNC.isNavigationBarHidden = true
        if #available(iOS 13.0, *) {
            homeNC.isModalInPresentation = true
            homeNC.modalPresentationStyle = .fullScreen
        } else {
            // Fallback on earlier versions
        }
        AppDelegate.setRootViewController(homeNC)
    }
    
    static func openLoginScreen() {
        let loginVC = LoginViewController()
        AppDelegate.setRootViewController(loginVC)
    }
    
}
