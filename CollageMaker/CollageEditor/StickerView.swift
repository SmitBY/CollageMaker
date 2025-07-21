import UIKit
import SnapKit

class StickerView: UIView {
    
    // MARK: - Properties
    private let imageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
    private let scaleButton = UIButton(type: .system)
    private let rotationButton = UIButton(type: .system)
    private var isSelected = false
    
    // Callbacks
    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?
    
    // Gesture recognizers
    private var panGesture: UIPanGestureRecognizer!
    private var pinchGesture: UIPinchGestureRecognizer!
    private var rotationGesture: UIRotationGestureRecognizer!
    
    // MARK: - Initializer
    init(image: UIImage) {
        super.init(frame: CGRect(x: 0, y: 0, width: 80, height: 80))
        setupView(with: image)
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupView(with image: UIImage) {
        // Настройка imageView
        imageView.image = image
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        
        // Настройка deleteButton (правый верхний угол)
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12
        deleteButton.isHidden = true
        
        // Настройка scaleButton (левый нижний угол)
        scaleButton.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
        scaleButton.tintColor = .systemGreen
        scaleButton.backgroundColor = .white
        scaleButton.layer.cornerRadius = 12
        scaleButton.isHidden = true
        
        // Настройка rotationButton (правый нижний угол)
        rotationButton.setImage(UIImage(systemName: "arrow.clockwise.circle"), for: .normal)
        rotationButton.tintColor = .systemBlue
        rotationButton.backgroundColor = .white
        rotationButton.layer.cornerRadius = 12
        rotationButton.isHidden = true
        
        // Добавляем subviews
        addSubview(imageView)
        addSubview(deleteButton)
        addSubview(scaleButton)
        addSubview(rotationButton)
        
        // Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(-5)
            make.width.height.equalTo(24)
        }
        
        scaleButton.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview().inset(-5)
            make.width.height.equalTo(24)
        }
        
        rotationButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(-5)
            make.width.height.equalTo(24)
        }
        
        // Настройка view
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        
        // Добавляем обработчики для кнопок
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Добавляем жесты для кнопок управления
        setupControlButtonGestures()
        
        // Добавляем tap gesture
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(viewTapped))
        addGestureRecognizer(tapGesture)
    }
    
    private func setupGestures() {
        // Pan gesture для перемещения
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        addGestureRecognizer(panGesture)
        
        // Pinch gesture для масштабирования
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        addGestureRecognizer(pinchGesture)
        
        // Rotation gesture для поворота
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        addGestureRecognizer(rotationGesture)
        
        // Настройка одновременного распознавания жестов
        panGesture.delegate = self
        pinchGesture.delegate = self
        rotationGesture.delegate = self
    }
    
    private func setupControlButtonGestures() {
        // Pan gesture для кнопки масштабирования
        let scalePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleScaleButtonPan(_:)))
        scaleButton.addGestureRecognizer(scalePanGesture)
        
        // Pan gesture для кнопки вращения
        let rotationPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotationButtonPan(_:)))
        rotationButton.addGestureRecognizer(rotationPanGesture)
    }
    
    // MARK: - Actions
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
    @objc private func viewTapped() {
        onTap?()
    }
    
    // MARK: - Gesture Handlers
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let superview = superview else { return }
        
        let translation = gesture.translation(in: superview)
        
        switch gesture.state {
        case .changed:
            center = CGPoint(x: center.x + translation.x, y: center.y + translation.y)
            gesture.setTranslation(.zero, in: superview)
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        switch gesture.state {
        case .changed:
            let scale = gesture.scale
            transform = transform.scaledBy(x: scale, y: scale)
            gesture.scale = 1.0
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        switch gesture.state {
        case .changed:
            transform = transform.rotated(by: gesture.rotation)
            gesture.rotation = 0
        default:
            break
        }
    }
    
    // MARK: - Control Button Gesture Handlers
    @objc private func handleScaleButtonPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Анимация кнопки
            UIView.animate(withDuration: 0.1) {
                self.scaleButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            
        case .changed:
            // Вычисляем изменение масштаба на основе вертикального движения
            let scaleFactor = 1.0 + (translation.y * -0.01) // Отрицательное для интуитивного управления
            let clampedScale = max(0.1, min(3.0, scaleFactor))
            
            // Применяем масштабирование
            transform = transform.scaledBy(x: clampedScale, y: clampedScale)
            
            // Сбрасываем translation
            gesture.setTranslation(.zero, in: self)
            
            // Обновляем иконку в зависимости от направления
            let iconName = translation.y < 0 ? "plus.magnifyingglass" : "minus.magnifyingglass"
            scaleButton.setImage(UIImage(systemName: iconName), for: .normal)
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному состоянию
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.scaleButton.transform = .identity
                self.scaleButton.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
            }
            
        default:
            break
        }
    }
    
    @objc private func handleRotationButtonPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        switch gesture.state {
        case .began:
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Анимация кнопки
            UIView.animate(withDuration: 0.1) {
                self.rotationButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            
        case .changed:
            // Вычисляем угол относительно центра элемента
            let deltaX = location.x - center.x
            let deltaY = location.y - center.y
            let angle = atan2(deltaY, deltaX)
            
            // Применяем небольшое вращение
            let rotationIncrement = angle * 0.05 // Чувствительность вращения
            transform = transform.rotated(by: rotationIncrement)
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному состоянию
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.rotationButton.transform = .identity
            }
            
        default:
            break
        }
    }
    
    // MARK: - Selection
    func setSelected(_ selected: Bool) {
        isSelected = selected
        deleteButton.isHidden = !selected
        scaleButton.isHidden = !selected
        rotationButton.isHidden = !selected
        
        if selected {
            layer.borderWidth = 2
            layer.borderColor = UIColor.systemBlue.cgColor
            
            // Анимация появления кнопок
            if !deleteButton.isHidden {
                animateButtonsAppearance()
            }
        } else {
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    private func animateButtonsAppearance() {
        let buttons = [deleteButton, scaleButton, rotationButton]
        
        buttons.forEach { button in
            button.alpha = 0
            button.transform = CGAffineTransform(scaleX: 0.1, y: 0.1)
        }
        
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            buttons.forEach { button in
                button.alpha = 1.0
                button.transform = .identity
            }
        }
    }
    
    // MARK: - External Transform Controls
    func applyScale(_ scale: CGFloat) {
        transform = transform.scaledBy(x: scale, y: scale)
    }
    
    func applyRotation(_ rotation: CGFloat) {
        transform = transform.rotated(by: rotation)
    }
    
    func resetTransform() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
            self.transform = .identity
        }
    }
    
    func getIsSelected() -> Bool {
        return isSelected
    }
}

// MARK: - UIGestureRecognizerDelegate
extension StickerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Позволяем одновременное распознавание жестов масштабирования и поворота
        return (gestureRecognizer == pinchGesture && otherGestureRecognizer == rotationGesture) ||
               (gestureRecognizer == rotationGesture && otherGestureRecognizer == pinchGesture)
    }
}
