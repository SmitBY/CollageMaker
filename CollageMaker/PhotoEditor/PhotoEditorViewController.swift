//
//  PhotoEditorViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 03.02.2025.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class PhotoEditorViewController: UIViewController {
    // MARK: - Properties
    let viewModel: PhotoEditorViewModel
    private let disposeBag = DisposeBag()
    weak var coordinator: HomeViewCoordinator?
    
    /// Callback для возврата отредактированного изображения
    var editingCompletion: ((UIImage?) -> Void)?
    
    // Переменные для обрезки
    private var initialCropFrame: CGRect?
    private var currentGestureHandle: CropHandleView?
    private var cropMode: CropMode = .move
    private var cropHandles: [CropHandleView] = []
    
    // Переменные для перетягивания кропа
    private var isDraggingCrop = false
    private var cropDragStartFrame: CGRect?
    private var lastBoundaryFeedbackTime: TimeInterval = 0
    private var isUpdatingHandlePositions = false
    
    // Фильтры
    private let filtersManager = ImageFiltersManager()
    private var originalImage: UIImage?
    private var currentFilterType: ImageFiltersManager.FilterType = .none
    private var filterPreviews: [ImageFiltersManager.FilterType: UIImage] = [:]
    
    // Форматы изображений
    enum AspectRatioFormat: String, CaseIterable {
        case free = "Произвольный"
        case ultraWide = "19:9"
        case vertical = "9:16"
        case portrait = "4:5"
        case landscape = "5:4"
        case square = "1:1"
        
        var ratio: CGFloat? {
            switch self {
            case .free: return nil
            case .ultraWide: return 19.0/9.0
            case .vertical: return 9.0/16.0
            case .portrait: return 4.0/5.0
            case .landscape: return 5.0/4.0
            case .square: return 1.0
            }
        }
    }
    
    private var currentAspectRatio: AspectRatioFormat = .free
    
    enum CropMode {
        case move
        case resizeTopLeft
        case resizeTopRight
        case resizeBottomLeft
        case resizeBottomRight
        case resizeLeft
        case resizeRight
        case resizeTop
        case resizeBottom
    }
    

    
    // MARK: - UI Elements
    /// Контейнер для изображения. Фон – черный, чтобы если изображение выходит за crop‑окно, оно показывалось на черном фоне.
    private let photoContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .black
        view.clipsToBounds = false
        return view
    }()
    
    // ImageView для отображения выбранного изображения.
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = false
        return iv
    }()
    
        // CropOverlayView затемняет область вне cropRect.
    private let cropOverlayView: CropOverlayView = {
        let overlay = CropOverlayView()
        overlay.backgroundColor = .clear
        overlay.isUserInteractionEnabled = false
        return overlay
    }()
    
    /// CropGridView – сетка для кадрирования.
    private let cropGridView: CropGridView = {
        let grid = CropGridView()
        grid.backgroundColor = .clear
        grid.isUserInteractionEnabled = true
        return grid
    }()
    
    /// Невидимая область для перетягивания всей кроп-области
    private let cropDragView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.isUserInteractionEnabled = true
        
        // Добавляем визуальный индикатор перетягивания
        let dragIndicator = UIView()
        dragIndicator.backgroundColor = UIColor.white.withAlphaComponent(0.3)
        dragIndicator.layer.cornerRadius = 4
        dragIndicator.layer.borderWidth = 1
        dragIndicator.layer.borderColor = UIColor.white.withAlphaComponent(0.5).cgColor
        dragIndicator.isUserInteractionEnabled = false
        
        view.addSubview(dragIndicator)
        dragIndicator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            dragIndicator.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            dragIndicator.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            dragIndicator.widthAnchor.constraint(equalToConstant: 30),
            dragIndicator.heightAnchor.constraint(equalToConstant: 30)
        ])
        
        // Добавляем четыре точки для индикации перетягивания
        let dotSize: CGFloat = 4
        let spacing: CGFloat = 6
        
        for i in 0..<4 {
            let dot = UIView()
            dot.backgroundColor = UIColor.white.withAlphaComponent(0.8)
            dot.layer.cornerRadius = dotSize / 2
            dot.isUserInteractionEnabled = false
            
            dragIndicator.addSubview(dot)
            dot.translatesAutoresizingMaskIntoConstraints = false
            
            let xOffset = (i % 2 == 0) ? -spacing/2 : spacing/2
            let yOffset = (i < 2) ? -spacing/2 : spacing/2
            
            NSLayoutConstraint.activate([
                dot.centerXAnchor.constraint(equalTo: dragIndicator.centerXAnchor, constant: xOffset),
                dot.centerYAnchor.constraint(equalTo: dragIndicator.centerYAnchor, constant: yOffset),
                dot.widthAnchor.constraint(equalToConstant: dotSize),
                dot.heightAnchor.constraint(equalToConstant: dotSize)
            ])
        }
        
        return view
    }()
    
    /// Коллекция форматов изображений
    private let aspectRatioCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 40)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(AspectRatioCell.self, forCellWithReuseIdentifier: AspectRatioCell.identifier)
        return cv
    }()
    
    /// Коллекция фильтров
    private let filtersCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.itemSize = CGSize(width: 80, height: 100)
        layout.minimumInteritemSpacing = 8
        layout.minimumLineSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        cv.register(FilterCollectionViewCell.self, forCellWithReuseIdentifier: FilterCollectionViewCell.identifier)
        return cv
    }()
    
    /// UIStackView для кнопок Cancel и Save.
    private let buttonStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.alignment = .fill
        sv.distribution = .fillEqually
        sv.spacing = 16
        return sv
    }()
    
    private let cancelButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Cancel", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 4
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Save", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 4
        return button
    }()
    
    // MARK: - Initializer
    init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        print("[PhotoEditorViewController] init(viewModel:) called")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupGestureRecognizers()
        setupFiltersCollection()
        setupAspectRatioCollection()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("photoContainerView bounds: \(photoContainerView.bounds)")
        
        // Обновляем cropOverlayView.cropRect только когда cropGridView имеет правильный размер
        if imageView.image != nil && !cropGridView.frame.isEmpty {
            // Конвертируем cropGridView.frame в координаты главного view для CropOverlayView
            let cropRectInView = photoContainerView.convert(cropGridView.frame, to: view)
            cropOverlayView.cropRect = cropRectInView
            print("Setting cropOverlayView.cropRect to: \(cropRectInView)")
            updateCropHandlesPositions()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .black
        
        // Добавляем CropOverlayView поверх всего экрана
        view.addSubview(cropOverlayView)
        cropOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Добавляем photoContainerView
        view.addSubview(photoContainerView)
        photoContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.height.equalTo(photoContainerView.snp.width) // Квадратное соотношение сторон
        }
        
        // Добавляем ImageView напрямую в photoContainerView
        photoContainerView.addSubview(imageView)
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Добавляем CropGridView поверх imageView
        photoContainerView.addSubview(cropGridView)
        cropGridView.snp.makeConstraints { make in
            make.center.equalTo(imageView)
        }
        
        // Добавляем невидимую область для перетягивания кропа (только центральная часть)
        photoContainerView.addSubview(cropDragView)
        cropDragView.snp.makeConstraints { make in
            make.center.equalTo(cropGridView)
            make.width.equalTo(cropGridView).offset(-60) // Оставляем 30px с каждой стороны для хендлов
            make.height.equalTo(cropGridView).offset(-60) // Оставляем 30px сверху и снизу для хендлов
        }
        
        // Добавляем коллекцию форматов изображений
        view.addSubview(aspectRatioCollectionView)
        aspectRatioCollectionView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide.snp.top).offset(20)
            make.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        
        // Добавляем коллекцию фильтров
        view.addSubview(filtersCollectionView)
        filtersCollectionView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(100)
            make.left.right.equalToSuperview()
            make.height.equalTo(120)
        }
        
        // Добавляем кнопки
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(20)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    private func updateCropGridViewConstraints() {
        // Используем Auto Layout для установки начального размера
        let visibleImageRect = imageView.frame.intersection(photoContainerView.bounds)
        
        print("ImageView frame: \(imageView.frame)")
        print("PhotoContainer bounds: \(photoContainerView.bounds)")
        print("Visible image rect: \(visibleImageRect)")
        
        // Проверяем, что видимая область имеет валидные размеры
        guard visibleImageRect.width > 0 && visibleImageRect.height > 0 else {
            print("Warning: Invalid visible image rect: \(visibleImageRect)")
            return
        }
        
        // Ограничиваем размеры рамки кропа границами изображения
        let maxWidth = min(visibleImageRect.width, imageView.frame.width)
        let maxHeight = min(visibleImageRect.height, imageView.frame.height)
        
        // Устанавливаем размер через SnapKit
        cropGridView.snp.remakeConstraints { make in
            make.center.equalTo(imageView)
            make.width.equalTo(maxWidth)
            make.height.equalTo(maxHeight)
        }
        
        view.layoutIfNeeded()
        print("CropGridView frame set to: \(cropGridView.frame)")
        
        // Проверяем, что финальная рамка не выходит за границы
        let finalFrame = cropGridView.frame
        let imageFrame = imageView.frame
        if !imageFrame.contains(finalFrame) {
            print("Warning: CropGrid frame \(finalFrame) exceeds image frame \(imageFrame)")
        }
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.image
            .asObservable()
            .subscribe(onNext: { [weak self] image in
                guard let self = self, let image = image else { return }
                
                // Сохраняем оригинальное изображение
                self.originalImage = image
                
                // Вывод оригинального разрешения в пикселях:
                print("Original image resolution: \(image.size.width * image.scale) x \(image.size.height * image.scale)")
                
                self.imageView.image = image
                
                // Обновляем ограничения imageView для сохранения соотношения сторон:
                self.imageView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(self.photoContainerView.snp.width)
                    let aspectRatio = image.size.height / image.size.width
                    make.height.equalTo(self.photoContainerView.snp.width).multipliedBy(aspectRatio)
                }
                
                self.view.layoutIfNeeded()
                
                // Обновляем размеры cropGridView чтобы покрыть весь imageView
                self.updateCropGridViewConstraints()
                
                // Создаем и позиционируем маркеры
                self.setupCropHandles()
                
                // Генерируем превью фильтров
                self.generateFilterPreviews()
            })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.editingCompletion?(nil) // Возвращаем nil при отмене
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                guard let self = self else { return }
                print("Save button tapped")
                
                // Создаем обрезанное изображение
                var finalImage = self.createCroppedImage()
                
                // Применяем текущий фильтр к обрезанному изображению
                if self.currentFilterType != .none, let croppedImage = finalImage {
                    finalImage = self.filtersManager.applyFilter(self.currentFilterType, to: croppedImage)
                }
                
                self.editingCompletion?(finalImage)
                self.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Gesture Recognizers Setup
    private func setupGestureRecognizers() {
        imageView.isUserInteractionEnabled = true
        
        // Добавляем стандартный pinch gesture для масштабирования.
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        // Добавляем стандартный rotation gesture для вращения.
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        imageView.addGestureRecognizer(pinchGesture)
        imageView.addGestureRecognizer(rotationGesture)
        
        // Добавляем жест перетягивания для cropDragView
        let cropDragGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropDrag(_:)))
        cropDragGesture.delegate = self
        cropDragView.addGestureRecognizer(cropDragGesture)
        
        // Жесты теперь обрабатываются отдельными маркерами
    }
    
    // MARK: - Gesture Handlers
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let imageView = gesture.view else { return }
        if gesture.state == .changed || gesture.state == .ended {
            imageView.transform = imageView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
            gesture.scale = 1.0
        }
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let imageView = gesture.view else { return }
        if gesture.state == .changed || gesture.state == .ended {
            imageView.transform = imageView.transform.rotated(by: gesture.rotation)
            gesture.rotation = 0.0
        }
    }
    
    @objc private func handleCropDrag(_ gesture: UIPanGestureRecognizer) {
        // Проверяем, что перетягивание доступно
        guard cropDragView.isUserInteractionEnabled else {
            print("Crop drag disabled - crop too small")
            return
        }
        
        let translation = gesture.translation(in: photoContainerView)
        
        // Получаем актуальные границы изображения с учетом трансформаций
        let imageViewBounds = imageView.bounds
        let actualImageFrame = photoContainerView.convert(imageViewBounds, from: imageView)
        
        switch gesture.state {
        case .began:
            print("Crop drag began")
            isDraggingCrop = true
            cropDragStartFrame = cropGridView.frame
            debugCropState()
            
            // Анимируем увеличение индикатора при начале перетягивания
            UIView.animate(withDuration: 0.2) {
                self.cropDragView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.cropDragView.alpha = 0.8
            }
            
        case .changed:
            guard let startFrame = cropDragStartFrame else { return }
            
            // Вычисляем новую позицию кропа
            var newFrame = startFrame
            newFrame.origin.x = startFrame.origin.x + translation.x
            newFrame.origin.y = startFrame.origin.y + translation.y
            
            // Дополнительная проверка границ изображения
            guard actualImageFrame.width > 0 && actualImageFrame.height > 0 else {
                print("[Crop Drag] Invalid image frame: \(actualImageFrame)")
                return
            }
            
            // Ограничиваем новую позицию границами изображения
            let constrainedFrame = validateAndConstrainCropFrame(newFrame, withinImageFrame: actualImageFrame)
            
            // Проверяем, была ли позиция ограничена (для обратной связи)
            let wasConstrained = constrainedFrame != newFrame
            if wasConstrained {
                print("[Crop Drag] Position constrained: attempted \(newFrame), result \(constrainedFrame)")
                
                // Визуальная обратная связь при достижении границ
                provideBoundaryFeedback()
            }
            
            // Обновляем позицию cropGridView
            cropGridView.snp.remakeConstraints { make in
                make.left.equalTo(photoContainerView).offset(constrainedFrame.origin.x)
                make.top.equalTo(photoContainerView).offset(constrainedFrame.origin.y)
                make.width.equalTo(constrainedFrame.width)
                make.height.equalTo(constrainedFrame.height)
            }
            
            // Принудительно обновляем layout
            view.layoutIfNeeded()
            
            // Обновляем cropDragView чтобы он следовал за cropGridView
            cropDragView.snp.remakeConstraints { make in
                make.edges.equalTo(cropGridView)
            }
            
            // Обновляем CropOverlayView
            let cropRectInView = photoContainerView.convert(cropGridView.frame, to: view)
            cropOverlayView.cropRect = cropRectInView
            
            // Обновляем позиции хендлов
            updateCropHandlesPositions()
            
        case .ended, .cancelled:
            print("Crop drag ended")
            isDraggingCrop = false
            cropDragStartFrame = nil
            lastBoundaryFeedbackTime = 0 // Сбрасываем таймер обратной связи
            
            // Анимируем возврат индикатора к исходному размеру
            UIView.animate(withDuration: 0.2) {
                self.cropDragView.transform = CGAffineTransform.identity
                self.cropDragView.alpha = 1.0
            }
            
        default:
            break
        }
    }
    
    // Старый метод обработки жестов удален - теперь используем отдельные маркеры
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Для жестов маркеров обрезки - не разрешаем одновременное выполнение
        if gestureRecognizer.view is CropHandleView && otherGestureRecognizer.view is CropHandleView {
            return false
        }
        
        // Не разрешаем одновременное выполнение жеста перетягивания кропа с жестами маркеров
        if (gestureRecognizer.view === cropDragView && otherGestureRecognizer.view is CropHandleView) ||
           (gestureRecognizer.view is CropHandleView && otherGestureRecognizer.view === cropDragView) {
            return false
        }
        
        // Для остальных жестов разрешаем одновременное распознавание
        return true
    }
    
    func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        // Если есть активный жест маркера, блокируем другие жесты маркеров
        if gestureRecognizer.view is CropHandleView && currentGestureHandle != nil {
            return gestureRecognizer.view === currentGestureHandle
        }
        
        // Если перетягиваем кроп, блокируем жесты маркеров
        if gestureRecognizer.view is CropHandleView && isDraggingCrop {
            return false
        }
        
        // Если есть активный жест маркера, блокируем перетягивание кропа
        if gestureRecognizer.view === cropDragView && currentGestureHandle != nil {
            return false
        }
        
        return true
    }
}

