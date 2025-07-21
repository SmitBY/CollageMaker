import UIKit

/// Перечисление доступных форм рамок для изображений
enum FrameShape: String, CaseIterable {
    case none = "none"
    case circle = "circle"
    case heart = "heart"
    case star = "star"
    case diamond = "diamond"
    case triangle = "triangle"
    case square = "square"
    case flower = "flower"
    case hexagon = "hexagon"
    
    /// Локализованное название формы
    var displayName: String {
        switch self {
        case .none: return "Без рамки"
        case .circle: return "Круг"
        case .heart: return "Сердце"
        case .star: return "Звезда"
        case .diamond: return "Ромб"
        case .triangle: return "Треугольник"
        case .square: return "Квадрат"
        case .flower: return "Цветок"
        case .hexagon: return "Шестиугольник"
        }
    }
    
    /// SF Symbol для иконки формы
    var iconName: String {
        switch self {
        case .none: return "rectangle.dashed"
        case .circle: return "circle"
        case .heart: return "heart"
        case .star: return "star"
        case .diamond: return "diamond"
        case .triangle: return "triangle"
        case .square: return "square"
        case .flower: return "leaf"
        case .hexagon: return "hexagon"
        }
    }
    
    // MARK: - Path Caching
    
    /// Кэш для UIBezierPath paths для улучшения производительности
    private static var pathCache: [String: UIBezierPath] = [:]
    
    /// Создает UIBezierPath для указанной формы в заданных границах
    /// - Parameter bounds: Границы для создания пути
    /// - Returns: UIBezierPath для формы или nil для .none
    func createPath(in bounds: CGRect) -> UIBezierPath? {
        guard self != .none else { return nil }
        
        // Создаем ключ кэша на основе формы и размера
        let cacheKey = "\(self.rawValue)_\(Int(bounds.width))x\(Int(bounds.height))"
        
        // Проверяем кэш
        if let cachedPath = FrameShape.pathCache[cacheKey] {
            return cachedPath.copy() as? UIBezierPath
        }
        
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let minSide = min(bounds.width, bounds.height)
        let radius = minSide / 2
        
        // Создаем путь в зависимости от формы
        let path: UIBezierPath
        switch self {
        case .none:
            return nil
            
        case .circle:
            path = UIBezierPath(arcCenter: center, radius: radius, startAngle: 0, endAngle: .pi * 2, clockwise: true)
            
        case .heart:
            path = createHeartPath(center: center, size: minSide)
            
        case .star:
            path = createStarPath(center: center, radius: radius)
            
        case .diamond:
            path = createDiamondPath(center: center, size: minSide)
            
        case .triangle:
            path = createTrianglePath(center: center, size: minSide)
            
        case .square:
            let squareSize = minSide * 0.9
            let origin = CGPoint(x: center.x - squareSize/2, y: center.y - squareSize/2)
            path = UIBezierPath(rect: CGRect(origin: origin, size: CGSize(width: squareSize, height: squareSize)))
            
        case .flower:
            path = createFlowerPath(center: center, radius: radius)
            
        case .hexagon:
            path = createHexagonPath(center: center, radius: radius)
        }
        
        // Кэшируем путь для повторного использования
        FrameShape.pathCache[cacheKey] = path.copy() as? UIBezierPath
        return path
    }
    
    /// Очищает кэш путей (полезно при нехватке памяти)
    static func clearPathCache() {
        pathCache.removeAll()
    }
    
    // MARK: - Private Path Creation Methods
    
