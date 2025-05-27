//
//  HomeViewCoordinator.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 01.02.2025.
//

import UIKit
import RxSwift

class HomeViewCoordinator: Coordinator {
    var childCoordinators: [Coordinator] = []
    var navigationController: UINavigationController
    private let disposeBag = DisposeBag()
    
    // Добавляем свойство для хранения ссылки на этот координатор (если нужно передать его в дочерние контроллеры).
    
    init(navigationController: UINavigationController) {
        self.navigationController = navigationController
    }
    
    func start() {
        let homeViewModel = HomeViewModel()
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
    func showCollageEditor(with template: CollageTemplate) {
        print("[HomeViewCoordinator] Navigating to CollageEditorViewController with template: \(template.name)")
        let editorViewModel = CollageEditorViewModel(template: template)
        let editorVC = CollageEditorViewController(viewModel: editorViewModel)
        // Передаем ссылку на координатор, чтобы CollageEditorViewController мог уведомлять его о выборе фото.
        navigationController.pushViewController(editorVC, animated: true)
    }
    
    /// Новый метод для показа PhotoEditorViewController поверх CollageEditorViewController.
    func showPhotoEditor(with image: UIImage) {
        let photoEditorViewModel = PhotoEditorViewModel(image: image)
        let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
        photoEditorVC.modalPresentationStyle = .overFullScreen
        navigationController.present(photoEditorVC, animated: true, completion: nil)
    }
}
