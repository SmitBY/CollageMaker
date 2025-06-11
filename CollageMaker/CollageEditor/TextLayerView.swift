//
//  TextLayerView.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import SnapKit

class TextLayerView: UIView {
    
    // MARK: - Properties
    
    let archTextView: ArchTextView = {
        let view = ArchTextView()
        view.text = "Введите текст"
        view.font = UIFont.systemFont(ofSize: 24)
        view.textColor = .black
        view.isUserInteractionEnabled = true
        return view
    }()
    
    // Для совместимости с существующим кодом
    var textLabel: UILabel {
        let label = UILabel()
        label.text = archTextView.text
        label.font = archTextView.font
        label.textColor = archTextView.textColor
        return label
    }
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .systemRed
        button.backgroundColor = .white
        button.layer.cornerRadius = 15
        button.layer.borderWidth = 2
        button.layer.borderColor = UIColor.systemRed.cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
        button.isHidden = true
        return button
    }()
    
    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?
    
    private var isSelected = false {
        didSet {
            updateSelectionState()
        }
    }
    
    // Состояние для жестов
    private var initialTransform: CGAffineTransform = .identity
    private var initialCenter: CGPoint = .zero
    
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
        
        addSubview(archTextView)
        addSubview(deleteButton)
        
        archTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().offset(8)
            make.size.equalTo(30)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        // Перемещение
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        addGestureRecognizer(panGesture)
        
        // Масштабирование
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        addGestureRecognizer(pinchGesture)
        
        // Вращение
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        addGestureRecognizer(rotationGesture)
        
        // Нажатие для выбора
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Делаем элемент интерактивным
        isUserInteractionEnabled = true
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            initialCenter = center
            setSelected(true)
        case .changed:
            let translation = gesture.translation(in: containerView)
            let newCenter = CGPoint(x: initialCenter.x + translation.x, y: initialCenter.y + translation.y)
            
            // Ограничиваем движение в пределах контейнера
            let constrainedCenter = constrainTextLayerCenter(newCenter, containerView: containerView)
            center = constrainedCenter
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            initialTransform = transform
            setSelected(true)
        case .changed:
            let scale = gesture.scale
            let newTransform = initialTransform.scaledBy(x: scale, y: scale)
            
            // Ограничиваем масштаб
            let minScale: CGFloat = 0.3
            let maxScale: CGFloat = 3.0
            let currentScale = sqrt(newTransform.a * newTransform.a + newTransform.c * newTransform.c)
            
            if currentScale >= minScale && currentScale <= maxScale {
                transform = newTransform
                
                // После изменения масштаба корректируем позицию
                let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
                center = constrainedCenter
            }
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            initialTransform = transform
            setSelected(true)
        case .changed:
            let rotation = gesture.rotation
            let newTransform = initialTransform.rotated(by: rotation)
            transform = newTransform
            
            // После поворота корректируем позицию
            let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
            center = constrainedCenter
        case .ended, .cancelled:
            break
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        onTap?()
        setSelected(true)
    }
    
    @objc private func deleteButtonTapped() {
        // Анимация удаления
        UIView.animate(withDuration: 0.3, animations: {
            self.transform = self.transform.scaledBy(x: 0.1, y: 0.1)
            self.alpha = 0
        }) { _ in
            self.onDelete?()
        }
    }
    
    // MARK: - Public Methods
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
    }
    
    private func updateSelectionState() {
        UIView.animate(withDuration: 0.2) {
            if self.isSelected {
                self.layer.borderColor = UIColor.systemBlue.cgColor
                self.layer.borderWidth = 2
                self.layer.cornerRadius = 8
                self.deleteButton.isHidden = false
                
                // Добавляем тень для выделения
                self.layer.shadowColor = UIColor.systemBlue.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 2)
                self.layer.shadowOpacity = 0.3
                self.layer.shadowRadius = 4
            } else {
                self.layer.borderColor = UIColor.clear.cgColor
                self.layer.borderWidth = 0
                self.layer.cornerRadius = 0
                self.deleteButton.isHidden = true
                
                // Убираем тень
                self.layer.shadowOpacity = 0
            }
        }
    }
    
    func updateText(_ text: String) {
        archTextView.updateText(text)
    }
    
    func updateTextColor(_ color: UIColor) {
        archTextView.updateTextColor(color)
    }
    
    func updateFont(_ font: UIFont) {
        archTextView.updateFont(font)
    }
    
    func updateFontByName(_ fontName: String) {
        let currentSize = archTextView.font.pointSize
        if let newFont = UIFont(name: fontName, size: currentSize) {
            archTextView.updateFont(newFont)
        }
    }
    
    func applyArchEffect(intensity: CGFloat) {
        archTextView.updateArchIntensity(intensity)
    }
    
    // MARK: - Helper Methods
    
    private func constrainTextLayerCenter(_ center: CGPoint, containerView: UIView) -> CGPoint {
        // Получаем размеры текстового слоя с учетом трансформации
        let transformedBounds = bounds.applying(transform)
        let containerBounds = containerView.bounds
        
        // Добавляем отступ от краев
        let margin: CGFloat = 20
        
        // Учитываем размеры с трансформацией
        let halfWidth = abs(transformedBounds.width) / 2
        let halfHeight = abs(transformedBounds.height) / 2
        
        // Вычисляем ограничения
        let minX = halfWidth + margin
        let maxX = containerBounds.width - halfWidth - margin
        let minY = halfHeight + margin
        let maxY = containerBounds.height - halfHeight - margin
        
        // Ограничиваем позицию центра
        let constrainedX = max(minX, min(maxX, center.x))
        let constrainedY = max(minY, min(maxY, center.y))
        
        return CGPoint(x: constrainedX, y: constrainedY)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension TextLayerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Разрешаем одновременное выполнение pinch и rotation
        if (gestureRecognizer is UIPinchGestureRecognizer && otherGestureRecognizer is UIRotationGestureRecognizer) ||
           (gestureRecognizer is UIRotationGestureRecognizer && otherGestureRecognizer is UIPinchGestureRecognizer) {
            return true
        }
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Если нажали на кнопку удаления, не обрабатываем другие жесты
        if touch.view == deleteButton {
            return false
        }
        return true
    }
} 