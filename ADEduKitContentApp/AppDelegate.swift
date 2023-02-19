//
//  AppDelegate.swift
//  ADEduKitContentApp
//
//  Created by Schwarze on 08.12.21.
//

import UIKit
import ADEduKit
import OSLog

@main
final class AppDelegate: UIResponder, UIApplicationDelegate {
    let appConfig = ADEduKitMyAppConfig()

    func configureLog() {
        let log = ADLog.sharedInstance
        let sc = SharedContainer.sharedInstance
        guard let url = sc.contentProviderLogURL else {
            Log.log("\(#function): could not determine log url")
            return
        }
        Log.log("\(#function): using log directory \(url)")
        let w = ADLogWriterFile(url: url)
        log.add(writer: w)
        let l = log.logger(named: "dummy")
        l.log("ClassKitContentProvider configured log.")
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        os_log(.info, "\(#function)")

        // explore locale options, if needed:
        // ADEduLocaleUtil.sharedInstance.explore()

        let repo = Facade.sharedInstance.repo()
        _ = repo.registerContainerName(name: "adedukitcontentapp")
        let container = repo.containerForName(name: "adedukitcontentapp")
        let _ = container?.metadata()
        if let model = container?.rootModelNode() {
            if let util = container?.classKitUtil() {
                util.setupContext(model: model)
            }
        }

        return true
    }

    // MARK: UISceneSession Lifecycle

    func application(_ application: UIApplication, configurationForConnecting connectingSceneSession: UISceneSession, options: UIScene.ConnectionOptions) -> UISceneConfiguration {
        os_log(.info, "\(#function)")
        // Called when a new scene session is being created.
        // Use this method to select a configuration to create the new scene with.
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {
        os_log(.info, "\(#function)")
        // Called when the user discards a scene session.
        // If any sessions were discarded while the application was not running, this will be called shortly after application:didFinishLaunchingWithOptions.
        // Use this method to release any resources that were specific to the discarded scenes, as they will not return.
    }

    // MARK: - ClassKit

    func application(_ application: UIApplication, continue userActivity: NSUserActivity, restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void) -> Bool {
        os_log(.info, "\(#function)")

        if userActivity.isClassKitDeepLink {
            os_log(.info, "\(#function): userActivity isClassKitDeepLink")
            if let path = userActivity.contextIdentifierPath {
                let result = navigateToIdentifierPath(path: path)
                return result
            }
        }
        return false
    }

    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        os_log(.info, "\(#function): url=\(url)")
        if url.scheme == appConfig.standardScheme() {
            let path = url.pathComponents
            let result = navigateToIdentifierPath(path: path)
            return result
        }
        return false
    }

    // MARK: - ClassKit helper

    func navigateToIdentifierPath(path: [String]) -> Bool {
        let ctxvc = ContextViewController.createInstance()
        let repo = Facade.sharedInstance.repo()
        // let _ = repo.registerContainerName(name: "adedukitcontentapp")
        let container = repo.containerForName(name: appConfig.standardContainerName())
        let rootmodel = container?.rootModelNode()
        let model = rootmodel?.modelAt(path: path, absolute: true)

        ctxvc.container = container
        ctxvc.model = model

        let rootVc : UIViewController? = UIApplication.shared.windows.first?.rootViewController
        let pvc = rootVc?.presentedViewController ?? rootVc
        pvc?.present(ctxvc, animated: true, completion: nil)
        return true
    }
}