// MARK: - Crop Handles Management
extension PhotoEditorViewController {
    private func setupCropHandles() {
        print("Setting up crop handles")
        
        // Удаляем старые маркеры
        cropHandles.forEach { $0.removeFromSuperview() }
        cropHandles.removeAll()
        
        // Создаем угловые маркеры
        let cornerPositions: [CropHandleView.Position] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        for position in cornerPositions {
            let handle = CropHandleView(type: .corner, position: position)
            view.addSubview(handle) // Добавляем на главный view для z-index
            cropHandles.append(handle)
            
            // Добавляем жест
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropHandlePan(_:)))
            panGesture.delegate = self
            handle.addGestureRecognizer(panGesture)
            print("Created corner handle: \(position)")
        }
        
        // Создаем боковые маркеры
        let edgePositions: [CropHandleView.Position] = [.top, .bottom, .left, .right]
        for position in edgePositions {
            let handle = CropHandleView(type: .edge, position: position)
            view.addSubview(handle) // Добавляем на главный view для z-index
            cropHandles.append(handle)
            
            // Добавляем жест
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropHandlePan(_:)))
            panGesture.delegate = self
            handle.addGestureRecognizer(panGesture)
            print("Created edge handle: \(position)")
        }
        
        print("Total handles created: \(cropHandles.count)")
        
        // Проверяем, что cropGridView имеет валидный фрейм перед позиционированием хендлов
        DispatchQueue.main.async {
            // Даем время Auto Layout для вычисления позиций
            if self.cropGridView.frame.width > 0 && self.cropGridView.frame.height > 0 {
                self.updateCropHandlesPositions()
            } else {
                print("Warning: CropGridView has invalid frame, delaying handle positioning")
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                    self.updateCropHandlesPositions()
                }
            }
        }
    }
    
    /// Валидирует и корректирует фрейм кропа, чтобы он не выходил за границы изображения
    private func validateAndConstrainCropFrame(_ frame: CGRect, withinImageFrame imageFrame: CGRect) -> CGRect {
        let minSize: CGFloat = 50.0
        
        // Проверяем, что imageFrame валиден
        guard imageFrame.width > 0 && imageFrame.height > 0 else {
            print("[Frame Validation] Invalid image frame: \(imageFrame)")
            return frame
        }
        
        // Ограничиваем размеры минимальными и максимальными значениями
        let validWidth = max(minSize, min(frame.width, imageFrame.width))
        let validHeight = max(minSize, min(frame.height, imageFrame.height))
        
        // Ограничиваем позицию границами изображения с учетом размеров кропа
        let validX = max(imageFrame.minX, min(frame.origin.x, imageFrame.maxX - validWidth))
        let validY = max(imageFrame.minY, min(frame.origin.y, imageFrame.maxY - validHeight))
        
        let validFrame = CGRect(x: validX, y: validY, width: validWidth, height: validHeight)
        
        // Дополнительная проверка: убеждаемся, что весь кроп находится внутри изображения
        let containedFrame = CGRect(
            x: max(imageFrame.minX, min(validFrame.minX, imageFrame.maxX - validFrame.width)),
            y: max(imageFrame.minY, min(validFrame.minY, imageFrame.maxY - validFrame.height)),
            width: min(validFrame.width, imageFrame.width),
            height: min(validFrame.height, imageFrame.height)
        )
        
        if containedFrame != frame {
            print("[Frame Validation] Corrected frame from \(frame) to \(containedFrame)")
            print("[Frame Validation] Image bounds: \(imageFrame)")
            print("[Frame Validation] Corrections applied:")
            if containedFrame.origin.x != frame.origin.x {
                print("  - X position: \(frame.origin.x) → \(containedFrame.origin.x)")
            }
            if containedFrame.origin.y != frame.origin.y {
                print("  - Y position: \(frame.origin.y) → \(containedFrame.origin.y)")
            }
            if containedFrame.width != frame.width {
                print("  - Width: \(frame.width) → \(containedFrame.width)")
            }
            if containedFrame.height != frame.height {
                print("  - Height: \(frame.height) → \(containedFrame.height)")
            }
        }
        
        return containedFrame
    }
    
    /// Отладочный метод для проверки состояния кропа
    private func debugCropState() {
        let cropFrame = cropGridView.frame
        let imageFrame = imageView.frame
        let containerBounds = photoContainerView.bounds
        
        print("=== CROP DEBUG STATE ===")
        print("CropGrid frame: \(cropFrame)")
        print("ImageView frame: \(imageFrame)")
        print("Container bounds: \(containerBounds)")
        print("Handles count: \(cropHandles.count)")
        print("Active gesture handle: \(currentGestureHandle?.position.debugDescription ?? "none")")
        print("Is dragging crop: \(isDraggingCrop)")
        print("Crop drag start frame: \(String(describing: cropDragStartFrame))")
        
        // Проверяем текущие позиции хендлов
        for handle in cropHandles {
            print("Handle \(handle.position.debugDescription) at: \(handle.center)")
        }
        
        // Проверяем cropFrameInView
        let cropFrameInView = photoContainerView.convert(cropFrame, to: view)
        print("CropFrame in view coordinates: \(cropFrameInView)")
        print("========================")
    }
    
    /// Предоставляет визуальную обратную связь при достижении границ изображения
    private func provideBoundaryFeedback() {
        let currentTime = Date().timeIntervalSince1970
        
        // Ограничиваем частоту тактильной обратной связи (не чаще чем раз в 0.2 секунды)
        if currentTime - lastBoundaryFeedbackTime > 0.2 {
            // Легкая вибрация для тактильной обратной связи
            let impactFeedback = UIImpactFeedbackGenerator(style: .light)
            impactFeedback.impactOccurred()
            lastBoundaryFeedbackTime = currentTime
            
            print("[Boundary Feedback] Haptic feedback provided")
        }
        
        // Кратковременная анимация cropDragView для визуальной обратной связи
        UIView.animate(withDuration: 0.1, animations: {
            self.cropDragView.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }) { _ in
            UIView.animate(withDuration: 0.1) {
                self.cropDragView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
            }
        }
    }
    
    /// Принудительно переставляет хендлы на правильные позиции
    private func repositionHandlesDirectly() {
        let cropFrame = cropGridView.frame
        let offset: CGFloat = 15
        
        guard cropFrame.width > 0 && cropFrame.height > 0 else {
            print("Cannot reposition handles - invalid crop frame: \(cropFrame)")
            return
        }
        
        let cropFrameInView = photoContainerView.convert(cropFrame, to: view)
        print("🔄 Repositioning handles based on cropFrameInView: \(cropFrameInView)")
        
        // Получаем границы основного view с учетом safe area
        let safeArea = view.safeAreaInsets
        let viewBounds = CGRect(
            x: safeArea.left,
            y: safeArea.top,
            width: view.bounds.width - safeArea.left - safeArea.right,
            height: view.bounds.height - safeArea.top - safeArea.bottom
        )
        
        for handle in cropHandles {
            var targetCenter: CGPoint
            
            switch handle.position {
            case .topLeft:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.minY - offset)
            case .topRight:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.minY - offset)
            case .bottomLeft:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.maxY + offset)
            case .bottomRight:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.maxY + offset)
            case .top:
                targetCenter = CGPoint(x: cropFrameInView.midX, y: cropFrameInView.minY - offset)
            case .bottom:
                targetCenter = CGPoint(x: cropFrameInView.midX, y: cropFrameInView.maxY + offset)
            case .left:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.midY)
            case .right:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.midY)
            }
            
            // Ограничиваем позицию хендла границами view
            let handleSize = handle.frame.size
            let minX = viewBounds.minX + handleSize.width / 2
            let maxX = viewBounds.maxX - handleSize.width / 2
            let minY = viewBounds.minY + handleSize.height / 2
            let maxY = viewBounds.maxY - handleSize.height / 2
            
            let constrainedCenter = CGPoint(
                x: max(minX, min(maxX, targetCenter.x)),
                y: max(minY, min(maxY, targetCenter.y))
            )
            
            // Принудительно обновляем позицию хендла
            handle.center = constrainedCenter
            print("🔄 Fixed handle \(handle.position.debugDescription) at: \(constrainedCenter)")
        }
    }
    
    private func updateCropHandlesPositions() {
        // Предотвращаем множественные одновременные обновления
        guard !isUpdatingHandlePositions else {
            print("⚠️ Skipping handle update - already in progress")
            return
        }
        
        isUpdatingHandlePositions = true
        defer { isUpdatingHandlePositions = false }
        
        let cropFrame = cropGridView.frame
        let offset: CGFloat = 15 // Смещение маркеров от края рамки
        
        // Проверяем что рамка имеет нормальные размеры
        guard cropFrame.width > 0 && cropFrame.height > 0 else {
            print("cropFrame is empty: \(cropFrame)")
            return
        }
        
        // Конвертируем координаты cropGridView в координаты главного view
        let cropFrameInView = photoContainerView.convert(cropFrame, to: view)
        print("Updating handle positions for cropFrame: \(cropFrame), in view: \(cropFrameInView)")
        
        // Дополнительная проверка согласованности размеров
        let expectedWidth = cropFrameInView.width
        let expectedHeight = cropFrameInView.height
        print("Expected crop size: \(expectedWidth) x \(expectedHeight)")
        
        // Ожидаемый размах хендлов (crop + offset с каждой стороны)
        let expectedHandleSpreadWidth = expectedWidth + (offset * 2)
        let expectedHandleSpreadHeight = expectedHeight + (offset * 2)
        print("Expected handle spread: \(expectedHandleSpreadWidth) x \(expectedHandleSpreadHeight)")
        
        // Получаем границы основного view с учетом safe area
        let safeArea = view.safeAreaInsets
        let viewBounds = CGRect(
            x: safeArea.left,
            y: safeArea.top,
            width: view.bounds.width - safeArea.left - safeArea.right,
            height: view.bounds.height - safeArea.top - safeArea.bottom
        )
        
        for handle in cropHandles {
            var targetCenter: CGPoint
            
            switch handle.position {
            case .topLeft:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.minY - offset)
            case .topRight:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.minY - offset)
            case .bottomLeft:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.maxY + offset)
            case .bottomRight:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.maxY + offset)
            case .top:
                targetCenter = CGPoint(x: cropFrameInView.midX, y: cropFrameInView.minY - offset)
            case .bottom:
                targetCenter = CGPoint(x: cropFrameInView.midX, y: cropFrameInView.maxY + offset)
            case .left:
                targetCenter = CGPoint(x: cropFrameInView.minX - offset, y: cropFrameInView.midY)
            case .right:
                targetCenter = CGPoint(x: cropFrameInView.maxX + offset, y: cropFrameInView.midY)
            }
            
            // Ограничиваем позицию хендла границами view
            let handleSize = handle.frame.size
            let minX = viewBounds.minX + handleSize.width / 2
            let maxX = viewBounds.maxX - handleSize.width / 2
            let minY = viewBounds.minY + handleSize.height / 2
            let maxY = viewBounds.maxY - handleSize.height / 2
            
            let constrainedCenter = CGPoint(
                x: max(minX, min(maxX, targetCenter.x)),
                y: max(minY, min(maxY, targetCenter.y))
            )
            
            handle.center = constrainedCenter
            
            // Логгируем если позиция была ограничена
            if constrainedCenter != targetCenter {
                print("Handle \(handle.position) constrained from \(targetCenter) to \(constrainedCenter)")
            } else {
                print("Handle \(handle.position) positioned at: \(constrainedCenter)")
            }
        }
        
        // Проверяем согласованность позиций хендлов
        if cropHandles.count >= 4 {
            let topLeftHandle = cropHandles.first(where: { $0.position == .topLeft })
            let topRightHandle = cropHandles.first(where: { $0.position == .topRight })
            let bottomLeftHandle = cropHandles.first(where: { $0.position == .bottomLeft })
            let bottomRightHandle = cropHandles.first(where: { $0.position == .bottomRight })
            
            if let topLeft = topLeftHandle, let topRight = topRightHandle,
               let bottomLeft = bottomLeftHandle, let _ = bottomRightHandle {
                let actualWidth = topRight.center.x - topLeft.center.x
                let actualHeight = bottomLeft.center.y - topLeft.center.y
                print("Actual handle spread: \(actualWidth) x \(actualHeight)")
                
                if abs(actualWidth - expectedHandleSpreadWidth) > 5 || abs(actualHeight - expectedHandleSpreadHeight) > 5 {
                    print("⚠️ WARNING: Handle positions don't match expected spread!")
                    print("  Expected spread: \(expectedHandleSpreadWidth) x \(expectedHandleSpreadHeight)")
                    print("  Actual spread: \(actualWidth) x \(actualHeight)")
                    print("  Crop frame in container: \(cropFrame)")
                    print("  Crop frame in view: \(cropFrameInView)")
                    print("  Offset used: \(offset)")
                }
            }
        }
        
        // Обновляем позицию cropDragView, чтобы она следовала за cropGridView (только центральная часть)
        let currentCropFrame = cropGridView.frame
        let minDragSize: CGFloat = 40 // Минимальный размер для перетягивания
        
        if currentCropFrame.width > 80 && currentCropFrame.height > 80 {
            // Кроп достаточно большой для перетягивания
            cropDragView.snp.remakeConstraints { make in
                make.center.equalTo(cropGridView)
                make.width.equalTo(cropGridView).offset(-60)
                make.height.equalTo(cropGridView).offset(-60)
            }
            cropDragView.isUserInteractionEnabled = true
            cropDragView.alpha = 1.0
        } else {
            // Кроп слишком маленький - отключаем перетягивание
            cropDragView.snp.remakeConstraints { make in
                make.center.equalTo(cropGridView)
                make.width.equalTo(minDragSize)
                make.height.equalTo(minDragSize)
            }
            cropDragView.isUserInteractionEnabled = false
            cropDragView.alpha = 0.3 // Делаем полупрозрачным
        }
    }
    
    @objc private func handleCropHandlePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CropHandleView else { 
            print("No handle found in gesture")
            return 
        }
        
        let translation = gesture.translation(in: view)
        let imageFrame = photoContainerView.convert(imageView.frame, to: view)
        let minCropSize: CGFloat = 100.0
        
        switch gesture.state {
        case .began:
            print("Gesture began on handle: \(handle.position)")
            debugCropState()
            // Всегда сохраняем текущее состояние при начале нового жеста
            initialCropFrame = cropGridView.frame
            currentGestureHandle = handle
            print("Initial crop frame: \(String(describing: initialCropFrame))")
            print("Previous gesture handle was: \(currentGestureHandle?.position.debugDescription ?? "none")")
            
        case .changed:
            guard let initialFrame = initialCropFrame,
                  currentGestureHandle == handle else { return }
            
            // Конвертируем initialFrame в координаты view для вычислений
            let initialFrameInView = photoContainerView.convert(initialFrame, to: view)
            var newFrameInView = initialFrameInView
            
            // Проверяем, что imageFrame корректен
            guard imageFrame.width > 0 && imageFrame.height > 0 else {
                print("[Gesture Debug] Invalid image frame: \(imageFrame)")
                return
            }
            
            switch handle.position {
            case .topLeft:
                let deltaX = translation.x
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // Определяем, какое изменение больше
                    let widthChange = abs(deltaX) / initialFrameInView.width
                    let heightChange = abs(deltaY) / initialFrameInView.height
                    
                    if widthChange >= heightChange {
                        // Изменяем по ширине
                        let newX = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                        let newWidth = initialFrameInView.maxX - newX
                        let newHeight = newWidth / ratio
                        
                        newFrameInView.origin.x = newX
                        newFrameInView.size.width = newWidth
                        newFrameInView.size.height = newHeight
                        newFrameInView.origin.y = initialFrameInView.maxY - newHeight
                        
                        // Проверяем границы по высоте
                        if newFrameInView.origin.y < imageFrame.origin.y {
                            newFrameInView.origin.y = imageFrame.origin.y
                            newFrameInView.size.height = initialFrameInView.maxY - newFrameInView.origin.y
                            newFrameInView.size.width = newFrameInView.size.height * ratio
                            newFrameInView.origin.x = initialFrameInView.maxX - newFrameInView.size.width
                        }
                    } else {
                        // Изменяем по высоте
                        let newY = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                        let newHeight = initialFrameInView.maxY - newY
                        let newWidth = newHeight * ratio
                        
                        newFrameInView.origin.y = newY
                        newFrameInView.size.height = newHeight
                        newFrameInView.size.width = newWidth
                        newFrameInView.origin.x = initialFrameInView.maxX - newWidth
                        
                        // Проверяем границы по ширине
                        if newFrameInView.origin.x < imageFrame.origin.x {
                            newFrameInView.origin.x = imageFrame.origin.x
                            newFrameInView.size.width = initialFrameInView.maxX - newFrameInView.origin.x
                            newFrameInView.size.height = newFrameInView.size.width / ratio
                            newFrameInView.origin.y = initialFrameInView.maxY - newFrameInView.size.height
                        }
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.origin.x = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                    newFrameInView.origin.y = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                    newFrameInView.size.width = initialFrameInView.maxX - newFrameInView.origin.x
                    newFrameInView.size.height = initialFrameInView.maxY - newFrameInView.origin.y
                }
                
            case .topRight:
                let deltaX = translation.x
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // Сохраняем соотношение сторон
                    let newY = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                    let newWidth = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                    let newHeight = initialFrameInView.maxY - newY
                    
                    // Определяем ограничивающий фактор
                    let widthBasedHeight = newWidth / ratio
                    let heightBasedWidth = newHeight * ratio
                    
                    if widthBasedHeight <= newHeight {
                        // Ограничиваем по ширине
                        newFrameInView.size.width = newWidth
                        newFrameInView.size.height = widthBasedHeight
                        newFrameInView.origin.y = initialFrameInView.maxY - newFrameInView.size.height
                    } else {
                        // Ограничиваем по высоте
                        newFrameInView.origin.y = newY
                        newFrameInView.size.height = newHeight
                        newFrameInView.size.width = heightBasedWidth
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.origin.y = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                    newFrameInView.size.width = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                    newFrameInView.size.height = initialFrameInView.maxY - newFrameInView.origin.y
                }
                
            case .bottomLeft:
                let deltaX = translation.x
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // Сохраняем соотношение сторон
                    let newX = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                    let newWidth = initialFrameInView.maxX - newX
                    let newHeight = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                    
                    // Определяем ограничивающий фактор
                    let widthBasedHeight = newWidth / ratio
                    let heightBasedWidth = newHeight * ratio
                    
                    if widthBasedHeight <= newHeight {
                        // Ограничиваем по ширине
                        newFrameInView.origin.x = newX
                        newFrameInView.size.width = newWidth
                        newFrameInView.size.height = widthBasedHeight
                    } else {
                        // Ограничиваем по высоте
                        newFrameInView.size.height = newHeight
                        newFrameInView.size.width = heightBasedWidth
                        newFrameInView.origin.x = initialFrameInView.maxX - newFrameInView.size.width
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.origin.x = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                    newFrameInView.size.width = initialFrameInView.maxX - newFrameInView.origin.x
                    newFrameInView.size.height = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                }
                
            case .bottomRight:
                let deltaX = translation.x
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // Сохраняем соотношение сторон - используем наибольшее изменение
                    let potentialWidth = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                    let potentialHeight = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                    
                    // Определяем, какое изменение больше относительно исходного размера
                    let widthChange = abs(deltaX) / initialFrameInView.width
                    let heightChange = abs(deltaY) / initialFrameInView.height
                    
                    if widthChange >= heightChange {
                        // Изменяем по ширине, высота следует за соотношением
                        newFrameInView.size.width = potentialWidth
                        newFrameInView.size.height = potentialWidth / ratio
                        
                        // Проверяем границы по высоте
                        if newFrameInView.size.height > imageFrame.maxY - initialFrameInView.origin.y {
                            newFrameInView.size.height = imageFrame.maxY - initialFrameInView.origin.y
                            newFrameInView.size.width = newFrameInView.size.height * ratio
                        }
                    } else {
                        // Изменяем по высоте, ширина следует за соотношением
                        newFrameInView.size.height = potentialHeight
                        newFrameInView.size.width = potentialHeight * ratio
                        
                        // Проверяем границы по ширине
                        if newFrameInView.size.width > imageFrame.maxX - initialFrameInView.origin.x {
                            newFrameInView.size.width = imageFrame.maxX - initialFrameInView.origin.x
                            newFrameInView.size.height = newFrameInView.size.width / ratio
                        }
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.size.width = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                    newFrameInView.size.height = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                }
                
            case .left:
                let deltaX = translation.x
                
                if let ratio = currentAspectRatio.ratio {
                    // При фиксированном соотношении сторон боковые маркеры изменяют размер пропорционально
                    let newX = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                    let newWidth = initialFrameInView.maxX - newX
                    let newHeight = newWidth / ratio
                    
                    // Проверяем, что новая высота помещается в границы изображения
                    let maxHeight = imageFrame.height
                    if newHeight <= maxHeight {
                        newFrameInView.origin.x = newX
                        newFrameInView.size.width = newWidth
                        newFrameInView.size.height = newHeight
                        // Центрируем по вертикали относительно изображения
                        let centerY = imageFrame.midY
                        newFrameInView.origin.y = centerY - newHeight / 2
                        
                        // Корректируем если выходим за границы
                        if newFrameInView.origin.y < imageFrame.origin.y {
                            newFrameInView.origin.y = imageFrame.origin.y
                        } else if newFrameInView.maxY > imageFrame.maxY {
                            newFrameInView.origin.y = imageFrame.maxY - newHeight
                        }
                    } else {
                        // Ограничиваем по высоте
                        newFrameInView.size.height = maxHeight
                        newFrameInView.size.width = maxHeight * ratio
                        newFrameInView.origin.x = initialFrameInView.maxX - newFrameInView.size.width
                        newFrameInView.origin.y = imageFrame.origin.y
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.origin.x = max(imageFrame.origin.x, min(initialFrameInView.maxX - minCropSize, initialFrameInView.origin.x + deltaX))
                    newFrameInView.size.width = initialFrameInView.maxX - newFrameInView.origin.x
                }
                
            case .right:
                let deltaX = translation.x
                
                if let ratio = currentAspectRatio.ratio {
                    // При фиксированном соотношении сторон боковые маркеры изменяют размер пропорционально
                    let newWidth = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                    let newHeight = newWidth / ratio
                    
                    // Проверяем, что новая высота помещается в границы изображения
                    let maxHeight = imageFrame.height
                    if newHeight <= maxHeight {
                        newFrameInView.size.width = newWidth
                        newFrameInView.size.height = newHeight
                        // Центрируем по вертикали относительно изображения
                        let centerY = imageFrame.midY
                        newFrameInView.origin.y = centerY - newHeight / 2
                        
                        // Корректируем если выходим за границы
                        if newFrameInView.origin.y < imageFrame.origin.y {
                            newFrameInView.origin.y = imageFrame.origin.y
                        } else if newFrameInView.maxY > imageFrame.maxY {
                            newFrameInView.origin.y = imageFrame.maxY - newHeight
                        }
                    } else {
                        // Ограничиваем по высоте
                        newFrameInView.size.height = maxHeight
                        newFrameInView.size.width = maxHeight * ratio
                        newFrameInView.origin.y = imageFrame.origin.y
                    }
                } else {
                    // Произвольный формат
                    newFrameInView.size.width = max(minCropSize, min(imageFrame.maxX - initialFrameInView.origin.x, initialFrameInView.width + deltaX))
                }
                
            case .top:
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // При фиксированном соотношении сторон верхние/нижние маркеры изменяют размер пропорционально
                    let newY = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                    let newHeight = initialFrameInView.maxY - newY
                    let newWidth = newHeight * ratio
                    
                    newFrameInView.origin.y = newY
                    newFrameInView.size.height = newHeight
                    newFrameInView.size.width = newWidth
                    // Центрируем по горизонтали
                    newFrameInView.origin.x = initialFrameInView.midX - newWidth / 2
                } else {
                    // Произвольный формат
                    newFrameInView.origin.y = max(imageFrame.origin.y, min(initialFrameInView.maxY - minCropSize, initialFrameInView.origin.y + deltaY))
                    newFrameInView.size.height = initialFrameInView.maxY - newFrameInView.origin.y
                }
                
            case .bottom:
                let deltaY = translation.y
                
                if let ratio = currentAspectRatio.ratio {
                    // При фиксированном соотношении сторон верхние/нижние маркеры изменяют размер пропорционально
                    let newHeight = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                    let newWidth = newHeight * ratio
                    
                    newFrameInView.size.height = newHeight
                    newFrameInView.size.width = newWidth
                    // Центрируем по горизонтали
                    newFrameInView.origin.x = initialFrameInView.midX - newWidth / 2
                } else {
                    // Произвольный формат
                    newFrameInView.size.height = max(minCropSize, min(imageFrame.maxY - initialFrameInView.origin.y, initialFrameInView.height + deltaY))
                }
            }
            
            // Конвертируем обратно в координаты photoContainerView
            let newFrame = view.convert(newFrameInView, to: photoContainerView)
            
            // Получаем границы изображения в координатах photoContainerView
            let imageFrameInContainer = photoContainerView.convert(imageView.frame, from: imageView.superview)
            
            // Применяем валидацию к новому фрейму
            let constrainedFrame = validateAndConstrainCropFrame(newFrame, withinImageFrame: imageFrameInContainer)
            
            // Отладочная информация для проверки границ
            if constrainedFrame != newFrame {
                print("[Gesture Debug] Frame constrained from \(newFrame) to \(constrainedFrame)")
                print("[Gesture Debug] Image bounds: \(imageFrameInContainer)")
            }
            
            // Обновляем ограничения с ограниченными координатами
            cropGridView.snp.remakeConstraints { make in
                make.left.equalTo(photoContainerView).offset(constrainedFrame.origin.x)
                make.top.equalTo(photoContainerView).offset(constrainedFrame.origin.y)
                make.width.equalTo(constrainedFrame.width)
                make.height.equalTo(constrainedFrame.height)
            }
            
            // Принудительно обновляем layout
            view.layoutIfNeeded()
            
            // Обновляем cropDragView чтобы он следовал за cropGridView (только центральная часть)
            let currentCropFrame = cropGridView.frame
            let minDragSize: CGFloat = 40 // Минимальный размер для перетягивания
            
            if currentCropFrame.width > 80 && currentCropFrame.height > 80 {
                // Кроп достаточно большой для перетягивания
                cropDragView.snp.remakeConstraints { make in
                    make.center.equalTo(cropGridView)
                    make.width.equalTo(cropGridView).offset(-60)
                    make.height.equalTo(cropGridView).offset(-60)
                }
                cropDragView.isUserInteractionEnabled = true
                cropDragView.alpha = 1.0
            } else {
                // Кроп слишком маленький - отключаем перетягивание
                cropDragView.snp.remakeConstraints { make in
                    make.center.equalTo(cropGridView)
                    make.width.equalTo(minDragSize)
                    make.height.equalTo(minDragSize)
                }
                cropDragView.isUserInteractionEnabled = false
                cropDragView.alpha = 0.3 // Делаем полупрозрачным
            }
            
            // Дополнительно обновляем layout чтобы убедиться что все компоненты синхронизированы
            view.layoutIfNeeded()
            
            // Пересчитываем cropRect для overlay на основе обновленного cropGridView.frame
            let updatedCropRectInView = photoContainerView.convert(cropGridView.frame, to: view)
            cropOverlayView.cropRect = updatedCropRectInView
            
            // Обновляем позиции хендлов
            updateCropHandlesPositions()
            
        case .ended, .cancelled:
            // Сбрасываем состояние только для текущего активного жеста
            if currentGestureHandle == handle {
                print("Gesture ended on handle: \(handle.position)")
                
                // Дополнительно обновляем позиции хендлов при окончании жеста
                DispatchQueue.main.async {
                    self.updateCropHandlesPositions()
                }
                
                initialCropFrame = nil
                currentGestureHandle = nil
            }
            
        default:
            break
        }
    }
}

