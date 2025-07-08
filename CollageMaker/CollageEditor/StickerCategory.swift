import UIKit

// MARK: - StickerCategory
enum StickerCategory: String, CaseIterable, Codable {
    case frequentlyUsed = "часто_используемые"
    case emotions = "эмоции"
    case animals = "животные"
    case objects = "объекты"
    case nature = "природа"
    case symbols = "символы"
    case bundleStickers = "стикеры"
    
    var displayName: String {
        switch self {
        case .frequentlyUsed:
            return "Часто используемые"
        case .emotions:
            return "Эмоции"
        case .animals:
            return "Животные"
        case .objects:
            return "Объекты"
        case .nature:
            return "Природа"
        case .symbols:
            return "Символы"
        case .bundleStickers:
            return "Стикеры"
        }
    }
    
    var iconName: String {
        switch self {
        case .frequentlyUsed:
            return "clock.fill"
        case .emotions:
            return "face.smiling.fill"
        case .animals:
            return "pawprint.fill"
        case .objects:
            return "cube.fill"
        case .nature:
            return "leaf.fill"
        case .symbols:
            return "star.fill"
        case .bundleStickers:
            return "photo.fill"
        }
    }
}

// MARK: - Enhanced StickerItem
struct StickerItem {
    enum StickerType {
        case emoji
        case systemIcon
        case assetImage
        case bundleImage
    }
    
    let type: StickerType
    let content: String
    let category: StickerCategory
    var isSelected: Bool = false
    var usageCount: Int = 0
    var lastUsedDate: Date?
    
    init(type: StickerType, content: String, category: StickerCategory = .symbols) {
        self.type = type
        self.content = content
        self.category = category
    }
    
    func generateImage(size: CGSize = CGSize(width: 60, height: 60)) -> UIImage? {
        switch type {
        case .emoji:
            return generateEmojiImage(emoji: content, size: size)
        case .systemIcon:
            return generateSystemIconImage(iconName: content, size: size)
        case .assetImage:
            return UIImage(named: content)
        case .bundleImage:
            return UIImage(named: content)
        }
    }
    
    private func generateEmojiImage(emoji: String, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        let font = UIFont.systemFont(ofSize: size.width * 0.7)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = emoji.size(withAttributes: attributes)
        
        let rect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        emoji.draw(in: rect, withAttributes: attributes)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func generateSystemIconImage(iconName: String, size: CGSize) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.6, weight: .medium)
        return UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
    }
    
    // Метод для увеличения счетчика использования
    mutating func markAsUsed() {
        usageCount += 1
        lastUsedDate = Date()
    }
}

// MARK: - StickerManager
class StickerManager {
    static let shared = StickerManager()
    private let userDefaults = UserDefaults.standard
    private let frequentlyUsedKey = "frequently_used_stickers"
    
    private init() {}
    
