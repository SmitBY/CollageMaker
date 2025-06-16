import UIKit

protocol AdvancedImageGestureHandlerDelegate: AnyObject {
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateTransform transform: CGAffineTransform, for imageView: UIImageView)
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateFrame frame: CGRect, for imageView: UIImageView)
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didTapImageView imageView: UIImageView)
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
    private var selectionOverlay: UIView?
    private var cornerHandles: [UIView] = []
    private var edgeHandles: [UIView] = []
    private var centerHandle: UIView?
    
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
        case resizing(corner: Corner)
        case resizingEdge(edge: Edge)
        case transforming
    }
    
    enum Corner: Equatable {
        case topLeft, topRight, bottomLeft, bottomRight
    }
    
    enum Edge: Equatable {
        case top, bottom, left, right
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
            showSelectionOverlay()
        } else {
            hideSelectionOverlay()
        }
    }
    
    private func showSelectionOverlay() {
        guard let _ = imageView, let containerView = containerView else { return }
        
        hideSelectionOverlay()
        
        // Создаем overlay
        selectionOverlay = UIView()
        selectionOverlay?.backgroundColor = .clear
        selectionOverlay?.layer.borderColor = UIColor.systemBlue.cgColor
        selectionOverlay?.layer.borderWidth = 2.0
        selectionOverlay?.isUserInteractionEnabled = false // Важно: отключаем взаимодействие для самого overlay
        
        // Добавляем overlay в containerView, но ограничиваем его bounds
        containerView.addSubview(selectionOverlay!)
        
        // Позиционируем overlay
        updateOverlayFrame()
        
        // Создаем угловые ручки
        createCornerHandles()
        
        // Создаем ручки краев
        createEdgeHandles()
        
        // Создаем центральную ручку
        createCenterHandle()
        
        // Убеждаемся, что overlay не выходит за границы containerView
        selectionOverlay?.clipsToBounds = true
    }
    
    private func hideSelectionOverlay() {
        selectionOverlay?.removeFromSuperview()
        selectionOverlay = nil
        cornerHandles.forEach { $0.removeFromSuperview() }
        cornerHandles.removeAll()
        edgeHandles.forEach { $0.removeFromSuperview() }
        edgeHandles.removeAll()
        centerHandle?.removeFromSuperview()
        centerHandle = nil
    }
    
    private func updateOverlayFrame() {
        guard let imageView = imageView, let overlay = selectionOverlay, let containerView = containerView else { return }
        
        let frame = imageView.frame
        let expandedFrame = frame.insetBy(dx: -10, dy: -10)
        
        // Ограничиваем overlay границами containerView с учетом трансформации
        let containerBounds = containerView.bounds
        let constrainedFrame = CGRect(
            x: max(containerBounds.minX, min(containerBounds.maxX - max(expandedFrame.width, 50), expandedFrame.origin.x)),
            y: max(containerBounds.minY, min(containerBounds.maxY - max(expandedFrame.height, 50), expandedFrame.origin.y)),
            width: min(expandedFrame.width, containerBounds.width),
            height: min(expandedFrame.height, containerBounds.height)
        )
        
        overlay.frame = constrainedFrame
        // Не применяем transform к overlay - это может вызывать проблемы
        // overlay.transform = imageView.transform
        
        // Обновляем позиции ручек после изменения фрейма
        updateHandlePositions()
    }
    
    private func updateHandlePositions() {
        guard let overlay = selectionOverlay else { return }
        
        let bounds = overlay.bounds
        
        // Обновляем угловые ручки
        for (index, handle) in cornerHandles.enumerated() {
            let corners: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
            if index < corners.count {
                positionCornerHandle(handle, for: corners[index])
            }
        }
        
        // Обновляем ручки краев
        for (index, handle) in edgeHandles.enumerated() {
            let edges: [Edge] = [.top, .bottom, .left, .right]
            if index < edges.count {
                positionEdgeHandle(handle, for: edges[index])
            }
        }
        
        // Обновляем центральную ручку
        centerHandle?.center = CGPoint(x: bounds.midX, y: bounds.midY)
    }
    
    private func createCornerHandles() {
        guard let overlay = selectionOverlay else { return }
        
        let corners: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        
        for corner in corners {
            let handle = createHandle(size: 20, color: .systemBlue)
            overlay.addSubview(handle)
            cornerHandles.append(handle)
            
            // Позиционируем ручку
            positionCornerHandle(handle, for: corner)
            
            // Добавляем жест
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCornerPan(_:)))
            handle.addGestureRecognizer(panGesture)
            handle.tag = corners.firstIndex(of: corner) ?? 0
        }
    }
    
    private func createEdgeHandles() {
        guard let overlay = selectionOverlay else { return }
        
        let edges: [Edge] = [.top, .bottom, .left, .right]
        
        for edge in edges {
            let handle = createHandle(size: 16, color: .systemGreen)
            overlay.addSubview(handle)
            edgeHandles.append(handle)
            
            // Позиционируем ручку
            positionEdgeHandle(handle, for: edge)
            
            // Добавляем жест
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleEdgePan(_:)))
            handle.addGestureRecognizer(panGesture)
            handle.tag = edges.firstIndex(of: edge) ?? 0
        }
    }
    
    private func createCenterHandle() {
        guard let overlay = selectionOverlay else { return }
        
        centerHandle = createHandle(size: 24, color: .systemOrange)
        overlay.addSubview(centerHandle!)
        
        // Позиционируем в центре
        centerHandle?.center = CGPoint(x: overlay.bounds.midX, y: overlay.bounds.midY)
        
        // Добавляем жест для перемещения
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCenterPan(_:)))
        centerHandle?.addGestureRecognizer(panGesture)
    }
    
    private func createHandle(size: CGFloat, color: UIColor) -> UIView {
        let handle = UIView(frame: CGRect(x: 0, y: 0, width: size, height: size))
        handle.backgroundColor = color
        handle.layer.cornerRadius = size / 2
        handle.layer.borderColor = UIColor.white.cgColor
        handle.layer.borderWidth = 2
        handle.isUserInteractionEnabled = true
        
        // Добавляем тень для лучшей видимости
        handle.layer.shadowColor = UIColor.black.cgColor
        handle.layer.shadowOffset = CGSize(width: 0, height: 2)
        handle.layer.shadowOpacity = 0.3
        handle.layer.shadowRadius = 2
        
        return handle
    }
    
    private func positionCornerHandle(_ handle: UIView, for corner: Corner) {
        guard let overlay = selectionOverlay else { return }
        
        let bounds = overlay.bounds
        
        switch corner {
        case .topLeft:
            handle.center = CGPoint(x: 0, y: 0)
        case .topRight:
            handle.center = CGPoint(x: bounds.width, y: 0)
        case .bottomLeft:
            handle.center = CGPoint(x: 0, y: bounds.height)
        case .bottomRight:
            handle.center = CGPoint(x: bounds.width, y: bounds.height)
        }
    }
    
    private func positionEdgeHandle(_ handle: UIView, for edge: Edge) {
        guard let overlay = selectionOverlay else { return }
        
        let bounds = overlay.bounds
        
        switch edge {
        case .top:
            handle.center = CGPoint(x: bounds.midX, y: 0)
        case .bottom:
            handle.center = CGPoint(x: bounds.midX, y: bounds.height)
        case .left:
            handle.center = CGPoint(x: 0, y: bounds.midY)
        case .right:
            handle.center = CGPoint(x: bounds.width, y: bounds.midY)
        }
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
            
            updateOverlayFrame()
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
                updateOverlayFrame()
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
            updateOverlayFrame()
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateTransform: imageView.transform, for: imageView)
        default:
            break
        }
    }
    
    @objc private func handleCenterPan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = imageView else { return }
        
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
            
            updateOverlayFrame()
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        default:
            break
        }
    }
    
    @objc private func handleCornerPan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        let corners: [Corner] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        let corner = corners[gesture.view?.tag ?? 0]
        
        let translation = gesture.translation(in: imageView.superview)
        
        switch gesture.state {
        case .began:
            editingMode = .resizing(corner: corner)
            initialFrame = imageView.frame
        case .changed:
            let newFrame = calculateNewFrame(from: initialFrame, corner: corner, translation: translation)
            imageView.frame = newFrame
            updateOverlayFrame()
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        default:
            break
        }
    }
    
    @objc private func handleEdgePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = imageView else { return }
        
        let edges: [Edge] = [.top, .bottom, .left, .right]
        let edge = edges[gesture.view?.tag ?? 0]
        
        let translation = gesture.translation(in: imageView.superview)
        
        switch gesture.state {
        case .began:
            editingMode = .resizingEdge(edge: edge)
            initialFrame = imageView.frame
        case .changed:
            let newFrame = calculateNewFrame(from: initialFrame, edge: edge, translation: translation)
            imageView.frame = newFrame
            updateOverlayFrame()
        case .ended, .cancelled:
            editingMode = .none
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        default:
            break
        }
    }
    
    // MARK: - Helper Methods
    
    private func calculateNewFrame(from frame: CGRect, corner: Corner, translation: CGPoint) -> CGRect {
        var newFrame = frame
        
        switch corner {
        case .topLeft:
            newFrame.origin.x += translation.x
            newFrame.origin.y += translation.y
            newFrame.size.width -= translation.x
            newFrame.size.height -= translation.y
        case .topRight:
            newFrame.origin.y += translation.y
            newFrame.size.width += translation.x
            newFrame.size.height -= translation.y
        case .bottomLeft:
            newFrame.origin.x += translation.x
            newFrame.size.width -= translation.x
            newFrame.size.height += translation.y
        case .bottomRight:
            newFrame.size.width += translation.x
            newFrame.size.height += translation.y
        }
        
        // Минимальный размер
        newFrame.size.width = max(newFrame.size.width, 50)
        newFrame.size.height = max(newFrame.size.height, 50)
        
        return newFrame
    }
    
    private func calculateNewFrame(from frame: CGRect, edge: Edge, translation: CGPoint) -> CGRect {
        var newFrame = frame
        
        switch edge {
        case .top:
            newFrame.origin.y += translation.y
            newFrame.size.height -= translation.y
        case .bottom:
            newFrame.size.height += translation.y
        case .left:
            newFrame.origin.x += translation.x
            newFrame.size.width -= translation.x
        case .right:
            newFrame.size.width += translation.x
        }
        
        // Минимальный размер
        newFrame.size.width = max(newFrame.size.width, 50)
        newFrame.size.height = max(newFrame.size.height, 50)
        
        return newFrame
    }
    
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
            
            // Обновляем overlay
            updateOverlayFrame()
            
            // Уведомляем делегата
            delegate?.gestureHandler(self, didUpdateFrame: imageView.frame, for: imageView)
        }
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