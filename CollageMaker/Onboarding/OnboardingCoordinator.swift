//
//  OnboardingCoordinator.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit

class OnboardingCoordinator: Coordinator {
    var childCoordinators = [Coordinator]()
    private var navigationController: UINavigationController?

    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }

    func start() {
        guard let navigationController = navigationController else {
            print("OnboardingCoordinator: No navigation controller provided")
            return
        }
        let onboardingVC = OnboardingViewController(viewModel: OnboardingViewModel())
        navigationController.pushViewController(onboardingVC, animated: true)
    }
}
