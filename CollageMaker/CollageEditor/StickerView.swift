import UIKit
import SnapKit

class StickerView: UIView {
    
    // MARK: - Properties
    private let imageView = UIImageView()
    private let deleteButton = UIButton(type: .system)
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
        
        // Настройка deleteButton
        deleteButton.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        deleteButton.tintColor = .red
        deleteButton.backgroundColor = .white
        deleteButton.layer.cornerRadius = 12
        deleteButton.isHidden = true
        
        // Добавляем subviews
        addSubview(imageView)
        addSubview(deleteButton)
        
        // Constraints
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(-5)
            make.width.height.equalTo(24)
        }
        
        // Настройка view
        backgroundColor = .clear
        layer.shadowColor = UIColor.black.cgColor
        layer.shadowOffset = CGSize(width: 0, height: 2)
        layer.shadowOpacity = 0.3
        layer.shadowRadius = 4
        
        // Добавляем обработчик для кнопки удаления
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        
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
    
    // MARK: - Selection
    func setSelected(_ selected: Bool) {
        isSelected = selected
        deleteButton.isHidden = !selected
        
        if selected {
            layer.borderWidth = 2
            layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
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