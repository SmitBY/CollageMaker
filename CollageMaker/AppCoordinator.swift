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
    var navigationController: UINavigationController { get set }
    
    func start()
}

class AppCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController

    /// Designated initializer with a UINavigationController dependency.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
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
        let onboardingCoordinator = OnboardingCoordinator(navigationController: navigationController)
        onboardingCoordinator.start()
        childCoordinators.append(onboardingCoordinator)
    }
    
    /// Configures and displays the Main screen using MainTabBarCoordinator.
    private func showHomeScreen() {
        
        // Initialize the MainTabBarCoordinator with the Main navigation controller.
        let mainTabBarCoordinator = MainTabBarCoordinator(navigationController: navigationController)
        mainTabBarCoordinator.start()
        childCoordinators.append(mainTabBarCoordinator)
        
    }
}