    // Получение всех стикеров по категориям
    func getAllStickers() -> [StickerCategory: [StickerItem]] {
        var categorizedStickers: [StickerCategory: [StickerItem]] = [:]
        
        // Эмоции
        categorizedStickers[.emotions] = [
            StickerItem(type: .emoji, content: "😀", category: .emotions),
            StickerItem(type: .emoji, content: "😍", category: .emotions),
            StickerItem(type: .emoji, content: "🤣", category: .emotions),
            StickerItem(type: .emoji, content: "😎", category: .emotions),
            StickerItem(type: .emoji, content: "🥳", category: .emotions),
            StickerItem(type: .emoji, content: "😇", category: .emotions),
            StickerItem(type: .emoji, content: "🤔", category: .emotions),
            StickerItem(type: .emoji, content: "😴", category: .emotions),
            StickerItem(type: .emoji, content: "🤗", category: .emotions),
            StickerItem(type: .emoji, content: "😘", category: .emotions)
        ]
        
        // Животные
        categorizedStickers[.animals] = [
            StickerItem(type: .emoji, content: "🐶", category: .animals),
            StickerItem(type: .emoji, content: "🐱", category: .animals),
            StickerItem(type: .emoji, content: "🐭", category: .animals),
            StickerItem(type: .emoji, content: "🐹", category: .animals),
            StickerItem(type: .emoji, content: "🐰", category: .animals),
            StickerItem(type: .emoji, content: "🦊", category: .animals),
            StickerItem(type: .emoji, content: "🐻", category: .animals),
            StickerItem(type: .emoji, content: "🐼", category: .animals),
            StickerItem(type: .emoji, content: "🐨", category: .animals),
            StickerItem(type: .emoji, content: "🐯", category: .animals)
        ]
        
        // Объекты
        categorizedStickers[.objects] = [
            StickerItem(type: .emoji, content: "⚽", category: .objects),
            StickerItem(type: .emoji, content: "🏀", category: .objects),
            StickerItem(type: .emoji, content: "🎯", category: .objects),
            StickerItem(type: .emoji, content: "🎮", category: .objects),
            StickerItem(type: .emoji, content: "🎁", category: .objects),
            StickerItem(type: .emoji, content: "🎈", category: .objects),
            StickerItem(type: .emoji, content: "🎂", category: .objects),
            StickerItem(type: .emoji, content: "📱", category: .objects),
            StickerItem(type: .emoji, content: "💻", category: .objects),
            StickerItem(type: .emoji, content: "📷", category: .objects)
        ]
        
        // Природа
        categorizedStickers[.nature] = [
            StickerItem(type: .emoji, content: "🌟", category: .nature),
            StickerItem(type: .emoji, content: "⭐", category: .nature),
            StickerItem(type: .emoji, content: "🌈", category: .nature),
            StickerItem(type: .emoji, content: "☀️", category: .nature),
            StickerItem(type: .emoji, content: "🌙", category: .nature),
            StickerItem(type: .emoji, content: "⚡", category: .nature),
            StickerItem(type: .emoji, content: "🔥", category: .nature),
            StickerItem(type: .emoji, content: "🌸", category: .nature),
            StickerItem(type: .emoji, content: "🌺", category: .nature),
            StickerItem(type: .emoji, content: "🌻", category: .nature)
        ]
        
        // Символы
        categorizedStickers[.symbols] = [
            StickerItem(type: .emoji, content: "❤️", category: .symbols),
            StickerItem(type: .emoji, content: "💕", category: .symbols),
            StickerItem(type: .emoji, content: "💖", category: .symbols),
            StickerItem(type: .emoji, content: "✨", category: .symbols),
            StickerItem(type: .emoji, content: "💎", category: .symbols),
            StickerItem(type: .emoji, content: "🎵", category: .symbols),
            StickerItem(type: .emoji, content: "🎉", category: .symbols),
            StickerItem(type: .emoji, content: "🎊", category: .symbols),
            StickerItem(type: .systemIcon, content: "heart.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "star.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "bolt.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "flame.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "crown.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "diamond.fill", category: .symbols),
            StickerItem(type: .systemIcon, content: "sparkles", category: .symbols)
        ]
        
        // Стикеры из Bundle
        categorizedStickers[.bundleStickers] = loadBundleStickers()
        
        // Часто используемые (загружаем из UserDefaults)
        categorizedStickers[.frequentlyUsed] = getFrequentlyUsedStickers()
        
        return categorizedStickers
    }
    
    private func loadBundleStickers() -> [StickerItem] {
        let stickerNames = [
            "sticker_01", "sticker_02", "sticker_03", "sticker_04", "sticker_05",
            "image-DFOtpQFrS2TDZYYTKpe3t1xzBXxyqN", "image-nI4awJxBtlfLCLZ7nqsHrh1qJ6AcSI",
            "image-SLW4v3ZRvj7Si9YqPiWqBSY3K1J03w", "image-590phLtyyJKpI5cBKwpJTC0PQxprv2"
        ]
        
        return stickerNames.compactMap { name in
            guard UIImage(named: name) != nil else { return nil }
            return StickerItem(type: .bundleImage, content: name, category: .bundleStickers)
        }
    }
    
    // Получение часто используемых стикеров
    func getFrequentlyUsedStickers() -> [StickerItem] {
        guard let data = userDefaults.data(forKey: frequentlyUsedKey),
              let frequentlyUsed = try? JSONDecoder().decode([FrequentStickerData].self, from: data) else {
            return []
        }
        
        return frequentlyUsed.compactMap { data in
            var item = StickerItem(type: data.type, content: data.content, category: data.category)
            item.usageCount = data.usageCount
            item.lastUsedDate = data.lastUsedDate
            return item
        }.sorted { $0.usageCount > $1.usageCount }
    }
    
    // Добавление стикера в часто используемые
    func markStickerAsUsed(_ sticker: StickerItem) {
        var frequentlyUsed = getFrequentlyUsedStickers()
        
        if let existingIndex = frequentlyUsed.firstIndex(where: { $0.content == sticker.content && $0.type == sticker.type }) {
            frequentlyUsed[existingIndex].usageCount += 1
            frequentlyUsed[existingIndex].lastUsedDate = Date()
        } else {
            var newSticker = sticker
            newSticker.markAsUsed()
            frequentlyUsed.append(newSticker)
        }
        
        // Ограничиваем до 20 наиболее используемых
        frequentlyUsed = Array(frequentlyUsed.sorted { $0.usageCount > $1.usageCount }.prefix(20))
        
        saveFrequentlyUsedStickers(frequentlyUsed)
    }
    
    private func saveFrequentlyUsedStickers(_ stickers: [StickerItem]) {
        let stickerData = stickers.map { sticker in
            FrequentStickerData(
                type: sticker.type,
                content: sticker.content,
                category: sticker.category,
                usageCount: sticker.usageCount,
                lastUsedDate: sticker.lastUsedDate
            )
        }
        
        if let data = try? JSONEncoder().encode(stickerData) {
            userDefaults.set(data, forKey: frequentlyUsedKey)
        }
    }
}

// MARK: - FrequentStickerData
private struct FrequentStickerData: Codable {
    let type: StickerItem.StickerType
    let content: String
    let category: StickerCategory
    let usageCount: Int
    let lastUsedDate: Date?
}

// MARK: - StickerItem.StickerType Codable
extension StickerItem.StickerType: Codable {
    enum CodingKeys: String, CodingKey {
        case emoji, systemIcon, assetImage, bundleImage
    }
    
    init(from decoder: Decoder) throws {
        let container = try decoder.singleValueContainer()
        let value = try container.decode(String.self)
        
        switch value {
        case "emoji": self = .emoji
        case "systemIcon": self = .systemIcon
        case "assetImage": self = .assetImage
        case "bundleImage": self = .bundleImage
        default: throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: decoder.codingPath, debugDescription: "Unknown StickerType"))
        }
    }
    
    func encode(to encoder: Encoder) throws {
        var container = encoder.singleValueContainer()
        switch self {
        case .emoji: try container.encode("emoji")
        case .systemIcon: try container.encode("systemIcon")
        case .assetImage: try container.encode("assetImage")
        case .bundleImage: try container.encode("bundleImage")
        }
    }
} 