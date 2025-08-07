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
        button.setTitle("Отмена", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemGray
        button.layer.cornerRadius = 22
        return button
    }()
    
    private let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 22
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
        view.backgroundColor = .systemBackground
        
        // Добавляем верхний контейнер с заголовком
        let headerView = UIView()
        headerView.backgroundColor = .systemGray6
        headerView.layer.cornerRadius = 12
        view.addSubview(headerView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Редактор фотографий"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 20)
        titleLabel.textColor = .label
        headerView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = "Обрежьте и примените фильтры"
        subtitleLabel.font = UIFont.systemFont(ofSize: 14)
        subtitleLabel.textColor = .systemGray
        headerView.addSubview(subtitleLabel)
        
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(60)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.leading.trailing.equalToSuperview().inset(16)
        }
        
        // Добавляем CropOverlayView поверх всего экрана
        view.addSubview(cropOverlayView)
        cropOverlayView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Добавляем photoContainerView
        photoContainerView.backgroundColor = .black
        view.addSubview(photoContainerView)
        photoContainerView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(16)
            make.right.equalToSuperview().inset(16)
            make.top.equalTo(headerView.snp.bottom).offset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-200) // Оставляем место для элементов управления
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
            make.top.equalTo(photoContainerView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(50)
        }
        
        // Добавляем коллекцию фильтров
        view.addSubview(filtersCollectionView)
        filtersCollectionView.snp.makeConstraints { make in
            make.top.equalTo(aspectRatioCollectionView.snp.bottom).offset(10)
            make.left.right.equalToSuperview()
            make.height.equalTo(100)
        }
        
        // Добавляем кнопки
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.snp.makeConstraints { make in
            make.top.equalTo(filtersCollectionView.snp.bottom).offset(10)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide).inset(10)
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
        guard cropDragView.isUserInteractionEnabled else { return }
        
        let translation = gesture.translation(in: view)
        let imageFrameInView = photoContainerView.convert(imageView.frame, to: view)
        
        switch gesture.state {
        case .began:
            isDraggingCrop = true
            cropDragStartFrame = getCurrentCropRectInView()
            
            // Анимация начала перетягивания
            UIView.animate(withDuration: 0.2) {
                self.cropDragView.transform = CGAffineTransform(scaleX: 1.2, y: 1.2)
                self.cropDragView.alpha = 0.8
            }
            
        case .changed:
            guard let startRect = cropDragStartFrame else { return }
            
            // Вычисляем новую позицию
            var newRect = startRect
            newRect.origin.x = startRect.origin.x + translation.x
            newRect.origin.y = startRect.origin.y + translation.y
            
            // Ограничиваем границами изображения
            if newRect.minX < imageFrameInView.minX {
                newRect.origin.x = imageFrameInView.minX
                provideBoundaryFeedback()
            }
            if newRect.minY < imageFrameInView.minY {
                newRect.origin.y = imageFrameInView.minY
                provideBoundaryFeedback()
            }
            if newRect.maxX > imageFrameInView.maxX {
                newRect.origin.x = imageFrameInView.maxX - newRect.width
                provideBoundaryFeedback()
            }
            if newRect.maxY > imageFrameInView.maxY {
                newRect.origin.y = imageFrameInView.maxY - newRect.height
                provideBoundaryFeedback()
            }
            
            // Применяем новую позицию
            setCropRect(newRect, inView: true)
            
        case .ended, .cancelled:
            isDraggingCrop = false
            cropDragStartFrame = nil
            
            // Анимация окончания перетягивания
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
    
    /// Создает и настраивает хендлы для изменения размера области кропа
    private func setupCropHandles() {
        // Удаляем старые хендлы
        cropHandles.forEach { $0.removeFromSuperview() }
        cropHandles.removeAll()
        
        // Создаем новые хендлы для всех позиций
        let cornerPositions: [CropHandleView.Position] = [.topLeft, .topRight, .bottomLeft, .bottomRight]
        let edgePositions: [CropHandleView.Position] = [.top, .bottom, .left, .right]
        
        // Создаем угловые хендлы
        for position in cornerPositions {
            let handle = CropHandleView(type: .corner, position: position)
            view.addSubview(handle)
            cropHandles.append(handle)
            
            // Добавляем жест для каждого хендла
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropHandlePan(_:)))
            panGesture.delegate = self
            handle.addGestureRecognizer(panGesture)
        }
        
        // Создаем боковые хендлы
        for position in edgePositions {
            let handle = CropHandleView(type: .edge, position: position)
            view.addSubview(handle)
            cropHandles.append(handle)
            
            // Добавляем жест для каждого хендла
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropHandlePan(_:)))
            panGesture.delegate = self
            handle.addGestureRecognizer(panGesture)
        }
        
        // Устанавливаем начальные позиции хендлов
        updateCropHandlesPositions()
    }
    
    /// Обновляет позиции хендлов на основе текущей области кропа
    private func updateCropHandlesPositions() {
        // Предотвращаем множественные одновременные обновления
        guard !isUpdatingHandlePositions else {
            return
        }
        
        isUpdatingHandlePositions = true
        defer { isUpdatingHandlePositions = false }
        
        // Получаем текущую область кропа в координатах view
        let cropRect = getCurrentCropRectInView()
        let offset: CGFloat = 15
        
        // Получаем безопасные границы
        let safeArea = view.safeAreaInsets
        let viewBounds = CGRect(
            x: safeArea.left,
            y: safeArea.top,
            width: view.bounds.width - safeArea.left - safeArea.right,
            height: view.bounds.height - safeArea.top - safeArea.bottom
        )
        
        // Позиционируем каждый хендл
        for handle in cropHandles {
            let targetCenter = getHandleTargetCenter(for: handle.position, cropRect: cropRect, offset: offset)
            
            // Ограничиваем позицию границами экрана
            let handleSize = CGSize(width: 30, height: 30) // Размер хендла
            let constrainedCenter = CGPoint(
                x: max(viewBounds.minX + handleSize.width/2, min(viewBounds.maxX - handleSize.width/2, targetCenter.x)),
                y: max(viewBounds.minY + handleSize.height/2, min(viewBounds.maxY - handleSize.height/2, targetCenter.y))
            )
            
            handle.center = constrainedCenter
        }
        
        // Обновляем визуальную рамку
        cropOverlayView.cropRect = cropRect
    }
    
    /// Возвращает целевую позицию для хендла
    private func getHandleTargetCenter(for position: CropHandleView.Position, cropRect: CGRect, offset: CGFloat) -> CGPoint {
        switch position {
        case .topLeft:
            return CGPoint(x: cropRect.minX - offset, y: cropRect.minY - offset)
        case .topRight:
            return CGPoint(x: cropRect.maxX + offset, y: cropRect.minY - offset)
        case .bottomLeft:
            return CGPoint(x: cropRect.minX - offset, y: cropRect.maxY + offset)
        case .bottomRight:
            return CGPoint(x: cropRect.maxX + offset, y: cropRect.maxY + offset)
        case .top:
            return CGPoint(x: cropRect.midX, y: cropRect.minY - offset)
        case .bottom:
            return CGPoint(x: cropRect.midX, y: cropRect.maxY + offset)
        case .left:
            return CGPoint(x: cropRect.minX - offset, y: cropRect.midY)
        case .right:
            return CGPoint(x: cropRect.maxX + offset, y: cropRect.midY)
        }
    }
    
    /// Возвращает текущую область кропа в координатах главного view
    private func getCurrentCropRectInView() -> CGRect {
        // Если есть активная область кропа в cropGridView, используем её
        if !cropGridView.frame.isEmpty {
            return photoContainerView.convert(cropGridView.frame, to: view)
        }
        
        // Иначе используем всю видимую область изображения
        let imageFrame = photoContainerView.convert(imageView.frame, to: view)
        let containerFrame = photoContainerView.convert(photoContainerView.bounds, to: view)
        return imageFrame.intersection(containerFrame)
    }
    
    /// Устанавливает новую область кропа и обновляет все связанные элементы
    private func setCropRect(_ newRect: CGRect, inView: Bool = true) {
        let rectInContainer: CGRect
        
        if inView {
            // Конвертируем из координат view в координаты контейнера
            rectInContainer = view.convert(newRect, to: photoContainerView)
        } else {
            rectInContainer = newRect
        }
        
        // Обновляем cropGridView
        cropGridView.snp.remakeConstraints { make in
            make.left.equalTo(photoContainerView).offset(rectInContainer.origin.x)
            make.top.equalTo(photoContainerView).offset(rectInContainer.origin.y)
            make.width.equalTo(rectInContainer.width)
            make.height.equalTo(rectInContainer.height)
        }
        
        // Обновляем cropDragView
        updateCropDragView()
        
        // Принудительно обновляем layout
        view.layoutIfNeeded()
        
        // Обновляем позиции хендлов
        updateCropHandlesPositions()
    }
    
    /// Обновляет cropDragView для соответствия текущей области кропа
    private func updateCropDragView() {
        let currentCropFrame = cropGridView.frame
        
        if currentCropFrame.width > 80 && currentCropFrame.height > 80 {
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
    }
    
    @objc private func handleCropHandlePan(_ gesture: UIPanGestureRecognizer) {
        guard let handle = gesture.view as? CropHandleView else { return }
        
        let translation = gesture.translation(in: view)
        let imageFrameInView = photoContainerView.convert(imageView.frame, to: view)
        let minCropSize: CGFloat = 100.0
        
        switch gesture.state {
        case .began:
            // Сохраняем начальное состояние
            initialCropFrame = cropGridView.frame
            currentGestureHandle = handle
            
        case .changed:
            guard let initialFrame = initialCropFrame,
                  currentGestureHandle == handle else { return }
            
            // Получаем начальную область в координатах view
            let initialRectInView = photoContainerView.convert(initialFrame, to: view)
            var newRect = initialRectInView
            
            // Применяем изменения в зависимости от позиции хендла
            switch handle.position {
            case .topLeft:
                newRect.origin.x = max(imageFrameInView.minX, initialRectInView.minX + translation.x)
                newRect.origin.y = max(imageFrameInView.minY, initialRectInView.minY + translation.y)
                newRect.size.width = initialRectInView.maxX - newRect.origin.x
                newRect.size.height = initialRectInView.maxY - newRect.origin.y
                
            case .topRight:
                newRect.origin.y = max(imageFrameInView.minY, initialRectInView.minY + translation.y)
                newRect.size.width = max(minCropSize, min(imageFrameInView.maxX - initialRectInView.minX, initialRectInView.width + translation.x))
                newRect.size.height = initialRectInView.maxY - newRect.origin.y
                
            case .bottomLeft:
                newRect.origin.x = max(imageFrameInView.minX, initialRectInView.minX + translation.x)
                newRect.size.width = initialRectInView.maxX - newRect.origin.x
                newRect.size.height = max(minCropSize, min(imageFrameInView.maxY - initialRectInView.minY, initialRectInView.height + translation.y))
                
            case .bottomRight:
                newRect.size.width = max(minCropSize, min(imageFrameInView.maxX - initialRectInView.minX, initialRectInView.width + translation.x))
                newRect.size.height = max(minCropSize, min(imageFrameInView.maxY - initialRectInView.minY, initialRectInView.height + translation.y))
                
            case .top:
                newRect.origin.y = max(imageFrameInView.minY, initialRectInView.minY + translation.y)
                newRect.size.height = initialRectInView.maxY - newRect.origin.y
                
            case .bottom:
                newRect.size.height = max(minCropSize, min(imageFrameInView.maxY - initialRectInView.minY, initialRectInView.height + translation.y))
                
            case .left:
                newRect.origin.x = max(imageFrameInView.minX, initialRectInView.minX + translation.x)
                newRect.size.width = initialRectInView.maxX - newRect.origin.x
                
            case .right:
                newRect.size.width = max(minCropSize, min(imageFrameInView.maxX - initialRectInView.minX, initialRectInView.width + translation.x))
            }
            
            // Применяем ограничения по соотношению сторон если нужно
            if let ratio = currentAspectRatio.ratio {
                newRect = applyAspectRatioConstraint(to: newRect, ratio: ratio, imageFrame: imageFrameInView)
            }
            
            // Устанавливаем новую область кропа
            setCropRect(newRect, inView: true)
            
        case .ended, .cancelled:
            initialCropFrame = nil
            currentGestureHandle = nil
            
        default:
            break
        }
    }
    
    /// Применяет ограничения по соотношению сторон к области кропа
    private func applyAspectRatioConstraint(to rect: CGRect, ratio: CGFloat, imageFrame: CGRect) -> CGRect {
        var constrainedRect = rect
        
        // Определяем, какой размер ограничивает
        let widthBasedHeight = rect.width / ratio
        let heightBasedWidth = rect.height * ratio
        
        if widthBasedHeight <= rect.height {
            // Ограничиваем по ширине
            constrainedRect.size.height = widthBasedHeight
        } else {
            // Ограничиваем по высоте
            constrainedRect.size.width = heightBasedWidth
        }
        
        // Проверяем границы изображения
        if constrainedRect.maxX > imageFrame.maxX {
            constrainedRect.size.width = imageFrame.maxX - constrainedRect.minX
            constrainedRect.size.height = constrainedRect.width / ratio
        }
        
        if constrainedRect.maxY > imageFrame.maxY {
            constrainedRect.size.height = imageFrame.maxY - constrainedRect.minY
            constrainedRect.size.width = constrainedRect.height * ratio
        }
        
        return constrainedRect
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
        
        // Вычисляем фактический размер и позицию изображения внутри imageView с учетом contentMode .scaleAspectFit
        let actualImageRect = calculateActualImageRect(for: originalImage, in: imageView)
        print("[Crop Debug] Actual image rect in imageView: \(actualImageRect)")
        
        // Получаем фрейм cropGridView в координатах photoContainerView
        let cropRect = cropGridView.frame
        print("[Crop Debug] Crop rect in container: \(cropRect)")
        
        // Конвертируем cropRect в координаты imageView
        let cropRectInImageView = photoContainerView.convert(cropRect, to: imageView)
        print("[Crop Debug] Crop rect in imageView: \(cropRectInImageView)")
        
        // Вычисляем пересечение cropRect с реальной областью изображения
        let cropRectInActualImage = cropRectInImageView.intersection(actualImageRect)
        print("[Crop Debug] Crop rect intersected with actual image: \(cropRectInActualImage)")
        
        // Проверяем, что есть пересечение
        guard !cropRectInActualImage.isEmpty else {
            print("[Crop Debug] No intersection with actual image")
            return originalImage
        }
        
        // Вычисляем относительные координаты относительно фактического изображения
        let relativeX = (cropRectInActualImage.origin.x - actualImageRect.origin.x) / actualImageRect.width
        let relativeY = (cropRectInActualImage.origin.y - actualImageRect.origin.y) / actualImageRect.height
        let relativeWidth = cropRectInActualImage.width / actualImageRect.width
        let relativeHeight = cropRectInActualImage.height / actualImageRect.height
        
        print("[Crop Debug] Relative coordinates: x=\(relativeX), y=\(relativeY), w=\(relativeWidth), h=\(relativeHeight)")
        
        // Ограничиваем координаты от 0 до 1
        let clampedX = max(0, min(1, relativeX))
        let clampedY = max(0, min(1, relativeY))
        let clampedWidth = max(0, min(1 - clampedX, relativeWidth))
        let clampedHeight = max(0, min(1 - clampedY, relativeHeight))
        
        // Переводим в координаты исходного изображения
        let imageSize = originalImage.size
        let cropX = clampedX * imageSize.width
        let cropY = clampedY * imageSize.height
        let cropWidth = clampedWidth * imageSize.width
        let cropHeight = clampedHeight * imageSize.height
        
        // Создаем CGRect для обрезки
        let cgCropRect = CGRect(x: cropX, y: cropY, width: cropWidth, height: cropHeight)
        print("[Crop Debug] Final crop rect: \(cgCropRect)")
        
        // Проверяем валидность области обрезки
        guard cgCropRect.width > 0 && cgCropRect.height > 0 &&
              cgCropRect.maxX <= imageSize.width && cgCropRect.maxY <= imageSize.height else {
            print("[Crop Debug] Invalid crop rect")
            return originalImage
        }
        
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
    
    /// Вычисляет фактический прямоугольник изображения внутри imageView с учетом contentMode .scaleAspectFit
    private func calculateActualImageRect(for image: UIImage, in imageView: UIImageView) -> CGRect {
        let imageViewSize = imageView.bounds.size
        let imageSize = image.size
        
        // Вычисляем коэффициент масштабирования для scaleAspectFit
        let scaleX = imageViewSize.width / imageSize.width
        let scaleY = imageViewSize.height / imageSize.height
        let scale = min(scaleX, scaleY)
        
        // Вычисляем размер изображения после масштабирования
        let scaledImageSize = CGSize(
            width: imageSize.width * scale,
            height: imageSize.height * scale
        )
        
        // Вычисляем позицию изображения (центрирование)
        let imageOrigin = CGPoint(
            x: (imageViewSize.width - scaledImageSize.width) / 2,
            y: (imageViewSize.height - scaledImageSize.height) / 2
        )
        
        return CGRect(origin: imageOrigin, size: scaledImageSize)
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
        
        guard let ratio = format.ratio else {
            // Произвольный формат - не изменяем размер
            return
        }
        
        // Получаем текущую область кропа
        let currentCropRect = getCurrentCropRectInView()
        let imageFrameInView = photoContainerView.convert(imageView.frame, to: view)
        
        // Вычисляем новые размеры с сохранением центра
        var newRect = currentCropRect
        let currentArea = currentCropRect.width * currentCropRect.height
        
        if ratio > 1.0 {
            // Ландшафтная ориентация
            newRect.size.height = sqrt(currentArea / ratio)
            newRect.size.width = newRect.size.height * ratio
        } else {
            // Портретная ориентация или квадрат
            newRect.size.width = sqrt(currentArea * ratio)
            newRect.size.height = newRect.size.width / ratio
        }
        
        // Центрируем относительно текущей позиции
        newRect.origin.x = currentCropRect.midX - newRect.width / 2
        newRect.origin.y = currentCropRect.midY - newRect.height / 2
        
        // Ограничиваем границами изображения
        if newRect.minX < imageFrameInView.minX {
            newRect.origin.x = imageFrameInView.minX
        }
        if newRect.minY < imageFrameInView.minY {
            newRect.origin.y = imageFrameInView.minY
        }
        if newRect.maxX > imageFrameInView.maxX {
            newRect.origin.x = imageFrameInView.maxX - newRect.width
        }
        if newRect.maxY > imageFrameInView.maxY {
            newRect.origin.y = imageFrameInView.maxY - newRect.height
        }
        
        // Если не помещается, уменьшаем размер
        if newRect.width > imageFrameInView.width {
            newRect.size.width = imageFrameInView.width
            newRect.size.height = newRect.width / ratio
            newRect.origin.x = imageFrameInView.minX
        }
        if newRect.height > imageFrameInView.height {
            newRect.size.height = imageFrameInView.height
            newRect.size.width = newRect.height * ratio
            newRect.origin.y = imageFrameInView.minY
        }
        
        // Применяем новую область кропа
        setCropRect(newRect, inView: true)
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