// MARK: - Crop Grid Touch Handling  
extension PhotoEditorViewController {
    // Старые методы больше не нужны - используем отдельные маркеры
}

// MARK: - Image Processing
extension PhotoEditorViewController {
    /// Создает обрезанное изображение на основе текущей позиции cropGridView
    private func createCroppedImage() -> UIImage? {
        guard let originalImage = imageView.image else { 
            print("No original image found")
            return nil 
        }
        
        print("[Crop Debug] Starting crop process")
        print("[Crop Debug] Original image size: \(originalImage.size)")
        print("[Crop Debug] ImageView frame: \(imageView.frame)")
        print("[Crop Debug] PhotoContainer bounds: \(photoContainerView.bounds)")
        print("[Crop Debug] CropGridView frame: \(cropGridView.frame)")
        
        // Находим видимую часть imageView (пересечение с photoContainerView)
        let visibleImageRect = imageView.frame.intersection(photoContainerView.bounds)
        print("[Crop Debug] Visible image rect: \(visibleImageRect)")
        
        // Проверяем, что есть видимая область
        guard !visibleImageRect.isEmpty else {
            print("[Crop Debug] No visible image area")
            return originalImage
        }
        
        // Получаем фрейм cropGridView в координатах photoContainerView
        let cropRect = cropGridView.frame
        print("[Crop Debug] Crop rect in container: \(cropRect)")
        
        // Вычисляем относительные координаты cropRect относительно видимой части изображения
        let relativeX = (cropRect.origin.x - visibleImageRect.origin.x) / visibleImageRect.width
        let relativeY = (cropRect.origin.y - visibleImageRect.origin.y) / visibleImageRect.height
        let relativeWidth = cropRect.width / visibleImageRect.width
        let relativeHeight = cropRect.height / visibleImageRect.height
        
        print("[Crop Debug] Relative to visible: x=\(relativeX), y=\(relativeY), w=\(relativeWidth), h=\(relativeHeight)")
        
        // Проверяем границы (crop должен быть внутри видимой области)
        guard relativeX >= 0 && relativeY >= 0 && 
              relativeX + relativeWidth <= 1.0 && relativeY + relativeHeight <= 1.0 else {
            print("[Crop Debug] Crop rect is outside visible bounds")
            return originalImage
        }
        
        // Теперь нужно вычислить, какая часть полного imageView является видимой
        let visibleRelativeToFullX = (visibleImageRect.origin.x - imageView.frame.origin.x) / imageView.frame.width
        let visibleRelativeToFullY = (visibleImageRect.origin.y - imageView.frame.origin.y) / imageView.frame.height
        let visibleRelativeToFullWidth = visibleImageRect.width / imageView.frame.width
        let visibleRelativeToFullHeight = visibleImageRect.height / imageView.frame.height
        
        print("[Crop Debug] Visible relative to full image: x=\(visibleRelativeToFullX), y=\(visibleRelativeToFullY), w=\(visibleRelativeToFullWidth), h=\(visibleRelativeToFullHeight)")
        
        // Финальные координаты в полном изображении
        let finalRelativeX = visibleRelativeToFullX + (relativeX * visibleRelativeToFullWidth)
        let finalRelativeY = visibleRelativeToFullY + (relativeY * visibleRelativeToFullHeight)
        let finalRelativeWidth = relativeWidth * visibleRelativeToFullWidth
        let finalRelativeHeight = relativeHeight * visibleRelativeToFullHeight
        
        print("[Crop Debug] Final relative coordinates: x=\(finalRelativeX), y=\(finalRelativeY), w=\(finalRelativeWidth), h=\(finalRelativeHeight)")
        
        // Переводим в координаты исходного изображения
        let imageSize = originalImage.size
        let cropX = max(0, finalRelativeX * imageSize.width)
        let cropY = max(0, finalRelativeY * imageSize.height)
        let cropWidth = min(imageSize.width - cropX, finalRelativeWidth * imageSize.width)
        let cropHeight = min(imageSize.height - cropY, finalRelativeHeight * imageSize.height)
        
        // Создаем CGRect для обрезки
        let cgCropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        print("[Crop Debug] Final crop rect: \(cgCropRect)")
        
        // Обрезаем изображение
        guard let cgImage = originalImage.cgImage?.cropping(to: cgCropRect) else { 
            print("[Crop Debug] Failed to crop image")
            return originalImage
        }
        
        // Создаем новое UIImage
        let croppedImage = UIImage(cgImage: cgImage, scale: originalImage.scale, orientation: originalImage.imageOrientation)
        print("[Crop Debug] Successfully cropped image to size: \(croppedImage.size)")
        return croppedImage
    }
}

