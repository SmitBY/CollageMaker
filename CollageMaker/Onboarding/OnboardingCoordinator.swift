//
//  OnboardingCoordinator.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit

class OnboardingCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    var navigationController: UINavigationController
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let onboardingVC = OnboardingViewController(viewModel: OnboardingViewModel())
        navigationController.pushViewController(onboardingVC, animated: true)
    }
}
