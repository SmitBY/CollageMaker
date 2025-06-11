//
//  HomeViewModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import Foundation
import RxSwift
import RxCocoa

/// ViewModel for the Home screen.
/// It loads and provides the list of collage templates.
class HomeViewModel {
    /// Title for the Home screen.
    let title = BehaviorRelay<String>(value: "Home Screen")
    
    /// Relay for the index of the selected cell.
        let selectedIndex = PublishRelay<Int>()
    
    /// BehaviorRelay holding an array of collage templates.
    let collageTemplates = BehaviorRelay<[CollageTemplate]>(value: [])
    weak var coordinator: HomeViewCoordinator?
    private let disposeBag = DisposeBag()
    
    init() {
        loadCollageTemplates()
    }
    
    /// Loads collage templates from the manager.
    private func loadCollageTemplates() {
        // For example, we get templates from CollageTemplatesManager.
        let templates = CollageTemplatesManager.shared.templates
        collageTemplates.accept(templates)
    }
}