// MARK: - Filters
extension PhotoEditorViewController {
    private func setupFiltersCollection() {
        filtersCollectionView.delegate = self
        filtersCollectionView.dataSource = self
    }
    
    private func generateFilterPreviews() {
        guard let originalImage = originalImage else { return }
        
        filtersManager.generateFilterPreviews(for: originalImage) { [weak self] previews in
            self?.filterPreviews = previews
            self?.filtersCollectionView.reloadData()
        }
    }
    
    private func applyFilter(_ filterType: ImageFiltersManager.FilterType) {
        guard let originalImage = originalImage else { return }
        
        currentFilterType = filterType
        
        // Сохраняем текущее состояние кропа перед применением фильтра
        let currentCropFrame = cropGridView.frame
        
        if filterType == .none {
            imageView.image = originalImage
        } else {
            if let filteredImage = filtersManager.applyFilter(filterType, to: originalImage) {
                imageView.image = filteredImage
            }
        }
        
        // Восстанавливаем состояние кропа после применения фильтра
        DispatchQueue.main.async {
            // Проверяем, что размеры не изменились критично
            if !currentCropFrame.isEmpty && abs(self.cropGridView.frame.width - currentCropFrame.width) > 10 {
                // Ограничиваем восстанавливаемый фрейм границами контейнера
                let containerBounds = self.photoContainerView.bounds
                let safeX = max(0, min(currentCropFrame.origin.x, containerBounds.width - currentCropFrame.width))
                let safeY = max(0, min(currentCropFrame.origin.y, containerBounds.height - currentCropFrame.height))
                
                // Восстанавливаем через SnapKit с безопасными координатами
                self.cropGridView.snp.remakeConstraints { make in
                    make.left.equalTo(self.photoContainerView).offset(safeX)
                    make.top.equalTo(self.photoContainerView).offset(safeY)
                    make.width.equalTo(currentCropFrame.width)
                    make.height.equalTo(currentCropFrame.height)
                }
                
                self.view.layoutIfNeeded()
                self.updateCropHandlesPositions()
                
                let cropRectInView = self.photoContainerView.convert(self.cropGridView.frame, to: self.view)
                self.cropOverlayView.cropRect = cropRectInView
            }
        }
    }
}

