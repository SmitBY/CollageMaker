//
//  BorderDragView.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import SnapKit

protocol BorderDragViewDelegate: AnyObject {
    func borderDragView(_ view: BorderDragView, didChangeRatio ratio: CGFloat)
}

class BorderDragView: UIView {
    
    // MARK: - Properties
    
    weak var delegate: BorderDragViewDelegate?
    
    private let dragHandle: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue.withAlphaComponent(0.8)
        view.layer.cornerRadius = 3
        return view
    }()
    
    private let hitArea: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var ratio: CGFloat = 0.5 {
        didSet {
            delegate?.borderDragView(self, didChangeRatio: ratio)
        }
    }
    
    var isVertical: Bool = false {
        didSet {
            setupConstraints()
            updateAppearance()
        }
    }
    
    private var initialTouchPoint: CGPoint = .zero
    private var initialRatio: CGFloat = 0.5
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = .clear
        
        addSubview(hitArea)
        addSubview(dragHandle)
        
        setupConstraints()
        updateAppearance()
    }
    
    private func setupConstraints() {
        hitArea.snp.remakeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        if isVertical {
            // Вертикальная граница (для изменения горизонтального размера)
            dragHandle.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(6)
                make.height.equalTo(40)
            }
        } else {
            // Горизонтальная граница (для изменения вертикального размера)
            dragHandle.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(40)
                make.height.equalTo(6)
            }
        }
    }
    
    private func updateAppearance() {
        if isVertical {
            dragHandle.layer.cornerRadius = 3
        } else {
            dragHandle.layer.cornerRadius = 3
        }
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        hitArea.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        hitArea.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        switch gesture.state {
        case .began:
            initialTouchPoint = gesture.location(in: superview)
            initialRatio = ratio
            highlightBorder(true)
            
        case .changed:
            let currentPoint = gesture.location(in: superview)
            let delta: CGFloat
            
            if isVertical {
                // Вертикальная граница - изменяем по X
                delta = currentPoint.x - initialTouchPoint.x
                // Используем размер родительского контейнера для более точного расчета
                guard let superviewBounds = superview?.bounds else { return }
                let maxDelta = superviewBounds.width * 0.4 // Максимальное смещение
                let normalizedDelta = delta / maxDelta
                ratio = max(0.1, min(0.9, initialRatio + normalizedDelta))
            } else {
                // Горизонтальная граница - изменяем по Y
                delta = currentPoint.y - initialTouchPoint.y
                // Используем размер родительского контейнера для более точного расчета
                guard let superviewBounds = superview?.bounds else { return }
                let maxDelta = superviewBounds.height * 0.4 // Максимальное смещение
                let normalizedDelta = delta / maxDelta
                ratio = max(0.1, min(0.9, initialRatio + normalizedDelta))
            }
            
        case .ended, .cancelled:
            highlightBorder(false)
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        // Сброс к центральному положению
        ratio = 0.5
        
        // Анимация подсветки
        highlightBorder(true)
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.2) {
            self.highlightBorder(false)
        }
    }
    
    // MARK: - Visual Feedback
    
    private func highlightBorder(_ highlight: Bool) {
        UIView.animate(withDuration: 0.2) {
            if highlight {
                self.dragHandle.backgroundColor = .systemBlue
                self.dragHandle.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            } else {
                self.dragHandle.backgroundColor = .systemBlue.withAlphaComponent(0.8)
                self.dragHandle.transform = .identity
            }
        }
    }
    
    // MARK: - Touch Handling
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Расширяем область касания для лучшего UX
        let expandedBounds = bounds.insetBy(dx: -10, dy: -10)
        if expandedBounds.contains(point) {
            return hitArea
        }
        return super.hitTest(point, with: event)
    }
} 