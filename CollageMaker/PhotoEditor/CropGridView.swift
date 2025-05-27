//
//  CropGridView.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 03.02.2025.
//

import Foundation
import UIKit

/// CropGridView отрисовывает сетку, разделяющую область на 9 равных квадратов.
/// Между линиями рисуются небольшие крестики в местах пересечения (горизонтальные линии длиной 16 пикселей, вертикальные – аналогично).
/// Дополнительно в 4 углах области рисуются крестики, где каждая "рука" крестика имеет длину 16 пикселей.
class CropGridView: UIView {
    override func draw(_ rect: CGRect) {
        guard let context = UIGraphicsGetCurrentContext() else { return }
        
        // Настраиваем стиль для обычных линий сетки.
        context.setStrokeColor(UIColor.white.withAlphaComponent(0.5).cgColor)
        context.setLineWidth(1.0)
        
        let width = rect.width
        let height = rect.height
        
        // Вычисляем размеры для 3 колонок и 3 рядов.
        let colWidth = width / 3.0
        let rowHeight = height / 3.0
        
        // Рисуем вертикальные линии.
        context.move(to: CGPoint(x: colWidth, y: 0))
        context.addLine(to: CGPoint(x: colWidth, y: height))
        context.move(to: CGPoint(x: 2 * colWidth, y: 0))
        context.addLine(to: CGPoint(x: 2 * colWidth, y: height))
        
        // Рисуем горизонтальные линии.
        context.move(to: CGPoint(x: 0, y: rowHeight))
        context.addLine(to: CGPoint(x: width, y: rowHeight))
        context.move(to: CGPoint(x: 0, y: 2 * rowHeight))
        context.addLine(to: CGPoint(x: width, y: 2 * rowHeight))
        
        context.strokePath()
        
        // Рисуем крестики в местах пересечения линий.
        let intersections: [CGPoint] = [
            CGPoint(x: colWidth, y: rowHeight),
            CGPoint(x: colWidth, y: 2 * rowHeight),
            CGPoint(x: 2 * colWidth, y: rowHeight),
            CGPoint(x: 2 * colWidth, y: 2 * rowHeight)
        ]
        
        // Параметры для крестика: толщина линии – 2 пикселя, длина "руки" – 8 пикселей (итого 16 по ширине).
        let crossLineThickness: CGFloat = 2.0
        let crossHalfLength: CGFloat = 8.0
        
        context.setFillColor(UIColor.white.cgColor)
        
        for point in intersections {
            // Рисуем горизонтальную линию крестика.
            let horizontalRect = CGRect(x: point.x - crossHalfLength,
                                        y: point.y - crossLineThickness / 2,
                                        width: crossHalfLength * 2,
                                        height: crossLineThickness)
            context.fill(horizontalRect)
            
            // Рисуем вертикальную линию крестика.
            let verticalRect = CGRect(x: point.x - crossLineThickness / 2,
                                      y: point.y - crossHalfLength,
                                      width: crossLineThickness,
                                      height: crossHalfLength * 2)
            context.fill(verticalRect)
        }
        
        // Теперь рисуем крестики в углах области.
        // Определяем 4 угловых точки: верхний левый, верхний правый, нижний левый, нижний правый.
        let corners: [CGPoint] = [
            CGPoint(x: 0, y: 0),
            CGPoint(x: width, y: 0),
            CGPoint(x: 0, y: height),
            CGPoint(x: width, y: height)
        ]
        
        // Для угловых крестиков используем ту же толщину (2 пикселя) и длину "рук" – 16 пикселей в каждую сторону.
        let cornerArmLength: CGFloat = 16.0
        
        for corner in corners {
            // Рисуем горизонтальную линию в угле.
            let horizontalRect = CGRect(x: corner.x - cornerArmLength,
                                        y: corner.y - crossLineThickness / 2,
                                        width: cornerArmLength * 2,
                                        height: crossLineThickness)
            context.fill(horizontalRect)
            
            // Рисуем вертикальную линию в угле.
            let verticalRect = CGRect(x: corner.x - crossLineThickness / 2,
                                      y: corner.y - cornerArmLength,
                                      width: crossLineThickness,
                                      height: cornerArmLength * 2)
            context.fill(verticalRect)
        }
    }
    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
          // Если в событии более одного касания – не перехватываем событие.
          if let event = event, let touches = event.allTouches, touches.count > 1 {
              return false
          }
          return super.point(inside: point, with: event)
      }
}
