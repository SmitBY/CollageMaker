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
        view.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        view.layer.cornerRadius = 3
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 1)
        view.layer.shadowOpacity = 0.3
        view.layer.shadowRadius = 2
        return view
    }()
    
    private let hitArea: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    var ratio: CGFloat = 0.5 {
        didSet {
            // Ограничиваем значение в пределах 0.1-0.9 для стабильности
            ratio = max(0.1, min(0.9, ratio))
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
    private var isDragging: Bool = false
    
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
                make.height.equalTo(50)
            }
        } else {
            // Горизонтальная граница (для изменения вертикального размера)
            dragHandle.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.centerY.equalToSuperview()
                make.width.equalTo(50)
                make.height.equalTo(6)
            }
        }
    }
    
    private func updateAppearance() {
        dragHandle.layer.cornerRadius = 3
        
        // Добавляем визуальную обратную связь для лучшего UX
        if isVertical {
            dragHandle.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        } else {
            dragHandle.backgroundColor = .systemBlue.withAlphaComponent(0.7)
        }
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.minimumNumberOfTouches = 1
        panGesture.maximumNumberOfTouches = 1
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
            isDragging = true
            highlightBorder(true)
            
            // Предотвращаем мерцание во время перетаскивания
            superview?.layer.removeAllAnimations()
            
        case .changed:
            guard isDragging else { return }
            
            let currentPoint = gesture.location(in: superview)
            let delta: CGFloat
            
            if isVertical {
                // Вертикальная граница - изменяем по X
                delta = currentPoint.x - initialTouchPoint.x
                
                // Используем размер родительского контейнера для расчета
                guard superview != nil else { return }
                let sensitivity: CGFloat = 0.003 // Снижаем чувствительность для плавности
                let normalizedDelta = delta * sensitivity
                
                ratio = max(0.1, min(0.9, initialRatio + normalizedDelta))
            } else {
                // Горизонтальная граница - изменяем по Y
                delta = currentPoint.y - initialTouchPoint.y
                
                guard superview != nil else { return }
                let sensitivity: CGFloat = 0.003
                let normalizedDelta = delta * sensitivity
                
                ratio = max(0.1, min(0.9, initialRatio + normalizedDelta))
            }
            
        case .ended, .cancelled:
            isDragging = false
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
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            self.highlightBorder(false)
        }
        
        print("🔧 Сброс соотношения к 50%")
    }
    
    // MARK: - Visual Feedback
    
    private func highlightBorder(_ highlight: Bool) {
        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction], animations: {
            if highlight {
                self.dragHandle.backgroundColor = .systemBlue
                self.dragHandle.transform = CGAffineTransform(scaleX: 1.3, y: 1.3)
                self.dragHandle.layer.shadowOpacity = 0.5
            } else {
                self.dragHandle.backgroundColor = .systemBlue.withAlphaComponent(0.7)
                self.dragHandle.transform = .identity
                self.dragHandle.layer.shadowOpacity = 0.3
            }
        })
    }
    
    // MARK: - Touch Handling
    
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        // Расширяем область касания для лучшего UX
        let expandedBounds = bounds.insetBy(dx: -15, dy: -15)
        if expandedBounds.contains(point) {
            return hitArea
        }
        return super.hitTest(point, with: event)
    }
    
    // MARK: - Lifecycle
    
    override func layoutSubviews() {
        super.layoutSubviews()
        
        // Обновляем внешний вид при изменении размеров
        updateAppearance()
    }
} 