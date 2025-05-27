//
//  CropOverlayView.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 04.02.2025.
//

import UIKit

/// CropOverlayView затемняет области вне cropRect, рисуя четыре прямоугольника.
/// Внутри cropRect область остается прозрачной, а вокруг него отрисовывается белая рамка.
class CropOverlayView: UIView {
    var cropRect: CGRect = .zero {
        didSet { setNeedsDisplay() }
    }
    
    override func draw(_ rect: CGRect) {
        // Рисуем затемнение только вне cropRect.
        let overlayColor = UIColor.black.withAlphaComponent(0.8)
        overlayColor.setFill()
        
        // Верхняя область.
        let topRect = CGRect(x: 0, y: 0, width: rect.width, height: cropRect.minY)
        UIRectFill(topRect)
        
        // Нижняя область.
        let bottomRect = CGRect(x: 0, y: cropRect.maxY, width: rect.width, height: rect.height - cropRect.maxY)
        UIRectFill(bottomRect)
        
        // Левая область.
        let leftRect = CGRect(x: 0, y: cropRect.minY, width: cropRect.minX, height: cropRect.height)
        UIRectFill(leftRect)
        
        // Правая область.
        let rightRect = CGRect(x: cropRect.maxX, y: cropRect.minY, width: rect.width - cropRect.maxX, height: cropRect.height)
        UIRectFill(rightRect)
        
        // Отрисовываем белую рамку вокруг cropRect.
        let borderPath = UIBezierPath(rect: cropRect)
        UIColor.white.setStroke()
        borderPath.lineWidth = 1.0
        borderPath.stroke()
    }
    
        override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
            let threshold: CGFloat = 20.0
            // Если касание происходит в центральной области (не в зоне изменения размера),
            // возвращаем nil, чтобы жест не перехватывался CropGridView и дошёл до imageView.
            if point.x > threshold && point.x < (bounds.width - threshold) &&
               point.y > threshold && point.y < (bounds.height - threshold) {
                return nil
            }
            return super.hitTest(point, with: event)
        }
}