// MARK: - Aspect Ratio
extension PhotoEditorViewController {
    private func setupAspectRatioCollection() {
        aspectRatioCollectionView.delegate = self
        aspectRatioCollectionView.dataSource = self
    }
    
    private func applyAspectRatio(_ format: AspectRatioFormat) {
        currentAspectRatio = format
        
        // Сохраняем текущее положение и размер cropGridView
        let currentCropFrame = cropGridView.frame
        let currentCenter = cropGridView.center
        
        guard let ratio = format.ratio else {
            // Произвольный формат - не изменяем размер, только сбрасываем ограничения
            return
        }
        
        // Получаем размер контейнера
        let containerSize = photoContainerView.bounds.size
        let availableWidth = containerSize.width
        let availableHeight = containerSize.height
        
        var newWidth: CGFloat
        var newHeight: CGFloat
        
        // Если у нас уже есть текущий размер, пытаемся сохранить масштаб
        if !currentCropFrame.isEmpty {
            let currentArea = currentCropFrame.width * currentCropFrame.height
            
            // Вычисляем новые размеры с сохранением площади (если возможно)
            if ratio > 1.0 {
                // Ландшафтная ориентация
                newHeight = sqrt(currentArea / ratio)
                newWidth = newHeight * ratio
                
                // Проверяем границы
                if newWidth > availableWidth {
                    newWidth = availableWidth
                    newHeight = newWidth / ratio
                }
                if newHeight > availableHeight {
                    newHeight = availableHeight
                    newWidth = newHeight * ratio
                }
            } else {
                // Портретная ориентация или квадрат
                newWidth = sqrt(currentArea * ratio)
                newHeight = newWidth / ratio
                
                // Проверяем границы
                if newHeight > availableHeight {
                    newHeight = availableHeight
                    newWidth = newHeight * ratio
                }
                if newWidth > availableWidth {
                    newWidth = availableWidth
                    newHeight = newWidth / ratio
                }
            }
        } else {
            // Если нет текущего размера, используем стандартную логику
            if ratio > 1.0 {
                newWidth = min(availableWidth * 0.8, availableHeight * 0.8 * ratio)
                newHeight = newWidth / ratio
            } else {
                newHeight = min(availableHeight * 0.8, availableWidth * 0.8 / ratio)
                newWidth = newHeight * ratio
            }
        }
        
        // Вычисляем безопасную позицию
        let targetX = max(0, min(currentCenter.x - newWidth/2, containerSize.width - newWidth))
        let targetY = max(0, min(currentCenter.y - newHeight/2, containerSize.height - newHeight))
        
        // Отладочная информация для применения соотношения сторон
        print("[AspectRatio Debug] Applied \(format.rawValue): \(newWidth)x\(newHeight) at (\(targetX), \(targetY))")
        
        // Обновляем размер cropGridView с безопасной позицией
        cropGridView.snp.remakeConstraints { make in
            make.left.equalTo(photoContainerView).offset(targetX)
            make.top.equalTo(photoContainerView).offset(targetY)
            make.width.equalTo(newWidth)
            make.height.equalTo(newHeight)
        }
        
        // Принудительно обновляем layout без анимации для корректного позиционирования
        view.layoutIfNeeded()
        
        // Обновляем cropDragView чтобы он следовал за cropGridView
        let updatedCropFrame = cropGridView.frame
        if updatedCropFrame.width > 80 && updatedCropFrame.height > 80 {
            cropDragView.snp.remakeConstraints { make in
                make.center.equalTo(cropGridView)
                make.width.equalTo(cropGridView).offset(-60)
                make.height.equalTo(cropGridView).offset(-60)
            }
            cropDragView.isUserInteractionEnabled = true
            cropDragView.alpha = 1.0
        } else {
            cropDragView.snp.remakeConstraints { make in
                make.center.equalTo(cropGridView)
                make.width.equalTo(40)
                make.height.equalTo(40)
            }
            cropDragView.isUserInteractionEnabled = false
            cropDragView.alpha = 0.3
        }
        
        // Еще один layout update для синхронизации всех компонентов
        view.layoutIfNeeded()
        
        // Обновляем cropOverlayView на основе актуального фрейма
        let cropRectInView = photoContainerView.convert(cropGridView.frame, to: view)
        cropOverlayView.cropRect = cropRectInView
        
        // Обновляем позиции хендлов
        updateCropHandlesPositions()
        
        // Добавляем небольшую анимацию для плавности
        UIView.animate(withDuration: 0.2) {
            self.view.layoutIfNeeded()
        }
    }
}

