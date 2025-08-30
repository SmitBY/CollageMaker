//
//  AppCoordinator.swift
//  
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa

protocol Coordinator: AnyObject {
    var childCoordinators: [Coordinator] { get set }

    func start()
}

class AppCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    private var rootViewController: UIViewController?

    /// Designated initializer without navigation controller for tab-based UI
    init() {
        // Empty initializer for new architecture
    }

    /// Legacy initializer with navigation controller for backward compatibility
    convenience init(navigationController: UINavigationController) {
        self.init()
        // For backward compatibility, we can still set up navigation if needed
    }
    
    /// Starts the app flow by checking if the user is new and then showing either the onboarding or home screen.
    func start() {
        if isUserNew() {
            showOnboarding()
        } else {
            showHomeScreen()
        }
    }
    
    /// Placeholder method to determine if the user is new.
    private func isUserNew() -> Bool {
        // Insert user newness logic here.
        return false
    }
    
    /// Starts the onboarding flow.
    private func showOnboarding() {
        // For now, skip onboarding and show home screen
        showHomeScreen()
    }

    /// Configures and displays the Main screen using MainTabBarController.
    private func showHomeScreen() {
        let mainTabBarController = MainTabBarController()
        rootViewController = mainTabBarController
    }

    /// Returns the root view controller for the app
    func getRootViewController() -> UIViewController? {
        return rootViewController
    }
}
