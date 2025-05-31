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

class GalleryViewModel {
    let title = BehaviorRelay<String>(value: "Галерея")
    let savedCollages = BehaviorRelay<[SavedCollage]>(value: [])
    let isLoading = BehaviorRelay<Bool>(value: false)
    
    private let disposeBag = DisposeBag()
    
    init() {
        loadSavedCollages()
    }
    
    func loadSavedCollages() {
        isLoading.accept(true)
        
        DispatchQueue.global(qos: .userInitiated).async { [weak self] in
            let collages = SavedCollagesManager.shared.getAllCollages()
            
            DispatchQueue.main.async {
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
