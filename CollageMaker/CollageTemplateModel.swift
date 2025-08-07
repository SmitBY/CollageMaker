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
    let aspectRatioId: String
    
    init(image: UIImage, templateName: String, aspectRatioId: String = "square") {
        self.id = UUID().uuidString
        self.image = image
        self.createdDate = Date()
        self.templateName = templateName
        self.aspectRatioId = aspectRatioId
    }
    
    init(id: String, image: UIImage, createdDate: Date, templateName: String, aspectRatioId: String = "square") {
        self.id = id
        self.image = image
        self.createdDate = createdDate
        self.templateName = templateName
        self.aspectRatioId = aspectRatioId
    }
}

// MARK: - Saved Collages Manager
class SavedCollagesManager {
    static let shared = SavedCollagesManager()
    private let userDefaults = UserDefaults.standard
    private let collagesKey = "SavedCollages"
    
    private init() {}
    
    func saveCollage(_ collage: SavedCollage) {
        print("💾 [SavedCollagesManager] Сохраняем коллаж: \(collage.templateName) с ID: \(collage.id)")
        
        var savedCollages = getAllCollages()
        savedCollages.append(collage)
        
        // Сохраняем изображение в Documents
        if let imageData = collage.image.jpegData(compressionQuality: 0.8) {
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagePath = documentsPath.appendingPathComponent("\(collage.id).jpg")
            do {
                try imageData.write(to: imagePath)
                print("✅ [SavedCollagesManager] Изображение сохранено: \(imagePath)")
            } catch {
                print("❌ [SavedCollagesManager] Ошибка сохранения изображения: \(error)")
            }
        } else {
            print("❌ [SavedCollagesManager] Не удалось создать данные изображения")
        }
        
        // Сохраняем метаданные в UserDefaults
        let collageData = savedCollages.map { collage in
            [
                "id": collage.id,
                "createdDate": collage.createdDate.timeIntervalSince1970,
                "templateName": collage.templateName,
                "aspectRatioId": collage.aspectRatioId
            ]
        }
        userDefaults.set(collageData, forKey: collagesKey)
        print("✅ [SavedCollagesManager] Метаданные сохранены. Всего коллажей: \(savedCollages.count)")
    }
    
    func getAllCollages() -> [SavedCollage] {
        print("📂 [SavedCollagesManager] Загружаем сохраненные коллажи...")
        
        guard let collagesData = userDefaults.array(forKey: collagesKey) as? [[String: Any]] else {
            print("📂 [SavedCollagesManager] Нет сохраненных коллажей в UserDefaults")
            return []
        }
        
        print("📂 [SavedCollagesManager] Найдено \(collagesData.count) записей в UserDefaults")
        
        let loadedCollages = collagesData.compactMap { data -> SavedCollage? in
            guard let id = data["id"] as? String,
                  let timestamp = data["createdDate"] as? TimeInterval,
                  let templateName = data["templateName"] as? String else {
                print("⚠️ [SavedCollagesManager] Неполные данные для коллажа")
                return nil
            }
            
            let aspectRatioId = data["aspectRatioId"] as? String ?? "square"
            
            // Загружаем изображение из Documents
            let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
            let imagePath = documentsPath.appendingPathComponent("\(id).jpg")
            
            guard let imageData = try? Data(contentsOf: imagePath),
                  let image = UIImage(data: imageData) else {
                print("⚠️ [SavedCollagesManager] Не удалось загрузить изображение для коллажа \(id)")
                return nil
            }
            
            print("✅ [SavedCollagesManager] Загружен коллаж: \(templateName) (\(id))")
            return SavedCollage(
                id: id,
                image: image,
                createdDate: Date(timeIntervalSince1970: timestamp),
                templateName: templateName,
                aspectRatioId: aspectRatioId
            )
        }.sorted { $0.createdDate > $1.createdDate } // Сортируем по дате создания (новые сначала)
        
        print("📂 [SavedCollagesManager] Успешно загружено \(loadedCollages.count) коллажей")
        return loadedCollages
    }
    
    func deleteCollage(withId id: String) {
        // Сначала получаем метаданные из UserDefaults (без загрузки изображений)
        guard let collagesData = userDefaults.array(forKey: collagesKey) as? [[String: Any]] else {
            return
        }
        
        // Удаляем коллаж из метаданных
        let updatedCollagesData = collagesData.filter { data in
            guard let collageId = data["id"] as? String else { return true }
            return collageId != id
        }
        
        // Обновляем UserDefaults
        userDefaults.set(updatedCollagesData, forKey: collagesKey)
        
        // Удаляем файл изображения из Documents
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        let imagePath = documentsPath.appendingPathComponent("\(id).jpg")
        
        do {
            try FileManager.default.removeItem(at: imagePath)
            print("Successfully deleted collage file: \(id).jpg")
        } catch {
            print("Error deleting collage file: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Debug Methods
    
    /// Проверяет существование файлов для всех сохраненных коллажей
    func checkFileIntegrity() {
        guard let collagesData = userDefaults.array(forKey: collagesKey) as? [[String: Any]] else {
            print("No collages metadata found")
            return
        }
        
        let documentsPath = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask)[0]
        
        for data in collagesData {
            guard let id = data["id"] as? String else { continue }
            let imagePath = documentsPath.appendingPathComponent("\(id).jpg")
            let fileExists = FileManager.default.fileExists(atPath: imagePath.path)
            print("Collage \(id): metadata exists, file exists: \(fileExists)")
        }
    }
}