    private func createHeartPath(center: CGPoint, size: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let scale = size / 200.0 // Масштабируем от базового размера 200
        
        // Сердце состоит из двух кругов и треугольника
        let heartWidth = 100 * scale
        let heartHeight = 90 * scale
        
        // Начальная точка снизу по центру
        path.move(to: CGPoint(x: center.x, y: center.y + heartHeight/2))
        
        // Левая часть сердца
        path.addCurve(to: CGPoint(x: center.x - heartWidth/2, y: center.y - heartHeight/6),
                     controlPoint1: CGPoint(x: center.x - heartWidth/4, y: center.y + heartHeight/4),
                     controlPoint2: CGPoint(x: center.x - heartWidth/2, y: center.y + heartHeight/12))
        
        path.addCurve(to: CGPoint(x: center.x, y: center.y - heartHeight/3),
                     controlPoint1: CGPoint(x: center.x - heartWidth/2, y: center.y - heartHeight/2),
                     controlPoint2: CGPoint(x: center.x - heartWidth/6, y: center.y - heartHeight/2))
        
        // Правая часть сердца
        path.addCurve(to: CGPoint(x: center.x + heartWidth/2, y: center.y - heartHeight/6),
                     controlPoint1: CGPoint(x: center.x + heartWidth/6, y: center.y - heartHeight/2),
                     controlPoint2: CGPoint(x: center.x + heartWidth/2, y: center.y - heartHeight/2))
        
        path.addCurve(to: CGPoint(x: center.x, y: center.y + heartHeight/2),
                     controlPoint1: CGPoint(x: center.x + heartWidth/2, y: center.y + heartHeight/12),
                     controlPoint2: CGPoint(x: center.x + heartWidth/4, y: center.y + heartHeight/4))
        
        path.close()
        return path
    }
    
    private func createStarPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let points = 5
        let innerRadius = radius * 0.4
        let angleIncrement = .pi * 2 / CGFloat(points)
        
        for i in 0..<points {
            let outerAngle = CGFloat(i) * angleIncrement - .pi / 2
            let innerAngle = outerAngle + angleIncrement / 2
            
            let outerPoint = CGPoint(
                x: center.x + cos(outerAngle) * radius,
                y: center.y + sin(outerAngle) * radius
            )
            
            let innerPoint = CGPoint(
                x: center.x + cos(innerAngle) * innerRadius,
                y: center.y + sin(innerAngle) * innerRadius
            )
            
            if i == 0 {
                path.move(to: outerPoint)
            } else {
                path.addLine(to: outerPoint)
            }
            path.addLine(to: innerPoint)
        }
        
        path.close()
        return path
    }
    
    private func createDiamondPath(center: CGPoint, size: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let halfSize = size / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - halfSize))
        path.addLine(to: CGPoint(x: center.x + halfSize, y: center.y))
        path.addLine(to: CGPoint(x: center.x, y: center.y + halfSize))
        path.addLine(to: CGPoint(x: center.x - halfSize, y: center.y))
        path.close()
        
        return path
    }
    
    private func createTrianglePath(center: CGPoint, size: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let height = size * 0.866 // Высота равностороннего треугольника
        let halfBase = size / 2
        
        path.move(to: CGPoint(x: center.x, y: center.y - height/2))
        path.addLine(to: CGPoint(x: center.x + halfBase, y: center.y + height/2))
        path.addLine(to: CGPoint(x: center.x - halfBase, y: center.y + height/2))
        path.close()
        
        return path
    }
    
    private func createFlowerPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let petals = 6
        let petalRadius = radius * 0.6
        let angleIncrement = .pi * 2 / CGFloat(petals)
        
        // Создаем цветок из круглых лепестков
        for i in 0..<petals {
            let angle = CGFloat(i) * angleIncrement
            let petalCenter = CGPoint(
                x: center.x + cos(angle) * radius * 0.5,
                y: center.y + sin(angle) * radius * 0.5
            )
            
            let petalPath = UIBezierPath(arcCenter: petalCenter, radius: petalRadius, 
                                       startAngle: 0, endAngle: .pi * 2, clockwise: true)
            path.append(petalPath)
        }
        
        // Добавляем центральный круг
        let centerCircle = UIBezierPath(arcCenter: center, radius: radius * 0.3, 
                                      startAngle: 0, endAngle: .pi * 2, clockwise: true)
        path.append(centerCircle)
        
        return path
    }
    
    private func createHexagonPath(center: CGPoint, radius: CGFloat) -> UIBezierPath {
        let path = UIBezierPath()
        let sides = 6
        let angleIncrement = .pi * 2 / CGFloat(sides)
        
        for i in 0..<sides {
            let angle = CGFloat(i) * angleIncrement - .pi / 2
            let point = CGPoint(
                x: center.x + cos(angle) * radius,
                y: center.y + sin(angle) * radius
            )
            
            if i == 0 {
                path.move(to: point)
            } else {
                path.addLine(to: point)
            }
        }
        
        path.close()
        return path
    }
} 