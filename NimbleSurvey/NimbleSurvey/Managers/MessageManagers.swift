//
//  MessageManagers.swift
//  NimbleSurvey
//
//  Created by Duc Bui on 11/03/2022.
//

import SwiftMessages

class MessageManager {
    static let shared = MessageManager()
    private init() {}
    var sharedConfig: SwiftMessages.Config {
        var config = SwiftMessages.Config()
        config.presentationStyle = .bottom
        config.presentationContext = .window(windowLevel: UIWindow.Level(rawValue: UIWindow.Level(rawValue: UIWindow.Level.statusBar.rawValue).rawValue))
        config.duration = .forever
        config.dimMode = .gray(interactive: true)
        config.interactiveHide = true
        config.preferredStatusBarStyle = .lightContent
        return config
    }
}

extension MessageManager {
    func showMessage(messageType type: Theme = .success, withTitle title: String = "", message: String, completion: (() -> Void)? = nil, duration: SwiftMessages.Duration = .seconds(seconds: 4)) {
        var config = sharedConfig
        let view = MessageView.viewFromNib(layout: .cardView)
        view.configureTheme(type)
        view.button?.isHidden = true
        view.configureContent(title: title, body: message)
        view.configureDropShadow()
        config.duration = duration
        config.eventListeners = [{ event in
            switch event {
            case .didHide:
                completion?()
            default:
                break
            }}]
        SwiftMessages.show(config: config, view: view)
    }
}

