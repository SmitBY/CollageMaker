//
//  SceneDelegate.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?
    var appCoordinator: AppCoordinator?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }
        
        window = UIWindow(windowScene: windowScene)

        // Создаем AppCoordinator без navigation controller, так как MainTabBarController сам управляет UI
        appCoordinator = AppCoordinator()
        appCoordinator?.start()

        // Глобальная темная тема
        if #available(iOS 13.0, *) {
            window?.overrideUserInterfaceStyle = .dark
        }

        // Настраиваем root view controller через coordinator
        if let rootVC = appCoordinator?.getRootViewController() {
            window?.rootViewController = rootVC
        }
        window?.makeKeyAndVisible()
    }
}
