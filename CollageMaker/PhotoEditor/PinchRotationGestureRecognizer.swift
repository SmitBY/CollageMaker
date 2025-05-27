//
//  PinchRotationGestureRecognizer.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 04.02.2025.
//

import UIKit.UIGestureRecognizerSubclass

class PinchRotationGestureRecognizer: UIGestureRecognizer {
    var scale: CGFloat = 1.0
    var rotation: CGFloat = 0.0
    
    private var initialDistance: CGFloat = 0.0
    private var initialAngle: CGFloat = 0.0
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent) {
        if touches.count != 2 {
            state = .failed
            return
        }
        let touchesArray = Array(touches)
        guard let view = self.view else { return }
        let point1 = touchesArray[0].location(in: view)
        let point2 = touchesArray[1].location(in: view)
        initialDistance = distanceBetween(point1, and: point2)
        initialAngle = angleBetween(point1, and: point2)
        scale = 1.0
        rotation = 0.0
        state = .began
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent) {
        guard let view = self.view, numberOfTouches >= 2 else {
            state = .failed
            return
        }
        let point1 = self.location(ofTouch: 0, in: view)
        let point2 = self.location(ofTouch: 1, in: view)
        let currentDistance = distanceBetween(point1, and: point2)
        let currentAngle = angleBetween(point1, and: point2)
        scale = currentDistance / initialDistance
        rotation = currentAngle - initialAngle
        state = .changed
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent) {
        if state == .changed {
            state = .ended
        } else {
            state = .failed
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent) {
        state = .cancelled
    }
    
    private func distanceBetween(_ p1: CGPoint, and p2: CGPoint) -> CGFloat {
        return hypot(p2.x - p1.x, p2.y - p1.y)
    }
    
    private func angleBetween(_ p1: CGPoint, and p2: CGPoint) -> CGFloat {
        return atan2(p2.y - p1.y, p2.x - p1.x)
    }
}
