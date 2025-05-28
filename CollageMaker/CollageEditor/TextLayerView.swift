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
        button.tintColor = .red
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
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
            make.top.trailing.equalToSuperview().inset(-8)
            make.size.equalTo(24)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        // Перемещение
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // Масштабирование
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        // Вращение
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        addGestureRecognizer(rotationGesture)
        
        // Нажатие для выбора
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = superview else { return }
        
        let translation = gesture.translation(in: containerView)
        let newCenter = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
        
        // Ограничиваем движение в пределах контейнера (collageView)
        let constrainedCenter = constrainTextLayerCenter(newCenter, containerView: containerView)
        center = constrainedCenter
        
        gesture.setTranslation(.zero, in: containerView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let containerView = superview else { return }
        
        let newTransform = transform.scaledBy(x: gesture.scale, y: gesture.scale)
        
        // Ограничиваем масштаб
        let minScale: CGFloat = 0.5
        let maxScale: CGFloat = 2.0
        let currentScale = sqrt(newTransform.a * newTransform.a + newTransform.c * newTransform.c)
        
        if currentScale >= minScale && currentScale <= maxScale {
            transform = newTransform
            
            // После изменения масштаба корректируем позицию
            let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
            center = constrainedCenter
        }
        
        gesture.scale = 1.0
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let containerView = superview else { return }
        
        transform = transform.rotated(by: gesture.rotation)
        
        // После поворота корректируем позицию
        let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
        center = constrainedCenter
        
        gesture.rotation = 0.0
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        onTap?()
        setSelected(true)
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
    // MARK: - Public Methods
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
    }
    
    private func updateSelectionState() {
        if isSelected {
            layer.borderColor = UIColor.systemBlue.cgColor
            layer.borderWidth = 2
            deleteButton.isHidden = false
        } else {
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
            deleteButton.isHidden = true
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
        let layerFrame = frame
        let containerBounds = containerView.bounds
        
        // Добавляем небольшой отступ от краев
        let margin: CGFloat = 10
        
        // Вычисляем минимальные и максимальные позиции центра
        let minX = layerFrame.width / 2 + margin
        let maxX = containerBounds.width - layerFrame.width / 2 - margin
        let minY = layerFrame.height / 2 + margin
        let maxY = containerBounds.height - layerFrame.height / 2 - margin
        
        // Ограничиваем позицию центра
        let constrainedX = max(minX, min(maxX, center.x))
        let constrainedY = max(minY, min(maxY, center.y))
        
        return CGPoint(x: constrainedX, y: constrainedY)
    }
} 