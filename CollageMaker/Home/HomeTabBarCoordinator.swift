//
//  HomeTabBarCoordinator.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 01.02.2025.
//

import UIKit
import RxSwift
import RxCocoa

class HomeTabBarCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let disposeBag = DisposeBag()
    
    /// Designated initializer with a UINavigationController dependency.
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    /// Starts the Home tab flow by creating the custom HomeTabBarController.
    func start() {
        // Create view models for Home, Gallery and Edit screens.
        let homeVM = HomeViewModel()
        let galleryVM = GalleryViewModel()
        let editVM = EditViewModel()
        
        // Убираем автоматический переход к редактору коллажа
        // Теперь главный экран сам управляет созданием коллажей
        
        // Create an instance of your custom HomeTabBarController.
        let homeTabBarController = HomeTabBarController(viewModel: homeVM,
                                                        galleryViewModel: galleryVM,
                                                        editViewModel: editVM)
        
        // Устанавливаем ссылку на координатор
        homeTabBarController.coordinator = self
        
        // Set the HomeTabBarController as the root view controller.
        // Не оборачиваем его в UINavigationController, если HomeTabBarController сам реализует навигационную логику.
        navigationController.setViewControllers([homeTabBarController], animated: true)
    }
    
    /// Navigates to the Collage Editor screen with the selected template and photos.
    func showCollageEditor(with template: CollageTemplate, selectedPhotos: [UIImage] = []) {
        print("[HomeTabBarCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")
        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel, selectedPhotos: selectedPhotos)
        editorVC.coordinator = self
        navigationController.pushViewController(editorVC, animated: true)
    }
    
    /// Новый метод для показа PhotoEditorViewController поверх CollageEditorViewController.
    func showPhotoEditor(with image: UIImage) {
        let photoEditorViewModel = PhotoEditorViewModel(image: image)
        let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
        photoEditorVC.modalPresentationStyle = .overFullScreen
        navigationController.present(photoEditorVC, animated: true, completion: nil)
    }
    
    /// Переключает на вкладку галереи
    func showGallery() {
        // Сначала возвращаемся к root контроллеру (HomeTabBarController)
        navigationController.popToRootViewController(animated: true)
        
        // Затем переключаемся на вкладку галереи
        if let homeTabBarController = navigationController.viewControllers.first as? HomeTabBarController {
            // Делаем это с небольшой задержкой, чтобы анимация pop завершилась
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                homeTabBarController.selectGalleryTab()
            }
        }
    }
}
