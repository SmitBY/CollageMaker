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

    let adaptiveTextView: AdaptiveTextView = {
        let view = AdaptiveTextView()
        view.text = "Введите текст"
        view.font = UIFont.systemFont(ofSize: 24)
        view.textColor = .black
        view.isUserInteractionEnabled = true
        // Настройки адаптации текста
        view.adjustsFontSizeToFitWidth = true
        view.enablesWordWrapping = true
        view.minimumFontSize = 12
        view.maximumFontSize = 72
        view.maxWidth = 180 // Учитываем отступы
        view.maxHeight = 180
        return view
    }()

    // Для совместимости с существующим кодом
    var archTextView: ArchTextView {
        return adaptiveTextView
    }

    // Для совместимости с существующим кодом
    var textLabel: UILabel {
        let label = UILabel()
        label.text = adaptiveTextView.text
        label.font = adaptiveTextView.font
        label.textColor = adaptiveTextView.textColor
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
    
    private let scaleControlButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
        button.tintColor = .systemGreen
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
        button.isHidden = true
        return button
    }()
    
    private let rotationControlButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "arrow.clockwise.circle"), for: .normal)
        button.tintColor = .systemBlue
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 3
        button.isHidden = true
        return button
    }()
    
    // Индикатор масштаба (улучшение)
    private let scaleIndicator: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemBlue
        label.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
        label.layer.cornerRadius = 8
        label.clipsToBounds = true
        label.textAlignment = .center
        label.alpha = 0
        return label
    }()
    
    var onDelete: (() -> Void)?
    var onTap: (() -> Void)?
    
    private var isSelected = false {
        didSet {
            updateSelectionState()
        }
    }
    
    // Для отслеживания комбинированных жестов
    private var gestureBeganTransform: CGAffineTransform = .identity
    private var gestureBeganCenter: CGPoint = .zero
    private var currentScale: CGFloat = 1.0
    private var currentRotation: CGFloat = 0.0
    private var currentTextAlignment: NSTextAlignment = .center

    // Состояние жестов для защиты от отмены
    private var lastValidTransform: CGAffineTransform = .identity
    private var lastGestureTransform: CGAffineTransform = .identity // Сохраняем последний жест отдельно
    private var isGestureActive: Bool = false
    private var lastRotationAngle: CGFloat = 0.0 // Последний угол поворота
    
    // Настройки поведения жестов
    var isSnapToAngleEnabled: Bool = false // Отключаем по умолчанию!
    var snapToAngleThreshold: CGFloat = 0.03 // ~1.7 градуса - очень строгий порог
    
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

        addSubview(adaptiveTextView)
        addSubview(deleteButton)
        addSubview(scaleControlButton)
        addSubview(rotationControlButton)
        addSubview(scaleIndicator)

        // Настраиваем callback для изменения размера
        adaptiveTextView.onSizeChanged = { [weak self] newSize in
            self?.handleTextSizeChanged(newSize)
        }

        adaptiveTextView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().offset(8)
            make.size.equalTo(30)
        }
        
        scaleControlButton.snp.makeConstraints { make in
            make.bottom.leading.equalToSuperview().inset(-5)
            make.size.equalTo(24)
        }
        
        rotationControlButton.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(-5)
            make.size.equalTo(24)
        }
        
        scaleIndicator.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(-30)
            make.centerX.equalToSuperview()
            make.width.equalTo(60)
            make.height.equalTo(20)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        setupControlButtonGestures()
        
        // Изначально компенсируем масштаб для кнопок управления
        updateControlButtonsScaleCompensation()
    }
    
    private func setupGestures() {
        // Перемещение
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        panGesture.delegate = self
        panGesture.cancelsTouchesInView = false
        addGestureRecognizer(panGesture)
        
        // Масштабирование
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        pinchGesture.delegate = self
        pinchGesture.cancelsTouchesInView = false
        addGestureRecognizer(pinchGesture)
        
        // Вращение
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        rotationGesture.delegate = self
        rotationGesture.cancelsTouchesInView = false
        addGestureRecognizer(rotationGesture)
        
        // Нажатие для выбора
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tapGesture)
        
        // Двойное нажатие для сброса трансформаций
        let doubleTapGesture = UITapGestureRecognizer(target: self, action: #selector(handleDoubleTap(_:)))
        doubleTapGesture.numberOfTapsRequired = 2
        addGestureRecognizer(doubleTapGesture)
        
        // Убеждаемся, что обычный тап не мешает двойному
        tapGesture.require(toFail: doubleTapGesture)
        
        // Расширяем область распознавания жестов
        expandGestureRecognitionArea()
        
        // Делаем элемент интерактивным
        isUserInteractionEnabled = true
    }
    
    /// Расширяет область распознавания жестов за пределы видимой рамки
    private func expandGestureRecognitionArea() {
        // Увеличиваем hit area для лучшего распознавания жестов
        layer.masksToBounds = false
        clipsToBounds = false
        
        // Добавляем невидимую расширенную область
        let extendedTouchArea = UIView()
        extendedTouchArea.backgroundColor = .clear
        extendedTouchArea.isUserInteractionEnabled = false
        insertSubview(extendedTouchArea, at: 0)
        
        extendedTouchArea.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalToSuperview().multipliedBy(2.0) // На 100% больше
        }
    }
    
    private func setupControlButtonGestures() {
        // Pan gesture для кнопки масштабирования
        let scalePanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleScaleControlPan(_:)))
        scaleControlButton.addGestureRecognizer(scalePanGesture)
        
        // Pan gesture для кнопки вращения
        let rotationPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleRotationControlPan(_:)))
        rotationControlButton.addGestureRecognizer(rotationPanGesture)
    }
    
    // MARK: - Улучшенные Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            gestureBeganCenter = center
            lastGestureTransform = transform
            isGestureActive = true
            setSelected(true)
            
        case .changed:
            let translation = gesture.translation(in: containerView)
            let newCenter = CGPoint(x: gestureBeganCenter.x + translation.x, y: gestureBeganCenter.y + translation.y)
            
            // Ограничиваем движение в пределах контейнера
            let constrainedCenter = constrainTextLayerCenter(newCenter, containerView: containerView)
            center = constrainedCenter
            lastValidTransform = transform // Сохраняем при каждом изменении
            
        case .ended:
            // Нормальное завершение перемещения
            isGestureActive = false
            lastValidTransform = transform // Финальное состояние
            
        case .cancelled, .failed:
            // Восстанавливаем последнее сохраненное состояние
            isGestureActive = false
            transform = lastValidTransform
            
        default:
            break
        }
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            gestureBeganTransform = transform
            lastGestureTransform = transform
            isGestureActive = true
            setSelected(true)
            
        case .changed:
            let scale = gesture.scale
            let newTransform = gestureBeganTransform.scaledBy(x: scale, y: scale)
            
            // Улучшенные ограничения масштаба
            let minScale: CGFloat = 0.2
            let maxScale: CGFloat = 4.0
            let currentScale = sqrt(newTransform.a * newTransform.a + newTransform.c * newTransform.c)
            
            if currentScale >= minScale && currentScale <= maxScale {
                transform = newTransform
                lastValidTransform = newTransform // Сохраняем при каждом изменении
                
                // Показываем индикатор масштаба
                showScaleIndicator(scale: currentScale)
                
                // После изменения масштаба корректируем позицию
                let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
                center = constrainedCenter

                // Компенсируем масштаб иконок управления
                updateControlButtonsScaleCompensation()
            }
            
        case .ended:
            // Нормальное завершение масштабирования
            isGestureActive = false
            hideScaleIndicator()
            lastValidTransform = transform // Финальное состояние
            
        case .cancelled, .failed:
            // Возвращаем к последнему сохраненному состоянию
            isGestureActive = false
            hideScaleIndicator()
            transform = lastValidTransform
            
        default:
            break
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let containerView = superview else { return }
        
        switch gesture.state {
        case .began:
            gestureBeganTransform = transform
            lastGestureTransform = transform
            isGestureActive = true
            setSelected(true)
            
            // Сохраняем текущий угол
            lastRotationAngle = atan2(transform.b, transform.a)
            
        case .changed:
            let rotation = gesture.rotation
            let newTransform = gestureBeganTransform.rotated(by: rotation)
            transform = newTransform
            
            // КРИТИЧЕСКИ ВАЖНО: Сохраняем трансформацию при каждом изменении
            lastValidTransform = newTransform
            
            // Обновляем сохраненный угол
            lastRotationAngle = atan2(newTransform.b, newTransform.a)
            
            // Показываем индикатор поворота
            showRotationIndicator(rotation: rotation)
            
            // После поворота корректируем позицию
            let constrainedCenter = constrainTextLayerCenter(center, containerView: containerView)
            center = constrainedCenter

            // Компенсируем масштаб иконок управления
            updateControlButtonsScaleCompensation()
            
        case .ended:
            // Нормальное завершение вращения
            isGestureActive = false
            hideScaleIndicator()
            
            // УСТРАНЯЕМ БАГ: сохраняем последнюю трансформацию перед любым snap
            let finalTransform = transform
            
            // Делаем привязку только если очень близко к углу и включена опция
            if isSnapToAngleEnabled {
                let wasSnapped = attemptSnapToAngleIfVeryClose()
                
                // Если не было привязки, гарантируем сохранение поворота
                if !wasSnapped {
                    // Применяем сохраненную трансформацию
                    transform = finalTransform
                }
            }
            
            // В любом случае запоминаем последнее состояние
            lastValidTransform = transform
            
        case .cancelled, .failed:
            // При отмене или сбое жеста гарантированно восстанавливаем 
            // последнее известное валидное состояние
            isGestureActive = false
            hideScaleIndicator()
            transform = lastValidTransform
            
        default:
            break
        }
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        onTap?()
        setSelected(true)
    }
    
    @objc private func handleDoubleTap(_ gesture: UITapGestureRecognizer) {
        // Сброс всех трансформаций с анимацией
        UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.3, options: [], animations: {
            self.transform = .identity
        })
        
        // Обновляем последнюю валидную трансформацию
        lastValidTransform = .identity
        
        // Показываем визуальную обратную связь
        flashSelection()
    }
    
    @objc private func deleteButtonTapped() {
        // Улучшенная анимация удаления
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.6, initialSpringVelocity: 0.8, options: [], animations: {
            self.transform = self.transform.scaledBy(x: 0.1, y: 0.1)
            self.alpha = 0
        }) { _ in
            self.onDelete?()
        }
    }
    
    // MARK: - Control Button Gesture Handlers
    @objc private func handleScaleControlPan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        switch gesture.state {
        case .began:
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Анимация кнопки
            UIView.animate(withDuration: 0.1) {
                self.scaleControlButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
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
            scaleControlButton.setImage(UIImage(systemName: iconName), for: .normal)

            // Компенсируем масштаб иконок
            updateControlButtonsScaleCompensation()
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному состоянию
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.scaleControlButton.transform = .identity
                self.scaleControlButton.setImage(UIImage(systemName: "plus.magnifyingglass"), for: .normal)
            }
            
        default:
            break
        }
    }
    
    @objc private func handleRotationControlPan(_ gesture: UIPanGestureRecognizer) {
        let location = gesture.location(in: self)
        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        
        switch gesture.state {
        case .began:
            // Haptic feedback
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            
            // Анимация кнопки
            UIView.animate(withDuration: 0.1) {
                self.rotationControlButton.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
            
        case .changed:
            // Вычисляем угол относительно центра элемента
            let deltaX = location.x - center.x
            let deltaY = location.y - center.y
            let angle = atan2(deltaY, deltaX)
            
            // Применяем небольшое вращение
            let rotationIncrement = angle * 0.05 // Чувствительность вращения
            transform = transform.rotated(by: rotationIncrement)

            // Обновляем компенсацию масштаба для кнопок
            updateControlButtonsScaleCompensation()
            
        case .ended, .cancelled:
            // Возвращаем кнопку к нормальному состоянию
            UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                self.rotationControlButton.transform = .identity
            }
            
        default:
            break
        }
    }
    
    // MARK: - Улучшенные вспомогательные методы
    
    private func showScaleIndicator(scale: CGFloat) {
        scaleIndicator.text = String(format: "%.1f×", scale)
        
        UIView.animate(withDuration: 0.1) {
            self.scaleIndicator.alpha = 1.0
        }
    }
    
    private func showRotationIndicator(rotation: CGFloat) {
        // Показываем общий угол поворота, а не инкрементальный
        let totalAngle = atan2(transform.b, transform.a)
        let degrees = Int((totalAngle * 180 / .pi).truncatingRemainder(dividingBy: 360))
        let normalizedDegrees = degrees < 0 ? degrees + 360 : degrees
        scaleIndicator.text = "\(normalizedDegrees)°"
        
        UIView.animate(withDuration: 0.1) {
            self.scaleIndicator.alpha = 1.0
        }
    }
    
    private func hideScaleIndicator() {
        UIView.animate(withDuration: 0.3) {
            self.scaleIndicator.alpha = 0
        }
    }
    
    /// Улучшенная функция привязки к углу с очень строгим порогом
    /// Возвращает true если была привязка, false если нет
    private func attemptSnapToAngleIfVeryClose() -> Bool {
        // Текущий угол поворота
        let currentAngle = atan2(transform.b, transform.a)
        
        // Нормализуем угол в диапазон [0, 2π]
        let normalizedAngle = currentAngle < 0 ? currentAngle + 2 * .pi : currentAngle
        
        // Углы для привязки (0°, 90°, 180°, 270°)
        let snapAngles: [CGFloat] = [0, .pi/2, .pi, 3 * .pi / 2, 2 * .pi]
        
        // Поиск ближайшего угла для привязки
        var closestAngle: CGFloat? = nil
        var minDiff: CGFloat = snapToAngleThreshold // Используем порог как начальный минимум
        
        for snapAngle in snapAngles {
            let diff = abs(normalizedAngle - snapAngle)
            if diff < minDiff {
                minDiff = diff
                closestAngle = snapAngle == 2 * .pi ? 0 : snapAngle // 2π = 0
            }
        }
        
        // Привязываем только если очень близко к одному из углов
        if let snapAngle = closestAngle {
            // Сохраняем текущий масштаб
            let currentScale = sqrt(transform.a * transform.a + transform.c * transform.c)
            
            // Создаем новую трансформацию с сохранением масштаба
            let snapTransform = CGAffineTransform(scaleX: currentScale, y: currentScale).rotated(by: snapAngle)
            
            UIView.animate(withDuration: 0.15, delay: 0, usingSpringWithDamping: 0.9, initialSpringVelocity: 0.3, options: [], animations: {
                self.transform = snapTransform
            })
            
            // Была привязка
            return true
        }
        
        // Не было привязки
        return false
    }
    
    private func flashSelection() {
        // Быстрая вспышка для обратной связи
        let originalBorderColor = layer.borderColor
        let originalBorderWidth = layer.borderWidth
        
        UIView.animate(withDuration: 0.1) {
            self.layer.borderColor = UIColor.systemGreen.cgColor
            self.layer.borderWidth = 3
        } completion: { _ in
            UIView.animate(withDuration: 0.2) {
                self.layer.borderColor = originalBorderColor
                self.layer.borderWidth = originalBorderWidth
            }
        }
    }
    
    // MARK: - Public Methods
    
    func setSelected(_ selected: Bool) {
        isSelected = selected
    }
    
    private func updateSelectionState() {
        UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [], animations: {
            if self.isSelected {
                self.layer.borderColor = UIColor.systemBlue.cgColor
                self.layer.borderWidth = 2
                self.layer.cornerRadius = 8
                self.deleteButton.isHidden = false
                self.scaleControlButton.isHidden = false
                self.rotationControlButton.isHidden = false
                
                // Улучшенная тень для выделения
                self.layer.shadowColor = UIColor.systemBlue.cgColor
                self.layer.shadowOffset = CGSize(width: 0, height: 3)
                self.layer.shadowOpacity = 0.4
                self.layer.shadowRadius = 6
                
                // Анимация появления кнопок
                self.animateControlButtonsAppearance()
            } else {
                self.layer.borderColor = UIColor.clear.cgColor
                self.layer.borderWidth = 0
                self.layer.cornerRadius = 0
                self.deleteButton.isHidden = true
                self.scaleControlButton.isHidden = true
                self.rotationControlButton.isHidden = true
                
                // Убираем тень
                self.layer.shadowOpacity = 0
            }
        })
    }
    
    private func animateControlButtonsAppearance() {
        let buttons = [deleteButton, scaleControlButton, rotationControlButton]
        
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
    
    func updateText(_ text: String) {
        adaptiveTextView.updateText(text)
    }

    func updateTextColor(_ color: UIColor) {
        adaptiveTextView.updateTextColor(color)
    }

    func updateFont(_ font: UIFont) {
        adaptiveTextView.updateFont(font)
    }

    func updateFontByName(_ fontName: String) {
        let currentSize = adaptiveTextView.font.pointSize
        if let newFont = UIFont(name: fontName, size: currentSize) {
            adaptiveTextView.updateFont(newFont)
        }
    }

    func applyArchEffect(intensity: CGFloat) {
        adaptiveTextView.updateArchIntensity(intensity)
    }

    // MARK: - Adaptive Text Methods

    /// Обработчик изменения размера текста
    private func handleTextSizeChanged(_ newSize: CGSize) {
        // Автоматически обновляем размер контейнера с учетом отступов
        let containerWidth = max(newSize.width, 50)  // Минимальная ширина
        let containerHeight = max(newSize.height, 30) // Минимальная высота

        // Обновляем размеры с анимацией
        UIView.animate(withDuration: 0.2, delay: 0, options: .curveEaseOut) {
            self.frame.size = CGSize(width: containerWidth, height: containerHeight)
            // Принудительно обновляем отображение текста
            self.adaptiveTextView.setNeedsDisplay()
            self.layoutIfNeeded()
        } completion: { _ in
            // После завершения анимации еще раз обновляем отображение
            self.adaptiveTextView.setNeedsDisplay()
        }
    }

    /// Настроить параметры адаптации текста
    func configureTextAdaptation(minFontSize: CGFloat? = nil, maxFontSize: CGFloat? = nil,
                               adjustsFontSize: Bool? = nil, enablesWrapping: Bool? = nil) {
        if let minSize = minFontSize {
            adaptiveTextView.minimumFontSize = minSize
        }
        if let maxSize = maxFontSize {
            adaptiveTextView.maximumFontSize = maxSize
        }
        if let adjusts = adjustsFontSize {
            adaptiveTextView.adjustsFontSizeToFitWidth = adjusts
        }
        if let wrapping = enablesWrapping {
            adaptiveTextView.enablesWordWrapping = wrapping
        }
    }

    /// Обновить ограничения для текста
    func updateTextConstraints(maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        if let width = maxWidth {
            adaptiveTextView.maxWidth = width
        }
        if let height = maxHeight {
            adaptiveTextView.maxHeight = height
        }
    }

    /// Сбросить адаптацию текста
    func resetTextAdaptation() {
        adaptiveTextView.resetAdaptation()
    }

    /// Установить выравнивание текста
    func setTextAlignment(_ alignment: NSTextAlignment) {
        currentTextAlignment = alignment
        // При необходимости можно обновить отображение текста здесь
        setNeedsDisplay()
    }

    /// Получить текущее выравнивание текста
    func getTextAlignment() -> NSTextAlignment {
        return currentTextAlignment
    }

    /// Установить выравнивание текста для адаптивного текста
    func setAdaptiveTextAlignment(_ alignment: NSTextAlignment) {
        currentTextAlignment = alignment
        adaptiveTextView.textAlignment = alignment
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
    
    // MARK: - Улучшенные Helper Methods
    
    private func constrainTextLayerCenter(_ center: CGPoint, containerView: UIView) -> CGPoint {
        // Получаем размеры текстового слоя с учетом трансформации
        let transformedBounds = bounds.applying(transform)
        let containerBounds = containerView.bounds
        
        // Уменьшенный отступ для большей свободы
        let margin: CGFloat = 15
        
        // Учитываем размеры с трансформацией
        let halfWidth = abs(transformedBounds.width) / 2
        let halfHeight = abs(transformedBounds.height) / 2
        
        // Вычисляем ограничения с учетом индикатора масштаба
        let minX = halfWidth + margin
        let maxX = containerBounds.width - halfWidth - margin
        let minY = max(halfHeight + margin, 40) // Дополнительное место для индикатора
        let maxY = containerBounds.height - halfHeight - margin
        
        // Ограничиваем позицию центра
        let constrainedX = max(minX, min(maxX, center.x))
        let constrainedY = max(minY, min(maxY, center.y))
        
        return CGPoint(x: constrainedX, y: constrainedY)
    }
    
    // MARK: - Расширенная область касаний
    
    /// Расширяет область распознавания касаний за пределы видимых границ
    override func point(inside point: CGPoint, with event: UIEvent?) -> Bool {
        // Всегда расширяем область касаний для большей стабильности
        let expandedBounds = bounds.insetBy(dx: -40, dy: -40) // Расширяем на 40 точек во все стороны
        return expandedBounds.contains(point)
    }
}

// MARK: - Оптимизированный UIGestureRecognizerDelegate

extension TextLayerView: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Разрешаем одновременное выполнение всех жестов трансформации
        let transformGestures = [UIPinchGestureRecognizer.self, UIRotationGestureRecognizer.self, UIPanGestureRecognizer.self]
        
        if transformGestures.contains(where: { $0 == type(of: gestureRecognizer) }) &&
           transformGestures.contains(where: { $0 == type(of: otherGestureRecognizer) }) {
            return true
        }
        
        return false
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        // Если нажали на любую из кнопок управления, не обрабатываем другие жесты
        if touch.view == deleteButton || touch.view == scaleControlButton || touch.view == rotationControlButton {
            return false
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldBeRequiredToFailBy otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Приоритет жестам трансформации над другими жестами
        if gestureRecognizer is UIRotationGestureRecognizer || 
           gestureRecognizer is UIPinchGestureRecognizer ||
           gestureRecognizer is UIPanGestureRecognizer {
            return false
        }
        return false
    }
    
    override func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Всегда разрешаем начало жестов трансформации, даже если активен другой жест
        return true
    }
}

// MARK: - Fixed-size control buttons support
extension TextLayerView {
    private func updateControlButtonsScaleCompensation() {
        // Извлекаем текущий масштаб из аффинного transform
        let a = transform.a
        let c = transform.c
        let scale = sqrt(a * a + c * c)
        let inverseScale = scale == 0 ? 1.0 : (1.0 / scale)

        let compensation = CGAffineTransform(scaleX: inverseScale, y: inverseScale)
        deleteButton.transform = compensation
        scaleControlButton.transform = compensation
        rotationControlButton.transform = compensation
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        // Обновляем компенсацию при любом изменении лейаута
        updateControlButtonsScaleCompensation()
    }
}
 
