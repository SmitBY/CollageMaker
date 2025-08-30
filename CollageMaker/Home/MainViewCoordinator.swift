//
//  MainViewCoordinator.swift
//  CollageMaker
//
//  Created by AI Assistant on 02.02.2025.
//

import UIKit
import RxSwift

/// Координатор для работы с MainTabBarController вместо UINavigationController
class MainViewCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    private let disposeBag = DisposeBag()

    // Ссылка на таб-бар контроллер для управления навигацией
    weak var tabBarController: MainTabBarController?

    init(tabBarController: MainTabBarController?) {
        self.tabBarController = tabBarController
    }

    func start() {
        // Этот координатор не запускает сам себя, он используется для навигации
    }

    /// Переход на CollageEditorViewController с выбранным шаблоном.
    func showCollageEditor(with template: CollageTemplate) {
        print("[MainViewCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")

        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel)

        // Устанавливаем координатор для навигации из редактора
        editorVC.coordinator = self

        // Используем таб-бар для модального показа редактора
        if let tabBarController = tabBarController {
            let navController = UINavigationController(rootViewController: editorVC)
            navController.modalPresentationStyle = .fullScreen
            tabBarController.present(navController, animated: true, completion: nil)
        }
    }

    /// Показ PhotoEditorViewController поверх текущего контроллера
    func showPhotoEditor(with image: UIImage) {
        let photoEditorViewModel = PhotoEditorViewModel(image: image)
        let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
        photoEditorVC.modalPresentationStyle = .overFullScreen

        if let tabBarController = tabBarController {
            tabBarController.present(photoEditorVC, animated: true, completion: nil)
        }
    }

    /// Переход на галерею проектов
    func showGallery() {
        if let tabBarController = tabBarController {
            tabBarController.selectTab(index: 3) // Projects tab
        }
    }
}
