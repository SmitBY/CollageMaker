//
//  HomeViewCoordinator.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 01.02.2025.
//

import UIKit
import RxSwift

class HomeViewCoordinator: Coordinator, PhotoEditorRouting {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let disposeBag = DisposeBag()
    
    // Добавляем свойство для хранения ссылки на этот координатор (если нужно передать его в дочерние контроллеры).
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let homeViewModel = HomeViewModel()
        homeViewModel.coordinator = self
        let homeVC = HomeViewController(viewModel: homeViewModel)
        _ = homeVC.view // Force load the view
        
        if let homeView = homeVC.view as? HomeView {
            homeView.collectionView.allowsSelection = true
        }
        
        homeViewModel.selectedIndex
            .subscribe(onNext: { [weak self] index in
                guard let self = self else { return }
                let templates = homeViewModel.collageTemplates.value
                if index < templates.count {
                    let template = templates[index]
                    self.showCollageEditor(with: template)
                } else {
                    print("[HomeViewCoordinator] Index \(index) out of bounds (templates count: \(templates.count))")
                }
            })
            .disposed(by: disposeBag)
        
        navigationController.pushViewController(homeVC, animated: true)
    }
    
    /// Переход на CollageEditorViewController с выбранным шаблоном.
    /// - Parameters:
    ///   - template: выбранный шаблон
    ///   - selectedPhotos: массив выбранных пользователем изображений
    func showCollageEditor(with template: CollageTemplate, selectedPhotos: [UIImage] = []) {
        print("[HomeViewCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")
        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel, selectedPhotos: selectedPhotos)
        // Передаем координатор для открытия фоторедактора
        editorVC.coordinator = self
        navigationController.pushViewController(editorVC, animated: true)
    }
    
    /// Новый метод для показа PhotoEditorViewController поверх CollageEditorViewController.
    func showPhotoEditor(with image: UIImage) {
        let photoEditorViewModel = PhotoEditorViewModel(image: image)
        let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
        let nav = UINavigationController(rootViewController: photoEditorVC)
        nav.modalPresentationStyle = .fullScreen
        nav.setNavigationBarHidden(true, animated: false)
        navigationController.present(nav, animated: true, completion: nil)
    }

    func showGallery() {
        // Переход в галерею через push
        let vm = GalleryViewModel()
        let vc = GalleryViewController(viewModel: vm)
        vc.coordinator = self
        navigationController.pushViewController(vc, animated: true)
    }
}
