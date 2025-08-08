//
//  AppDelegate.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?) -> Bool {
        let window = UIWindow(frame: UIScreen.main.bounds)
        let navigationController = UINavigationController()
        appCoordinator = AppCoordinator(navigationController: navigationController)
        appCoordinator?.start()
        
        // Глобальная настройка темной темы и белого статус-бара
        if #available(iOS 13.0, *) {
            window.overrideUserInterfaceStyle = .dark
        }

        // Оформление навигации: черный фон, белые заголовки и элементы
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .black
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        appearance.largeTitleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController.navigationBar.standardAppearance = appearance
        navigationController.navigationBar.scrollEdgeAppearance = appearance
        navigationController.navigationBar.compactAppearance = appearance
        navigationController.navigationBar.tintColor = .white
        navigationController.navigationBar.barStyle = .black

        window.rootViewController = navigationController
        window.makeKeyAndVisible()
        self.window = window
        
        return true
    }
}
