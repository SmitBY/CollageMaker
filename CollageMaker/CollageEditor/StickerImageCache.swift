import UIKit

// MARK: - StickerImageCache
class StickerImageCache {
    static let shared = StickerImageCache()
    
    private let cache = NSCache<NSString, UIImage>()
    private let cacheQueue = DispatchQueue(label: "sticker.image.cache", qos: .utility)
    
    private init() {
        setupCache()
    }
    
    private func setupCache() {
        // Настройка лимитов кэша
        cache.countLimit = 100 // Максимум 100 изображений
        cache.totalCostLimit = 50 * 1024 * 1024 // 50MB максимум
        
        // Очистка кэша при предупреждении о памяти
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(clearCache),
            name: UIApplication.didReceiveMemoryWarningNotification,
            object: nil
        )
    }
    
    @objc private func clearCache() {
        cache.removeAllObjects()
    }
    
    // MARK: - Public Methods
    
    func cachedImage(for item: StickerItem) -> UIImage? {
        let key = cacheKey(for: item)
        return cache.object(forKey: key)
    }
    
    func cacheImage(_ image: UIImage, for item: StickerItem) {
        let key = cacheKey(for: item)
        let cost = imageCost(image)
        
        cacheQueue.async { [weak self] in
            self?.cache.setObject(image, forKey: key, cost: cost)
        }
    }
    
    func generateAndCacheImage(for item: StickerItem, size: CGSize = CGSize(width: 60, height: 60), completion: @escaping (UIImage?) -> Void) {
        let key = cacheKey(for: item)
        
        // Проверяем кэш сначала
        if let cachedImage = cache.object(forKey: key) {
            DispatchQueue.main.async {
                completion(cachedImage)
            }
            return
        }
        
        // Генерируем изображение в фоновой очереди
        cacheQueue.async { [weak self] in
            let image = item.generateImage(size: size)
            
            if let image = image {
                let cost = self?.imageCost(image) ?? 0
                self?.cache.setObject(image, forKey: key, cost: cost)
            }
            
            DispatchQueue.main.async {
                completion(image)
            }
        }
    }
    
    func preloadImages(for items: [StickerItem], size: CGSize = CGSize(width: 60, height: 60)) {
        cacheQueue.async { [weak self] in
            for item in items {
                let key = self?.cacheKey(for: item) ?? ""
                
                // Пропускаем уже закэшированные изображения
                if self?.cache.object(forKey: NSString(string: key)) != nil {
                    continue
                }
                
                if let image = item.generateImage(size: size) {
                    let cost = self?.imageCost(image) ?? 0
                    self?.cache.setObject(image, forKey: NSString(string: key), cost: cost)
                }
            }
        }
    }
    
    // MARK: - Private Methods
    
    private func cacheKey(for item: StickerItem) -> NSString {
        return NSString(string: "\(item.type.rawValue)_\(item.content)")
    }
    
    private func imageCost(_ image: UIImage) -> Int {
        guard let cgImage = image.cgImage else { return 0 }
        return cgImage.bytesPerRow * cgImage.height
    }
}

// MARK: - StickerItem.StickerType Extension
extension StickerItem.StickerType {
    var rawValue: String {
        switch self {
        case .emoji: return "emoji"
        case .systemIcon: return "systemIcon"
        case .assetImage: return "assetImage"
        case .bundleImage: return "bundleImage"
        }
    }
} 