//
//  CollageEditorViewModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 31.01.2025.
//

import Foundation
import RxSwift
import RxCocoa

/// ViewModel for the Collage Editor screen.
/// It holds the current collage template, manages selected images, and enables the save button when needed.
class CollageEditorViewModel {
    /// Holds the current collage template.
    let collageTemplate = BehaviorRelay<CollageTemplate?>(value: nil)
    
    /// Dictionary mapping index paths to selected images.
    let selectedImages = BehaviorRelay<[IndexPath: UIImage]>(value: [:])
    
    /// Determines whether the save button should be enabled.
    let saveButtonEnabled = BehaviorRelay<Bool>(value: false)
    
    private let disposeBag = DisposeBag()
    
    /// Initializes the view model with a given collage template.
    /// - Parameter template: The collage template to be used in the editor.
    init(template: CollageTemplate) {
        collageTemplate.accept(template)
        setupBindings()
    }
    
    /// Sets up reactive bindings.
    /// Save button is always enabled as we can save collage even with placeholder images.
    private func setupBindings() {
        // Кнопка сохранения всегда доступна - можно сохранять коллаж даже с placeholder изображениями
        saveButtonEnabled.accept(true)
    }
    
    /// Sets an image at the specified index path.
    /// - Parameters:
    ///   - indexPath: The index path corresponding to the image slot.
    ///   - image: The image to set.
    func setImage(at indexPath: IndexPath, image: UIImage) {
        var images = selectedImages.value
        images[indexPath] = image
        selectedImages.accept(images)
    }
    
    /// Retrieves the image at the specified index path.
    /// - Parameter indexPath: The index path corresponding to the image slot.
    /// - Returns: The image if it exists, or nil.
    func getImage(at indexPath: IndexPath) -> UIImage? {
        return selectedImages.value[indexPath]
    }
    
    /// Resets all selected images.
    func resetSelectedImages() {
        selectedImages.accept([:])
    }
}
