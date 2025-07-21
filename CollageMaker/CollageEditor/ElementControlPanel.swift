import UIKit
import SnapKit

protocol ElementControlPanelDelegate: AnyObject {
    func controlPanel(_ panel: ElementControlPanel, didChangeScale scale: CGFloat)
    func controlPanel(_ panel: ElementControlPanel, didChangeRotation rotation: CGFloat)
    func controlPanel(_ panel: ElementControlPanel, didResetTransform: Void)
    func controlPanel(_ panel: ElementControlPanel, didRequestFramePicker: Void)
    func controlPanel(_ panel: ElementControlPanel, didSelectFrameShape frameShape: FrameShape)
}

class ElementControlPanel: UIView {
    
    // MARK: - Properties
    weak var delegate: ElementControlPanelDelegate?
    
    private let rotationButton = UIButton(type: .custom)
    private let scaleButton = UIButton(type: .custom)
    private let resetButton = UIButton(type: .custom)
    private let frameButton = UIButton(type: .custom)
    
    // Gesture tracking
    private var initialRotationAngle: CGFloat = 0
    private var currentRotation: CGFloat = 0
    private var initialScaleDistance: CGFloat = 0
    private var currentScale: CGFloat = 1.0
    
    private var rotationCenter: CGPoint = .zero
    private var scaleStartPoint: CGPoint = .zero
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.7)
        layer.cornerRadius = 12
        
        // Кнопка вращения (нижний правый угол)
        rotationButton.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        rotationButton.setImage(UIImage(systemName: "rotate.right"), for: .normal)
        rotationButton.tintColor = .white
        rotationButton.layer.cornerRadius = 25
        rotationButton.layer.shadowColor = UIColor.black.cgColor
        rotationButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        rotationButton.layer.shadowOpacity = 0.3
        rotationButton.layer.shadowRadius = 4
        
        // Кнопка масштаба (нижний левый угол)
        scaleButton.backgroundColor = UIColor.systemGreen.withAlphaComponent(0.8)
        scaleButton.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
        scaleButton.tintColor = .white
        scaleButton.layer.cornerRadius = 25
        scaleButton.layer.shadowColor = UIColor.black.cgColor
        scaleButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        scaleButton.layer.shadowOpacity = 0.3
        scaleButton.layer.shadowRadius = 4
        
        // Кнопка сброса (верх по центру)
        resetButton.backgroundColor = UIColor.systemRed.withAlphaComponent(0.8)
        resetButton.setImage(UIImage(systemName: "arrow.counterclockwise"), for: .normal)
        resetButton.tintColor = .white
        resetButton.layer.cornerRadius = 20
        resetButton.layer.shadowColor = UIColor.black.cgColor
        resetButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        resetButton.layer.shadowOpacity = 0.3
        resetButton.layer.shadowRadius = 4
        
        // Кнопка фреймов (верхний левый угол)
        frameButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.8)
        frameButton.setImage(UIImage(systemName: "heart"), for: .normal)
        frameButton.tintColor = .white
        frameButton.layer.cornerRadius = 20
        frameButton.layer.shadowColor = UIColor.black.cgColor
        frameButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        frameButton.layer.shadowOpacity = 0.3
        frameButton.layer.shadowRadius = 4
        
        addSubview(rotationButton)
        addSubview(scaleButton)
        addSubview(resetButton)
        addSubview(frameButton)
        
        // Действия кнопок
        resetButton.addTarget(self, action: #selector(resetButtonTapped), for: .touchUpInside)
        frameButton.addTarget(self, action: #selector(frameButtonTapped), for: .touchUpInside)
    }
    
    private func setupConstraints() {
        // Кнопка вращения - нижний правый угол
        rotationButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(10)
            make.width.height.equalTo(50)
        }
        
        // Кнопка масштаба - нижний левый угол
        scaleButton.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview().inset(10)
            make.width.height.equalTo(50)
        }
        
        // Кнопка сброса - верх по центру
        resetButton.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview().inset(10)
            make.width.height.equalTo(40)
        }
        
        // Кнопка фреймов - верхний левый угол
        frameButton.snp.makeConstraints { make in
            make.top.leading.equalToSuperview().inset(10)
            make.width.height.equalTo(40)
        }
    }
    
    private func setupGestures() {
        // Pan gesture для кнопки вращения
        let rotationPan = UIPanGestureRecognizer(target: self, action: #selector(handleRotationPan(_:)))
        rotationButton.addGestureRecognizer(rotationPan)
        
        // Pan gesture для кнопки масштаба
        let scalePan = UIPanGestureRecognizer(target: self, action: #selector(handleScalePan(_:)))
        scaleButton.addGestureRecognizer(scalePan)
    }
    
    // MARK: - Actions
    @objc private func resetButtonTapped() {
        currentRotation = 0
        currentScale = 1.0
        delegate?.controlPanel(self, didResetTransform: ())
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
        impactFeedback.impactOccurred()
        
        // Анимация кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.resetButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.resetButton.transform = .identity
            }
        }
    }
    
    @objc private func frameButtonTapped() {
        delegate?.controlPanel(self, didRequestFramePicker: ())
        
        // Haptic feedback
        let impactFeedback = UIImpactFeedbackGenerator(style: .light)
        impactFeedback.impactOccurred()
        
        // Анимация кнопки
        UIView.animate(withDuration: 0.1, animations: {
            self.frameButton.transform = CGAffineTransform(scaleX: 0.9, y: 0.9)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.frameButton.transform = .identity
            }
        }
    }
    
    // MARK: - Gesture Handlers
    @objc private func handleRotationPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            rotationCenter = rotationButton.center
            let deltaX = location.x - rotationCenter.x
            let deltaY = location.y - rotationCenter.y
            initialRotationAngle = atan2(deltaY, deltaX)
            
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            // Визуальная обратная связь
            UIView.animate(withDuration: 0.1) {
                self.rotationButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            
        case .changed:
            let deltaX = location.x - rotationCenter.x
            let deltaY = location.y - rotationCenter.y
            let currentAngle = atan2(deltaY, deltaX)
            
            let angleDifference = currentAngle - initialRotationAngle
            currentRotation += angleDifference
            initialRotationAngle = currentAngle
            
            delegate?.controlPanel(self, didChangeRotation: angleDifference)
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному размеру
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.rotationButton.transform = .identity
            }
            
        default:
            break
        }
    }
    
    @objc private func handleScalePan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        
        switch gesture.state {
        case .began:
            scaleStartPoint = location
            initialScaleDistance = 0
            
            // Haptic feedback
            let selectionFeedback = UISelectionFeedbackGenerator()
            selectionFeedback.selectionChanged()
            
            // Визуальная обратная связь
            UIView.animate(withDuration: 0.1) {
                self.scaleButton.transform = CGAffineTransform(scaleX: 1.1, y: 1.1)
            }
            
        case .changed:
            let deltaX = location.x - scaleStartPoint.x
            let deltaY = location.y - scaleStartPoint.y
            let distance = sqrt(deltaX * deltaX + deltaY * deltaY)
            
            if initialScaleDistance == 0 {
                initialScaleDistance = distance
                return
            }
            
            let scaleFactor = distance / initialScaleDistance
            let scaleChange = scaleFactor - 1.0
            
            // Ограничиваем масштаб
            let newScale = currentScale + scaleChange * 0.01
            let clampedScale = max(0.2, min(3.0, newScale))
            
            if clampedScale != currentScale {
                let actualScaleChange = clampedScale / currentScale
                currentScale = clampedScale
                delegate?.controlPanel(self, didChangeScale: actualScaleChange)
            }
            
            initialScaleDistance = distance
            
            // Обновляем иконку в зависимости от масштаба
            let iconName = scaleChange > 0 ? "plus.magnifyingglass" : "minus.magnifyingglass"
            scaleButton.setImage(UIImage(systemName: iconName), for: .normal)
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному размеру и иконке
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.scaleButton.transform = .identity
                self.scaleButton.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
            }
            
        default:
            break
        }
    }
    
    // MARK: - Public Methods
    func show(animated: Bool = true) {
        isHidden = false
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }
    
    func hide(animated: Bool = true) {
        if animated {
            UIView.animate(withDuration: 0.2, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.8, y: 0.8)
            }) { _ in
                self.isHidden = true
                self.transform = .identity
            }
        } else {
            isHidden = true
        }
    }
    
    func resetValues() {
        currentRotation = 0
        currentScale = 1.0
    }
    
    // MARK: - Frame Shape Methods
    
    /// Обновляет внешний вид кнопки фрейма в соответствии с выбранной формой
    /// - Parameter frameShape: Текущая форма рамки
    func updateFrameButton(for frameShape: FrameShape) {
        let iconName = frameShape == .none ? "rectangle.dashed" : frameShape.iconName
        frameButton.setImage(UIImage(systemName: iconName), for: .normal)
        
        // Меняем цвет кнопки в зависимости от состояния
        if frameShape == .none {
            frameButton.backgroundColor = UIColor.systemGray.withAlphaComponent(0.8)
        } else {
            frameButton.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.8)
        }
    }
    
    /// Уведомляет delegate о выборе формы рамки
    /// - Parameter frameShape: Выбранная форма рамки
    func notifyFrameShapeSelected(_ frameShape: FrameShape) {
        delegate?.controlPanel(self, didSelectFrameShape: frameShape)
    }
} 