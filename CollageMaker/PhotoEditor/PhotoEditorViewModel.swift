//
//  PhotoEditorViewModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 03.02.2025.
//

import Foundation
import UIKit
import RxRelay

/// ViewModel for the Photo Editor screen.
/// Он хранит изображение, выбранное пользователем для редактирования.
class PhotoEditorViewModel {
    let image: BehaviorRelay<UIImage?> = BehaviorRelay(value: nil)
    
    init(image: UIImage?) {
        self.image.accept(image)
    }
}
