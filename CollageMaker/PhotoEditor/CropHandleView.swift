import UIKit

class CropHandleView: UIView {
    enum HandleType {
        case corner
        case edge
    }
    
    enum Position {
        case topLeft, topRight, bottomLeft, bottomRight
        case top, bottom, left, right
    }
    
    let handleType: HandleType
    let position: Position
    
    init(type: HandleType, position: Position) {
        self.handleType = type
        self.position = position
        super.init(frame: .zero)
        setupView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupView() {
        backgroundColor = .clear
        isUserInteractionEnabled = true
        
        let size: CGFloat = handleType == .corner ? 30 : 25
        frame = CGRect(x: 0, y: 0, width: size, height: size)
    }
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        context.setFillColor(UIColor.white.cgColor)
        context.setStrokeColor(UIColor.blue.cgColor)
        context.setLineWidth(2.0)
        
        let inset: CGFloat = 4.0
        let drawRect = rect.insetBy(dx: inset, dy: inset)
        
        switch handleType {
        case .corner:
            drawCornerHandle(in: drawRect, context: context)
        case .edge:
            drawEdgeHandle(in: drawRect, context: context)
        }
    }
    
    private func drawCornerHandle(in rect: CGRect, context: CGContext) {
        // Рисуем квадратный маркер с синей рамкой
        context.fill(rect)
        context.stroke(rect)
        
        // Добавляем направляющие линии в углу
        let lineLength: CGFloat = 8.0
        let lineWidth: CGFloat = 2.0
        
        context.setLineWidth(lineWidth)
        context.setStrokeColor(UIColor.blue.cgColor)
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        switch position {
        case .topLeft:
            // Линии вправо и вниз
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x + lineLength, y: center.y))
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x, y: center.y + lineLength))
            
        case .topRight:
            // Линии влево и вниз
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x - lineLength, y: center.y))
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x, y: center.y + lineLength))
            
        case .bottomLeft:
            // Линии вправо и вверх
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x + lineLength, y: center.y))
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x, y: center.y - lineLength))
            
        case .bottomRight:
            // Линии влево и вверх
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x - lineLength, y: center.y))
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x, y: center.y - lineLength))
            
        default:
            break
        }
        
        context.strokePath()
    }
    
    private func drawEdgeHandle(in rect: CGRect, context: CGContext) {
        // Рисуем прямоугольный маркер с синей рамкой
        context.fill(rect)
        context.stroke(rect)
        
        // Добавляем стрелочки для указания направления
        let arrowLength: CGFloat = 6.0
        context.setLineWidth(2.0)
        context.setStrokeColor(UIColor.blue.cgColor)
        
        let center = CGPoint(x: rect.midX, y: rect.midY)
        
        switch position {
        case .top, .bottom:
            // Вертикальные стрелки
            let direction: CGFloat = (position == .top) ? -1 : 1
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x, y: center.y + arrowLength * direction))
            context.move(to: CGPoint(x: center.x - 3, y: center.y + (arrowLength - 3) * direction))
            context.addLine(to: CGPoint(x: center.x, y: center.y + arrowLength * direction))
            context.addLine(to: CGPoint(x: center.x + 3, y: center.y + (arrowLength - 3) * direction))
            
        case .left, .right:
            // Горизонтальные стрелки
            let direction: CGFloat = (position == .left) ? -1 : 1
            context.move(to: CGPoint(x: center.x, y: center.y))
            context.addLine(to: CGPoint(x: center.x + arrowLength * direction, y: center.y))
            context.move(to: CGPoint(x: center.x + (arrowLength - 3) * direction, y: center.y - 3))
            context.addLine(to: CGPoint(x: center.x + arrowLength * direction, y: center.y))
            context.addLine(to: CGPoint(x: center.x + (arrowLength - 3) * direction, y: center.y + 3))
            
        default:
            break
        }
        
        context.strokePath()
    }
} 