// MARK: - UICollectionViewDataSource
extension PhotoEditorViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == aspectRatioCollectionView {
            return AspectRatioFormat.allCases.count
        } else {
            return ImageFiltersManager.FilterType.allCases.count
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == aspectRatioCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: AspectRatioCell.identifier, for: indexPath) as! AspectRatioCell
            
            let format = AspectRatioFormat.allCases[indexPath.item]
            cell.configure(with: format, isSelected: format == currentAspectRatio)
            
            return cell
        } else {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FilterCollectionViewCell.identifier, for: indexPath) as! FilterCollectionViewCell
            
            let filterType = ImageFiltersManager.FilterType.allCases[indexPath.item]
            let previewImage = filterPreviews[filterType]
            
            cell.configure(with: previewImage, title: filterType.displayName)
            cell.isSelected = (filterType == currentFilterType)
            
            return cell
        }
    }
}

// MARK: - UICollectionViewDelegate
extension PhotoEditorViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == aspectRatioCollectionView {
            let format = AspectRatioFormat.allCases[indexPath.item]
            applyAspectRatio(format)
            collectionView.reloadData() // Обновляем выделение
        } else {
            let filterType = ImageFiltersManager.FilterType.allCases[indexPath.item]
            applyFilter(filterType)
            collectionView.reloadData() // Обновляем выделение
        }
    }
}
