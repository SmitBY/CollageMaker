import UIKit
import SnapKit

protocol AdvancedImageGestureHandlerDelegate: AnyObject {
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateTransform transform: CGAffineTransform, for imageView: UIImageView)
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateFrame frame: CGRect, for imageView: UIImageView)
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didTapImageView imageView: UIImageView)
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didDeleteImageView imageView: UIImageView)
}

class AdvancedImageGestureHandler: NSObject {
    weak var delegate: AdvancedImageGestureHandlerDelegate?
    private weak var imageView: UIImageView?
    private weak var containerView: UIView?
    
    // Состояние трансформации
    private var initialTransform: CGAffineTransform = .identity
    private var currentTransform: CGAffineTransform = .identity
    
    // Состояние рамки
    private var initialFrame: CGRect = .zero
    private var currentFrame: CGRect = .zero
    
    // Элементы управления
    private var deleteButton: UIButton?
    
    // Жесты
    private var panGesture: UIPanGestureRecognizer?
    private var pinchGesture: UIPinchGestureRecognizer?
    private var rotationGesture: UIRotationGestureRecognizer?
    
    // Состояние редактирования
    private var isSelected: Bool = false
    private var editingMode: EditingMode = .none
    
    enum EditingMode: Equatable {
        case none
        case moving
        case transforming
    }
    
    init(imageView: UIImageView, containerView: UIView) {
        super.init()
        self.imageView = imageView
        self.containerView = containerView
        setupGestures()
    }
    
    private func setupGestures() {
        guard let imageView = imageView else { return }
        
        // Основные жесты для трансформации
        pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        
        // Разрешаем одновременное выполнение жестов
        pinchGesture?.delegate = self
        rotationGesture?.delegate = self
        panGesture?.delegate = self
        
        if let pinch = pinchGesture { imageView.addGestureRecognizer(pinch) }
        if let rotation = rotationGesture { imageView.addGestureRecognizer(rotation) }
        if let pan = panGesture { imageView.addGestureRecognizer(pan) }
        
        // Тап для выделения
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        imageView.addGestureRecognizer(tapGesture)
        
        imageView.isUserInteractionEnabled = true
    }
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
        if selected {
            showDeleteButton()
        } else {
            hideDeleteButton()
        }
    }
    
    func updateDeleteButtonVisibility() {
        guard let imageView = imageView else { return }
        
        // Показываем кнопку удаления только если есть реальное изображение (не placeholder)
        if let image = imageView.image, image != UIImage(named: "placeholder") {
            showDeleteButton()
        } else {
            hideDeleteButton()
        }
    }
    
    private func showDeleteButton() {
        guard let imageView = imageView, 
              let tileView = imageView.superview else { return }
        
        hideDeleteButton()
        
        // Создаем кнопку удаления на рамке
        deleteButton = UIButton(type: .system)
        deleteButton?.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton?.tintColor = .red
        deleteButton?.backgroundColor = .white
        deleteButton?.layer.cornerRadius = 12
        deleteButton?.layer.borderColor = UIColor.white.cgColor
        deleteButton?.layer.borderWidth = 2
        deleteButton?.isUserInteractionEnabled = true
        
        // Добавляем тень для лучшей видимости
        deleteButton?.layer.shadowColor = UIColor.black.cgColor
        deleteButton?.layer.shadowOffset = CGSize(width: 0, height: 2)
        deleteButton?.layer.shadowOpacity = 0.3
        deleteButton?.layer.shadowRadius = 2
        
        // Добавляем кнопку к рамке (tileView)
        tileView.addSubview(deleteButton!)
        
        // Используем SnapKit для надежного позиционирования
        deleteButton?.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.trailing.equalToSuperview().offset(-6)
            make.width.height.equalTo(24)
        }
        
        // Добавляем обработчик нажатия
        deleteButton?.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
        // Убеждаемся, что кнопка поверх всего
        tileView.bringSubviewToFront(deleteButton!)
    }
    
    private func hideDeleteButton() {
        deleteButton?.removeFromSuperview()
        deleteButton = nil
    }
    

    

    

    

    
    // MARK: - Gesture Handlers
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        guard let imageView = imageView else { return }
        delegate?.gestureHandler(self, didTapImageView: imageView)
    }
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = imageView, editingMode == .none || editingMode == .moving else { return }
        
        let translation = gesture.translation(in: imageView.superview)
        
        switch gesture.state {
        case .began:
            editingMode = .moving
            initialFrame = imageView.frame
        case .changed:
            let newCenter = CGPoint(
                x: initialFrame.midX + translation.x,
                y: initialFrame.midY + translation.y
            )
            
            // Проверяем границы перед применением
            if let containerBounds = imageView.superview?.bounds {
                let constrainedCenter = constrainPoint(newCenter, in: containerBounds)
                imageView.center = constrainedCenter
            } else {
                imageView.center = newCenter
            }
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        switch gesture.state {
        case .began:
            editingMode = .transforming
            initialTransform = imageView.transform
        case .changed:
            let scale = gesture.scale
            let newTransform = initialTransform.scaledBy(x: scale, y: scale)
            
            // Ограничиваем масштаб
            let currentScale = sqrt(newTransform.a * newTransform.a + newTransform.c * newTransform.c)
            let minScale: CGFloat = 0.1
            let maxScale: CGFloat = 5.0
            
            if currentScale >= minScale && currentScale <= maxScale {
                imageView.transform = newTransform

            }
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateTransform: imageView.transform, for: imageView)
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        switch gesture.state {
        case .began:
            editingMode = .transforming
            initialTransform = imageView.transform
        case .changed:
            let rotation = gesture.rotation
            let newTransform = initialTransform.rotated(by: rotation)
            imageView.transform = newTransform
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateTransform: imageView.transform, for: imageView)
        default:
            break
        }
    }
    

    
    // MARK: - Helper Methods
    
    private func constrainPoint(_ point: CGPoint, in bounds: CGRect) -> CGPoint {
        guard !bounds.isEmpty else { return point }
        
        let margin: CGFloat = 50
        return CGPoint(
            x: max(bounds.minX + margin, min(bounds.maxX - margin, point.x)),
            y: max(bounds.minY + margin, min(bounds.maxY - margin, point.y))
        )
    }
    
    // MARK: - Public Methods
    
    /// Сбрасывает трансформацию изображения если оно вышло за границы
    func resetTransformIfNeeded() {
        guard let imageView = imageView, let containerView = containerView else { return }
        
        let imageFrame = imageView.frame
        let containerBounds = containerView.bounds.insetBy(dx: 20, dy: 20)
        
        // Проверяем, не вышло ли изображение полностью за границы
        if !imageFrame.intersects(containerBounds) {
            print("Изображение вышло за границы, сбрасываем трансформацию")
            
            // Сбрасываем трансформацию
            imageView.transform = .identity
            
            // Возвращаем в центр контейнера
            imageView.center = CGPoint(x: containerBounds.midX, y: containerBounds.midY)
            
            // Уведомляем делегата
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        }
    }
    
    @objc private func deleteButtonTapped() {
        guard let imageView = imageView else { return }
        delegate?.gestureHandler(self, didDeleteImageView: imageView)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension AdvancedImageGestureHandler: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Разрешаем одновременное выполнение pinch и rotation
        if (gestureRecognizer == pinchGesture && otherGestureRecognizer == rotationGesture) ||
           (gestureRecognizer == rotationGesture && otherGestureRecognizer == pinchGesture) {
            return true
        }
        return false
    }
} 