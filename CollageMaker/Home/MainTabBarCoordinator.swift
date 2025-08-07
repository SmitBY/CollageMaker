//
//  MainTabBarCoordinator.swift
//  CollageMaker
//
//  Created by AI Assistant on 02.02.2025.
//

import UIKit
import RxSwift
import RxCocoa

class MainTabBarCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let disposeBag = DisposeBag()
    
    /// Designated initializer with a UINavigationController dependency.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    /// Starts the Main tab flow by creating the custom MainTabBarController.
    func start() {
        // Скрываем навигационную панель для полноэкранного отображения
        navigationController.isNavigationBarHidden = true
        
        // Create an instance of MainTabBarController.
        let mainTabBarController = MainTabBarController()
        
        // Устанавливаем ссылку на координатор
        mainTabBarController.coordinator = self
        
        // Set the MainTabBarController as the root view controller.
        navigationController.setViewControllers([mainTabBarController], animated: true)
    }
    
    /// Показывает экран создания проекта (используется как fallback, основная логика теперь в MainTabBarController)
    func showCreateProject() {
        print("[MainTabBarCoordinator] Fallback showCreateProject called - switching to create tab")
        
        // Переключаемся на вкладку создания коллажа в текущем MainTabBarController
        if let mainTabBarController = navigationController.viewControllers.first as? MainTabBarController {
            mainTabBarController.selectTab(index: 2)
        }
    }
    
    /// Navigates to the Collage Editor screen with the selected template and photos.
    func showCollageEditor(with template: CollageTemplate, selectedPhotos: [UIImage] = []) {
        print("[MainTabBarCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")
        
        // Показываем навигационную панель для редактора коллажа
        navigationController.isNavigationBarHidden = false
        
        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel, selectedPhotos: selectedPhotos)
        editorVC.coordinator = self
        navigationController.pushViewController(editorVC, animated: true)
    }
    
    /// Показывает PhotoEditor поверх текущего экрана.
    func showPhotoEditor(with image: UIImage, completion: @escaping (UIImage?) -> Void) {
        let photoEditorViewModel = PhotoEditorViewModel(image: image)
        let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
        photoEditorVC.editingCompletion = completion
        photoEditorVC.modalPresentationStyle = .overFullScreen
        navigationController.present(photoEditorVC, animated: true, completion: nil)
    }
    
    /// Переключает на вкладку галереи после сохранения коллажа
    func showGallery() {
        // Сначала возвращаемся к root контроллеру (MainTabBarController)
        navigationController.popToRootViewController(animated: true)
        
        // Скрываем навигационную панель обратно
        navigationController.isNavigationBarHidden = true
        
        // Затем переключаемся на вкладку Projects (галерея)
        if let mainTabBarController = navigationController.viewControllers.first as? MainTabBarController {
            // Делаем это с небольшой задержкой, чтобы анимация pop завершилась
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                mainTabBarController.selectTab(index: 3) // Индекс 3 = Projects
            }
        }
    }
    
    /// Возвращается к главному экрану
    func returnToMain() {
        navigationController.popToRootViewController(animated: true)
        
        // Скрываем навигационную панель обратно
        navigationController.isNavigationBarHidden = true
    }
}