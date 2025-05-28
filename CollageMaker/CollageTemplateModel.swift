//
//  CollageTemplateModel.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import Foundation
import UIKit

// Data model representing a collage template
struct CollageTemplate {
    let id: Int
    let name: String
    let positions: [(Int, Int)]
}

// MARK: - Saved Collage Model
struct SavedCollage {
    let id: String
    let image: UIImage
    let createdDate: Date
    let templateName: String
    
    init(image: UIImage, templateName: String) {
        self.id = UUID().uuidString
        self.image = image
        self.createdDate = Date()
        self.templateName = templateName
    }
    
    init(id: String, image: UIImage, createdDate: Date, templateName: String) {
        self.id = id
        self.image = image
        self.createdDate = createdDate
        self.templateName = templateName
    }
}

// MARK: - Saved Collages Manager
class SavedCollagesManager {
    static let shared = SavedCollagesManager()
    private let userDefaults = UserDefaults.standard
    private let collagesKey = "SavedCollages"
    
    private init() {}
    
    func saveCollage(_ collage: SavedCollage) {
        var savedCollages = getAllCollages()
        savedCollages.append(collage)
        
        // Сохраняем изображение в Documents
        if let imageData = collage.image.jpegData(compressionQuality: 0.8) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagePath = documentsPath.appendingPathComponent("\(collage.id).jpg")
            try? imageData.write(to: imagePath)
        }
        
        // Сохраняем метаданные в UserDefaults
        let collageData = savedCollages.map { collage in
            [
                "id": collage.id,
                "createdDate": collage.createdDate.timeIntervalSince1970,
                "templateName": collage.templateName
            ]
        }
        userDefaults.set(collageData, forKey: collagesKey)
    }
    
    func getAllCollages() -> [SavedCollage] {
        guard let collagesData = userDefaults.array(forKey: collagesKey) as? [[String: Any]] else {
            return []
        }
        
        return collagesData.compactMap { data -> SavedCollage? in
            guard let id = data["id"] as? String,
                  let timestamp = data["createdDate"] as? TimeInterval,
                  let templateName = data["templateName"] as? String else {
                return nil
            }
            
            // Загружаем изображение из Documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagePath = documentsPath.appendingPathComponent("\(id).jpg")
            
            guard let imageData = try? Data(contentsOf: imagePath),
                  let image = UIImage(data: imageData) else {
                return nil
            }
            
            return SavedCollage(
                id: id,
                image: image,
                createdDate: Date(timeIntervalSince1970: timestamp),
                templateName: templateName
            )
        }.sorted { $0.createdDate > $1.createdDate } // Сортируем по дате создания (новые сначала)
    }
    
    func deleteCollage(withId id: String) {
        var savedCollages = getAllCollages()
        savedCollages.removeAll { $0.id == id }
        
        // Удаляем изображение из Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("\(id).jpg")
        try? FileManager.default.removeItem(at: imagePath)
        
        // Обновляем UserDefaults
        let collageData = savedCollages.map { collage in
            [
                "id": collage.id,
                "createdDate": collage.createdDate.timeIntervalSince1970,
                "templateName": collage.templateName
            ]
        }
        userDefaults.set(collageData, forKey: collagesKey)
    }
}
