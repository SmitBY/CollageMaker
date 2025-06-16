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
        
        // Рисуем только тонкую белую рамку для обозначения области обрезки
        context.setStrokeColor(UIColor.white.cgColor)
        context.setLineWidth(1.0)
        context.stroke(rect)
        
        // Убираем сетку и маркеры - они теперь отдельные views
    }
    

    
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
          // Если в событии более одного касания – не перехватываем событие.
          if let event = event, let touches = event.allTouches, touches.count > 1 {
              return false
          }
          return super.point(inside: point, with: event)
      }
}
