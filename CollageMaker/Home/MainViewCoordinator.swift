//
//  MainViewCoordinator.swift
//  CollageMaker
//
//  Created by AI Assistant on 02.02.2025.
//

import UIKit
import RxSwift

/// Координатор для работы с MainTabBarController вместо UINavigationController
class MainViewCoordinator: Coordinator, PhotoEditorRouting {
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
    /// - Parameters:
    ///   - template: выбранный шаблон
    ///   - selectedPhotos: массив выбранных пользователем изображений
    func showCollageEditor(with template: CollageTemplate, selectedPhotos: [UIImage] = []) {
        print("[MainViewCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")

        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel, selectedPhotos: selectedPhotos)

        // Устанавливаем координатор для навигации из редактора (реализует PhotoEditorRouting)
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
        
        guard let tabBarController = tabBarController else { return }

        // Всегда показываем модально на весь экран от корневого верхнего VC
        var presenter: UIViewController = tabBarController
        while let presented = presenter.presentedViewController {
            presenter = presented
        }
        let nav = UINavigationController(rootViewController: photoEditorVC)
        nav.modalPresentationStyle = .fullScreen
        nav.setNavigationBarHidden(true, animated: false)
        photoEditorVC.modalTransitionStyle = .crossDissolve
        presenter.present(nav, animated: true, completion: nil)
    }

    func showGallery() {
        if let tabBarController = tabBarController {
            tabBarController.selectTab(index: 3)
        }
    }
}
