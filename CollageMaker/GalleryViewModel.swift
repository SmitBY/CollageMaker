//
//  GalleryViewModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import Foundation
import RxSwift
import RxCocoa
import UIKit
import Photos

class GalleryViewModel {
    let title = BehaviorRelay<String>(value: "Галерея")
    let savedCollages = BehaviorRelay<[SavedCollage]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    
    private let disposeBag = DisposeBag()
    
    init() {
        loadSavedCollages()
    }
    
    func loadSavedCollages() {
        print("🔄 [GalleryViewModel] Начинаем загрузку коллажей...")
        isLoading.accept(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let collages = SavedCollagesManager.shared.getAllCollages()
            
            DispatchQueue.main.async {
                print("🔄 [GalleryViewModel] Загружено \(collages.count) коллажей, обновляем UI")
                self?.savedCollages.accept(collages)
                self?.isLoading.accept(false)
            }
        }
    }
    
    func deleteCollage(at index: Int) {
        let currentCollages = savedCollages.value
        guard index < currentCollages.count else { 
            print("Error: Index \(index) out of bounds for collages array")
            return 
        }
        
        let collageToDelete = currentCollages[index]
        print("Deleting collage with ID: \(collageToDelete.id)")
        
        // Удаляем из галереи устройства
        PHPhotoLibrary.shared().performChanges({
            // Получаем все фотографии из галереи
            let fetchOptions = PHFetchOptions()
            fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
            let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
            
            // Ищем фотографию, которая соответствует нашему коллажу
            assets.enumerateObjects { asset, _, _ in
                if let creationDate = asset.creationDate,
                   abs(creationDate.timeIntervalSince(collageToDelete.createdDate)) < 1.0 { // Разница в 1 секунду
                    PHAssetChangeRequest.deleteAssets([asset] as NSArray)
                }
            }
        }) { success, error in
            if let error = error {
                print("Error deleting from photo library: \(error.localizedDescription)")
            }
        }
        
        // Удаляем из локального хранилища
        SavedCollagesManager.shared.deleteCollage(withId: collageToDelete.id)
        
        // Обновляем список
        loadSavedCollages()
    }
    
    func deleteCollage(withId id: String) {
        print("Deleting collage with ID: \(id)")
        SavedCollagesManager.shared.deleteCollage(withId: id)
        loadSavedCollages()
    }
    
    func getCollage(at index: Int) -> SavedCollage? {
        let currentCollages = savedCollages.value
        guard index < currentCollages.count else { return nil }
        return currentCollages[index]
    }
}
