//
//  ArchTextView.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import CoreText

class ArchTextView: UIView {
    
    // MARK: - Properties
    
    var text: String = "Текст" {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var font: UIFont = UIFont.systemFont(ofSize: 24) {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var textColor: UIColor = .black {
        didSet {
            setNeedsDisplay()
        }
    }
    
    var archIntensity: CGFloat = 0 {
        didSet {
            setNeedsDisplay()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Drawing
    
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        if archIntensity == 0 {
            // Обычный текст без изгиба
            drawStraightText(in: context, rect: rect)
        } else {
            // Текст по арке
            drawArchedText(in: context, rect: rect)
        }
    }
    
    private func drawStraightText(in context: CGContext, rect: CGRect) {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSAttributedString(string: text, attributes: attributes)
        let textSize = attributedString.size()
        
        let drawRect = CGRect(
            x: (rect.width - textSize.width) / 2,
            y: (rect.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        attributedString.draw(in: drawRect)
    }
    
    private func drawArchedText(in context: CGContext, rect: CGRect) {
        let centerX = rect.width / 2
        let centerY = rect.height / 2
        
        // Радиус арки зависит от интенсивности
        let baseRadius = max(rect.width, rect.height) * 0.8
        let radius = baseRadius / (1 + abs(archIntensity) * 2)
        
        // Определяем, арка вверх или вниз
        let isUpward = archIntensity > 0
        let arcCenterY = isUpward ? centerY + radius : centerY - radius
        
        // Создаем путь арки
        let path = CGMutablePath()
        let startAngle = isUpward ? CGFloat.pi : 0
        let endAngle = isUpward ? 0 : CGFloat.pi
        
        path.addArc(center: CGPoint(x: centerX, y: arcCenterY),
                   radius: radius,
                   startAngle: startAngle,
                   endAngle: endAngle,
                   clockwise: !isUpward)
        
        // Создаем attributed string
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]
        
        let attributedString = NSMutableAttributedString(string: text, attributes: attributes)
        
        // Создаем framesetter
        let framesetter = CTFramesetterCreateWithAttributedString(attributedString)
        
        // Создаем frame для текста по пути
        let frame = CTFramesetterCreateFrame(framesetter, CFRangeMake(0, 0), path, nil)
        
        // Рисуем текст
        context.saveGState()
        context.textMatrix = .identity
        context.translateBy(x: 0, y: rect.height)
        context.scaleBy(x: 1, y: -1)
        
        CTFrameDraw(frame, context)
        
        context.restoreGState()
    }
    
    // MARK: - Public Methods
    
    func updateText(_ newText: String) {
        text = newText
    }
    
    func updateFont(_ newFont: UIFont) {
        font = newFont
    }
    
    func updateTextColor(_ color: UIColor) {
        textColor = color
    }
    
    func updateArchIntensity(_ intensity: CGFloat) {
        archIntensity = intensity
    }
} 