//
//  AppCoordinator.swift
//  
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa

protocol Coordinator {
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
    
    /// Configures and displays the Home screen using HomeTabBarCoordinator.
    private func showHomeScreen() {
        
        // Initialize the HomeTabBarCoordinator with the Home navigation controller.
        let homeTabBarCoordinator = HomeTabBarCoordinator(navigationController: navigationController)
        homeTabBarCoordinator.start()
        childCoordinators.append(homeTabBarCoordinator)
        
    }
}
