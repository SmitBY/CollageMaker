//
//  CollageEditorViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 31.01.2025.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa
import Photos
import PhotosUI

// MARK: - Aspect Ratio Model
struct AspectRatio {
    let id: String
    let name: String
    let ratio: CGFloat // width / height
    let width: Int
    let height: Int
    let displayName: String
    let isPopular: Bool
    
    init(id: String, name: String, width: Int, height: Int, displayName: String, isPopular: Bool = false) {
        self.id = id
        self.name = name
        self.width = width
        self.height = height
        self.ratio = CGFloat(width) / CGFloat(height)
        self.displayName = displayName
        self.isPopular = isPopular
    }
    
    /// Calculates the size for a given container width
    func sizeForWidth(_ width: CGFloat) -> CGSize {
        return CGSize(width: width, height: width / ratio)
    }
    
    /// Calculates the size for a given container height
    func sizeForHeight(_ height: CGFloat) -> CGSize {
        return CGSize(width: height * ratio, height: height)
    }
}

// MARK: - Aspect Ratio Manager
class AspectRatioManager {
    static let shared = AspectRatioManager()
    
    private init() {}
    
    /// Предустановленные соотношения сторон для Instagram
    let instagramRatios: [AspectRatio] = [
        AspectRatio(id: "square", name: "Квадрат", width: 1, height: 1, displayName: "1:1", isPopular: true),
        AspectRatio(id: "portrait", name: "Портрет", width: 4, height: 5, displayName: "4:5", isPopular: true),
        AspectRatio(id: "story", name: "Stories", width: 9, height: 16, displayName: "9:16", isPopular: true)
    ]

    
    /// Все доступные соотношения сторон
    var allRatios: [AspectRatio] {
        return instagramRatios
    }
    
    /// Популярные соотношения сторон
    var popularRatios: [AspectRatio] {
        return instagramRatios.filter { $0.isPopular }
    }
    
    /// Найти соотношение сторон по ID
    func ratio(by id: String) -> AspectRatio? {
        return allRatios.first { $0.id == id }
    }
    
    /// Найти ближайшее соотношение сторон для данного размера
    func closestRatio(for size: CGSize) -> AspectRatio {
        let targetRatio = size.width / size.height
        
        return allRatios.min { ratio1, ratio2 in
            abs(ratio1.ratio - targetRatio) < abs(ratio2.ratio - targetRatio)
        } ?? instagramRatios[0] // Возвращаем квадрат по умолчанию
    }
    
    /// Получить оптимальный размер для контейнера с учетом соотношения сторон
    func optimalSize(for aspectRatio: AspectRatio, in containerSize: CGSize, margin: CGFloat = 20) -> CGSize {
        let availableWidth = containerSize.width - margin * 2
        let availableHeight = containerSize.height - margin * 2
        
        // Вычисляем максимальный размер для каждого направления
        let maxSizeByWidth = aspectRatio.sizeForWidth(availableWidth)
        let maxSizeByHeight = aspectRatio.sizeForHeight(availableHeight)
        
        // Выбираем размер, который лучше помещается в контейнер
        if maxSizeByWidth.height <= availableHeight && maxSizeByWidth.width <= availableWidth {
            return maxSizeByWidth
        } else if maxSizeByHeight.width <= availableWidth && maxSizeByHeight.height <= availableHeight {
            return maxSizeByHeight
        } else {
            // Если ни один не помещается идеально, выбираем меньший
            let areaByWidth = maxSizeByWidth.width * min(maxSizeByWidth.height, availableHeight)
            let areaByHeight = min(maxSizeByHeight.width, availableWidth) * maxSizeByHeight.height
            
            return areaByWidth > areaByHeight ? 
                CGSize(width: maxSizeByWidth.width, height: min(maxSizeByWidth.height, availableHeight)) :
                CGSize(width: min(maxSizeByHeight.width, availableWidth), height: maxSizeByHeight.height)
        }
    }
}

// MARK: - UserDefaults Extension for AspectRatio
extension UserDefaults {
    private enum Keys {
        static let selectedAspectRatioId = "SelectedAspectRatioId"
    }
    
    var selectedAspectRatioId: String {
        get {
            return string(forKey: Keys.selectedAspectRatioId) ?? "square"
        }
        set {
            set(newValue, forKey: Keys.selectedAspectRatioId)
        }
    }
}

/// View controller for the Collage Editor screen.
/// It is initialized with a CollageEditorViewModel.
class CollageEditorViewController: UIViewController {
    
    weak var coordinator: (any Coordinator)?
    
    // MARK: - Properties
    
    /// The view model for the editor screen.
    private let viewModel: CollageEditorViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    private let collageView = UIView()
    private let backgroundImageView = UIImageView()
    private let saveButton = UIButton(type: .system)
    private let addTextButton = UIButton(type: .system)
    private let addStickerButton = UIButton(type: .system)
    private let changeBackgroundButton = UIButton(type: .system)
    private let addImageButton = UIButton(type: .system)
    
    // Aspect Ratio Selector
    private let aspectRatioScrollView = UIScrollView()
    private let aspectRatioStackView = UIStackView()
    private var aspectRatioButtons: [UIButton] = []
    private var currentAspectRatio: AspectRatio
    
    // Контейнер для ползунков
    private let slidersContainerView = UIView()
    
    // Ползунок для закругления углов
    private let cornerRadiusSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 20
        slider.value = 4
        return slider
    }()
    
    private let cornerRadiusLabel: UILabel = {
        let label = UILabel()
        label.text = "Закругление: 4"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    // Ползунок для расстояния между фотографиями
    private let spacingSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 0
        slider.maximumValue = 16
        slider.value = 8
        return slider
    }()
    
    private let spacingLabel: UILabel = {
        let label = UILabel()
        label.text = "Расстояние: 8"
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        return label
    }()
    
    // Данные для коллажа
    private var selectedPhotos: [UIImage] = [] // Выбранные пользователем фотографии
    private var textLayers: [TextLayerView] = [] // Текстовые слои
    // Frame picker для добавления изображений
    private var framePickerView: FramePickerView?
    private var isAddingNewImageWithFrame = false
    private var selectedImageForFraming: UIImage?
    private var stickerViews: [StickerView] = [] // Стикеры
    private var borderViews: [BorderDragView] = [] // Границы для изменения размеров
    private var currentTextLayer: TextLayerView?
    private var currentStickerView: StickerView?
    private var textEditingPanel: TextEditingPanel?
    
    // Сохраняем текущие размеры сетки
    private var currentColumnWidths: [CGFloat] = []
    private var currentRowHeights: [CGFloat] = []
    private var currentInnerMargin: CGFloat = 8
    
    /// Stores the currently selected image's index path (for image picker usage)
    private var currentIndexPath: IndexPath?
    
    // We'll store gridContainer's tag for later retrieval.
    private let gridContainerTag = 999
    
    // Advanced gesture handling
    private var gestureHandlers: [AdvancedImageGestureHandler] = []
    private var selectedImageView: UIImageView?
    
    // MARK: - Initializer
    
    /// Designated initializer with dependency injection.
    init(viewModel: CollageEditorViewModel, selectedPhotos: [UIImage] = []) {
        self.viewModel = viewModel
        self.selectedPhotos = selectedPhotos
        
        // Инициализируем текущее соотношение сторон
        let savedRatioId = UserDefaults.standard.selectedAspectRatioId
        self.currentAspectRatio = AspectRatioManager.shared.ratio(by: savedRatioId) ?? AspectRatioManager.shared.instagramRatios[0]
        
        super.init(nibName: nil, bundle: nil)
        
        // Загружаем сохраненное значение расстояния
        let savedMargin = UserDefaults.standard.double(forKey: "currentInnerMargin")
        if savedMargin > 0 {
            self.currentInnerMargin = CGFloat(savedMargin)
        }
        
        print("[CollageEditorViewController] init(viewModel:) called, restored margin: \(currentInnerMargin)")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[CollageEditorViewController] viewDidLoad called")
        setupUI()
        setupBindings()
        
        // Инициализируем ползунки с сохраненными значениями
        spacingSlider.value = Float(currentInnerMargin)
        spacingLabel.text = "Расстояние: \(Int(currentInnerMargin))"
        
        if let template = viewModel.collageTemplate.value {
            setupCollageView(with: template)
            // Сначала инициализируем модель с выбранными фотографиями
            initializeViewModelWithSelectedPhotos()
            fillCollageWithSelectedPhotos()
        }
    }

    // Предпочитаем белый текст статус-бара
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        title = "Редактор коллажа"
        
        // Настройка навигации в едином стиле
        navigationController?.navigationBar.tintColor = .systemBlue
        navigationController?.navigationBar.titleTextAttributes = [
            .foregroundColor: UIColor.white,
            .font: UIFont.boldSystemFont(ofSize: 18)
        ]
        
        // Добавляем кнопку "Назад"
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            title: "Назад",
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        
        // Настройка кнопки сохранения
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 25 // Более современный радиус
        
        // Настройка кнопки добавления текста
        addTextButton.setTitle("+ Текст", for: .normal)
        addTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        addTextButton.backgroundColor = .systemGreen
        addTextButton.setTitleColor(.white, for: .normal)
        addTextButton.layer.cornerRadius = 20 // Более современный радиус
        
        // Настройка кнопки добавления стикеров
        addStickerButton.setTitle("😀", for: .normal)
        addStickerButton.titleLabel?.font = UIFont.systemFont(ofSize: 20)
        addStickerButton.backgroundColor = .systemPurple
        addStickerButton.setTitleColor(.white, for: .normal)
        addStickerButton.layer.cornerRadius = 20
        
        // Настройка кнопки смены фона
        changeBackgroundButton.setTitle("Фон", for: .normal)
        changeBackgroundButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        changeBackgroundButton.backgroundColor = .systemOrange
        changeBackgroundButton.setTitleColor(.white, for: .normal)
        changeBackgroundButton.layer.cornerRadius = 20
        
        // Настройка кнопки добавления изображения
        addImageButton.setTitle("+ 📷", for: .normal)
        addImageButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        addImageButton.backgroundColor = .systemBlue
        addImageButton.setTitleColor(.white, for: .normal)
        addImageButton.layer.cornerRadius = 20
        
        // Настройка области коллажа
        collageView.backgroundColor = .lightGray
        collageView.layer.cornerRadius = 12
        collageView.clipsToBounds = true
        
        // Настройка фонового изображения
        backgroundImageView.contentMode = .scaleAspectFill
        backgroundImageView.clipsToBounds = true
        backgroundImageView.layer.cornerRadius = 12
        
        // Настройка контейнера для ползунков
        slidersContainerView.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
        slidersContainerView.layer.cornerRadius = 8
        slidersContainerView.layer.borderWidth = 1
        slidersContainerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Настройка селектора соотношений сторон
        setupAspectRatioSelector()
        
        // Добавляем элементы на view
        view.addSubview(aspectRatioScrollView)
        view.addSubview(collageView)
        view.addSubview(slidersContainerView)
        view.addSubview(saveButton)
        view.addSubview(addTextButton)
        view.addSubview(addStickerButton)
        view.addSubview(changeBackgroundButton)
        view.addSubview(addImageButton)
        
        // Добавляем фоновое изображение в collageView (самое первое, чтобы оно было позади всех элементов)
        collageView.addSubview(backgroundImageView)
        
        // Добавляем ползунки в контейнер
        slidersContainerView.addSubview(cornerRadiusLabel)
        slidersContainerView.addSubview(cornerRadiusSlider)
        slidersContainerView.addSubview(spacingLabel)
        slidersContainerView.addSubview(spacingSlider)
        
        // Настройка constraints
        aspectRatioScrollView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(10)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(80)
        }
        
        collageView.snp.makeConstraints { make in
            make.top.equalTo(aspectRatioScrollView.snp.bottom).offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
        }
        
        // Constraints для фонового изображения - заполняет весь collageView
        backgroundImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        slidersContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(saveButton.snp.top).offset(-10)
            make.height.equalTo(120)
        }
        
        // Constraints для ползунков внутри контейнера (вертикальное расположение)
        cornerRadiusLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(12)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(120)
        }
        
        cornerRadiusSlider.snp.makeConstraints { make in
            make.centerY.equalTo(cornerRadiusLabel)
            make.leading.equalTo(cornerRadiusLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        spacingLabel.snp.makeConstraints { make in
            make.top.equalTo(cornerRadiusLabel.snp.bottom).offset(20)
            make.leading.equalToSuperview().offset(16)
            make.width.equalTo(120)
        }
        
        spacingSlider.snp.makeConstraints { make in
            make.centerY.equalTo(spacingLabel)
            make.leading.equalTo(spacingLabel.snp.trailing).offset(12)
            make.trailing.equalToSuperview().offset(-16)
            make.height.equalTo(30)
        }
        
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.height.equalTo(50)
        }
        
        addTextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
            make.width.equalTo(80)
            make.height.equalTo(40)
        }
        
        addStickerButton.snp.makeConstraints { make in
            make.trailing.equalTo(addTextButton.snp.leading).offset(-10)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
            make.width.equalTo(50)
            make.height.equalTo(40)
        }
        
        changeBackgroundButton.snp.makeConstraints { make in
            make.trailing.equalTo(addStickerButton.snp.leading).offset(-10)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
            make.width.equalTo(60)
            make.height.equalTo(40)
        }
        
        addImageButton.snp.makeConstraints { make in
            make.trailing.equalTo(changeBackgroundButton.snp.leading).offset(-10)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
            make.width.equalTo(70)
            make.height.equalTo(40)
        }
        
        // Убеждаемся, что кнопки всегда поверх других элементов
        ensureButtonsOnTop()
        
        // Добавляем жест для снятия выделения при тапе на пустое место
        setupCollageViewTapGesture()
    }
    
    private func ensureButtonsOnTop() {
        // Перемещаем элементы управления на передний план
        view.bringSubviewToFront(slidersContainerView)
        view.bringSubviewToFront(saveButton)
        view.bringSubviewToFront(addTextButton)
        view.bringSubviewToFront(addStickerButton)
        view.bringSubviewToFront(changeBackgroundButton)
        view.bringSubviewToFront(addImageButton)

        // Если есть TextEditingPanel, она должна быть самой верхней
        if let textPanel = textEditingPanel {
            view.bringSubviewToFront(textPanel)
        }

        // Добавляем тень для лучшей видимости
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        saveButton.layer.shadowOpacity = 0.3
        saveButton.layer.shadowRadius = 4

        addTextButton.layer.shadowColor = UIColor.black.cgColor
        addTextButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addTextButton.layer.shadowOpacity = 0.3
        addTextButton.layer.shadowRadius = 4

        addStickerButton.layer.shadowColor = UIColor.black.cgColor
        addStickerButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addStickerButton.layer.shadowOpacity = 0.3
        addStickerButton.layer.shadowRadius = 4

        changeBackgroundButton.layer.shadowColor = UIColor.black.cgColor
        changeBackgroundButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        changeBackgroundButton.layer.shadowOpacity = 0.3
        changeBackgroundButton.layer.shadowRadius = 4

        addImageButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showImagePickerWithFrameSelection()
            })
            .disposed(by: disposeBag)

        slidersContainerView.layer.shadowColor = UIColor.black.cgColor
        slidersContainerView.layer.shadowOffset = CGSize(width: 0, height: 2)
        slidersContainerView.layer.shadowOpacity = 0.1
        slidersContainerView.layer.shadowRadius = 4
    }
    
    private func setupSquareEditingArea() {
        // Создаем квадратную область для редактирования
        let squareSize = min(collageView.bounds.width, collageView.bounds.height) - 40
        
        let editingArea = UIView()
        editingArea.backgroundColor = .clear
        editingArea.layer.borderColor = UIColor.gray.cgColor
        editingArea.layer.borderWidth = 2
        editingArea.layer.cornerRadius = 8
        editingArea.tag = 1000 // Тег для идентификации области редактирования
        
        collageView.addSubview(editingArea)
        editingArea.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(squareSize)
        }
    }
    
    private func fillCollageWithSelectedPhotos() {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        // Очищаем старые обработчики жестов
        gestureHandlers.removeAll()
        
        // Проходим по всем плиткам в шаблоне
        for index in 0..<gridContainer.subviews.count {
            guard let tileView = gridContainer.subviews[safe: index],
                  let imageView = tileView.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { continue }
            
            // Определяем, какое изображение использовать
            var imageToUse: UIImage?
            let indexPath = IndexPath(item: index, section: 0)
            
            // Сначала проверяем viewModel (обновленные изображения)
            if let modelImage = viewModel.getImage(at: indexPath) {
                imageToUse = modelImage
            }
            // Затем проверяем selectedPhotos (исходные изображения)
            else if index < selectedPhotos.count && selectedPhotos[index].size != .zero {
                imageToUse = selectedPhotos[index]
            }
            
            if let image = imageToUse {
                // Устанавливаем реальное изображение
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                imageView.backgroundColor = .clear
                
                // Создаем продвинутый обработчик жестов
                let gestureHandler = AdvancedImageGestureHandler(imageView: imageView, containerView: collageView)
                gestureHandler.delegate = self
                gestureHandlers.append(gestureHandler)
                
                // Обновляем видимость кнопки удаления
                gestureHandler.updateDeleteButtonVisibility()
                
                imageView.tag = index
                imageView.isUserInteractionEnabled = true
            } else {
                // Устанавливаем placeholder и добавляем возможность выбора
                imageView.image = UIImage(named: "placeholder")
                imageView.contentMode = .scaleAspectFill
                imageView.backgroundColor = .lightGray
                
                // Добавляем тап для выбора изображения
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageForTile(_:)))
                imageView.addGestureRecognizer(tapGesture)
                imageView.tag = index
                imageView.isUserInteractionEnabled = true
            }
        }
        
        // Убеждаемся, что кнопки остаются доступными после создания обработчиков жестов
        ensureButtonsOnTop()
    }
    
    @objc private func selectImageForTile(_ gesture: UITapGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        
        currentIndexPath = IndexPath(item: imageView.tag, section: 0)
        presentImagePicker()
    }
    
    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }
    
    // MARK: - Creative Template Styling
    
    private func applyCreativeStyle(to tileView: UIView, template: CollageTemplate, position: (Int, Int), index: Int) {
        switch template.name {
        case "Heart 7":
            // Особая стилизация для формы сердца
            tileView.layer.cornerRadius = tileView.bounds.width / 6
            tileView.layer.shadowColor = UIColor.red.cgColor
            tileView.layer.shadowOpacity = 0.3
            tileView.layer.shadowRadius = 4
            tileView.layer.shadowOffset = CGSize(width: 0, height: 2)
            
            // Верхние части сердца (индексы 0, 1) - более округлые
            if index == 0 || index == 1 {
                tileView.layer.cornerRadius = tileView.bounds.width / 3
            }
            // Нижний кончик сердца (индекс 6)
            else if index == 6 {
                tileView.layer.cornerRadius = tileView.bounds.width / 4
                // Делаем кончик более заостренным
                let trianglePath = UIBezierPath()
                let bounds = tileView.bounds
                trianglePath.move(to: CGPoint(x: bounds.midX, y: 0))
                trianglePath.addLine(to: CGPoint(x: 0, y: bounds.height * 0.7))
                trianglePath.addLine(to: CGPoint(x: bounds.width, y: bounds.height * 0.7))
                trianglePath.close()
                
                let maskLayer = CAShapeLayer()
                maskLayer.path = trianglePath.cgPath
                tileView.layer.mask = maskLayer
            }
            
        case "Circle 4":
            tileView.layer.cornerRadius = min(tileView.bounds.width, tileView.bounds.height) / 2
            
        case "Wave Split 2", "Curve Split 2":
            tileView.layer.cornerRadius = 12
            
        case "Triangle 3":
            // Создаем треугольную маску
            let trianglePath = UIBezierPath()
            let bounds = tileView.bounds
            if index == 0 {
                // Верхний треугольник
                trianglePath.move(to: CGPoint(x: bounds.midX, y: 0))
                trianglePath.addLine(to: CGPoint(x: 0, y: bounds.height))
                trianglePath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            } else if index == 1 {
                // Левый нижний треугольник
                trianglePath.move(to: CGPoint(x: 0, y: 0))
                trianglePath.addLine(to: CGPoint(x: 0, y: bounds.height))
                trianglePath.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
            } else {
                // Правый нижний треугольник
                trianglePath.move(to: CGPoint(x: bounds.width, y: 0))
                trianglePath.addLine(to: CGPoint(x: bounds.midX, y: bounds.height))
                trianglePath.addLine(to: CGPoint(x: bounds.width, y: bounds.height))
            }
            trianglePath.close()
            
            let maskLayer = CAShapeLayer()
            maskLayer.path = trianglePath.cgPath
            tileView.layer.mask = maskLayer
            
        case "Diamond 4":
            // Создаем ромбовидную маску
            let diamondPath = UIBezierPath()
            let bounds = tileView.bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 3
            
            diamondPath.move(to: CGPoint(x: center.x, y: center.y - radius))
            diamondPath.addLine(to: CGPoint(x: center.x + radius, y: center.y))
            diamondPath.addLine(to: CGPoint(x: center.x, y: center.y + radius))
            diamondPath.addLine(to: CGPoint(x: center.x - radius, y: center.y))
            diamondPath.close()
            
            let maskLayer = CAShapeLayer()
            maskLayer.path = diamondPath.cgPath
            tileView.layer.mask = maskLayer
            
        case "Polaroid Stack":
            // Поворачиваем фото как поляроиды
            let rotations: [CGFloat] = [-0.1, 0.15, -0.05]
            if index < rotations.count {
                tileView.transform = CGAffineTransform(rotationAngle: rotations[index])
            }
            tileView.layer.cornerRadius = 8
            tileView.layer.shadowColor = UIColor.black.cgColor
            tileView.layer.shadowOffset = CGSize(width: 0, height: 2)
            tileView.layer.shadowOpacity = 0.3
            tileView.layer.shadowRadius = 4
            
        case "Film Strip 4":
            tileView.layer.cornerRadius = 2
            // Добавляем перфорацию как декорацию
            tileView.layer.borderWidth = 2
            tileView.layer.borderColor = UIColor.darkGray.cgColor
            
        case "Plus 5", "Star 5":
            if index == 2 { // Центральная фотография
                tileView.layer.cornerRadius = min(tileView.bounds.width, tileView.bounds.height) / 2
            } else {
                tileView.layer.cornerRadius = 8
            }
            
        case "Hexagon 6":
            // Создаем шестиугольную маску
            let hexagonPath = UIBezierPath()
            let bounds = tileView.bounds
            let center = CGPoint(x: bounds.midX, y: bounds.midY)
            let radius = min(bounds.width, bounds.height) / 2.5
            
            for i in 0..<6 {
                let angle = CGFloat(i) * .pi / 3
                let point = CGPoint(
                    x: center.x + radius * cos(angle),
                    y: center.y + radius * sin(angle)
                )
                if i == 0 {
                    hexagonPath.move(to: point)
                } else {
                    hexagonPath.addLine(to: point)
                }
            }
            hexagonPath.close()
            
            let maskLayer = CAShapeLayer()
            maskLayer.path = hexagonPath.cgPath
            tileView.layer.mask = maskLayer
            
        default:
            // Стандартный стиль
            tileView.layer.cornerRadius = 4.0
        }
    }
    
    private func presentImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Collage View Setup
    
    /// Configures the collage view based on the provided template.
    /// Настройка области коллажа с учетом выбранного соотношения сторон
    private func setupCollageView(with template: CollageTemplate) {
        // Очищаем старый коллаж, кроме backgroundImageView
        collageView.subviews.forEach { subview in
            if subview !== backgroundImageView {
                subview.removeFromSuperview()
            }
        }
        
        // Сбрасываем сохраненные размеры сетки
        currentColumnWidths.removeAll()
        currentRowHeights.removeAll()
        
        // Синхронизируем ползунок с текущим значением margin
        spacingSlider.value = Float(currentInnerMargin)
        spacingLabel.text = "Расстояние: \(Int(currentInnerMargin))"
        
        // Force layout update to obtain correct bounds.
        view.layoutIfNeeded()
        print("Setting up collage view with template: \(template.name), aspect ratio: \(currentAspectRatio.displayName), spacing: \(Int(currentInnerMargin))")
        
        // Define margins - используем текущие значения ползунков
        let innerMargin = currentInnerMargin
        let outerMargin = max(currentInnerMargin, 8) // Синхронизируем с ползунком
        
        // Определяем, является ли шаблон специальным.
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        
        let columns: Int
        let rows: Int
        if specialTemplates.contains(template.name) {
            columns = 2
            rows = 2
        } else {
            columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
            rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        }
        
        // Получаем размер collageView
        let containerWidth = collageView.bounds.width > 0 ? collageView.bounds.width : 200
        let containerHeight = collageView.bounds.height > 0 ? collageView.bounds.height : 200
        
        // Определяем оптимальный размер рабочей области с учетом соотношения сторон
        let availableSize = CGSize(width: containerWidth - 2 * outerMargin, height: containerHeight - 2 * outerMargin)
        let workAreaSize = AspectRatioManager.shared.optimalSize(for: currentAspectRatio, in: availableSize, margin: 0)
        
        // Вычисляем размеры плиток исходя из рабочей области (не квадрата!)
        let totalHorizontalSpacing = innerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = innerMargin * CGFloat(rows - 1)
        
        // Размер плиток должен адаптироваться под соотношение сторон
        let tileWidth = (workAreaSize.width - totalHorizontalSpacing) / CGFloat(columns)
        let tileHeight = (workAreaSize.height - totalVerticalSpacing) / CGFloat(rows)
        
        // Размер контейнера сетки точно соответствует выбранному соотношению
        let gridWidth = workAreaSize.width
        let gridHeight = workAreaSize.height
        
        // Убеждаемся, что фоновое изображение находится в самом низу стека
        collageView.sendSubviewToBack(backgroundImageView)
        
        // Создаем контейнер для сетки и центрируем его в collageView.
        let gridContainer = UIView()
        gridContainer.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.3)
        gridContainer.layer.borderColor = UIColor.systemBlue.cgColor
        gridContainer.layer.borderWidth = 2
        gridContainer.layer.cornerRadius = 8
        gridContainer.tag = gridContainerTag
        collageView.addSubview(gridContainer)
        gridContainer.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(gridWidth)
            make.height.equalTo(gridHeight)
            // ВАЖНО: Убеждаемся что gridContainer не выходит за пределы с учетом outerMargin
            make.leading.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-outerMargin)
            make.top.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-outerMargin)
        }
        
        // Для каждого элемента шаблона создаем tileView с прямоугольными размерами
        for (index, position) in template.positions.enumerated() {
            _ = position.0
            _ = position.1
            
            // Расчет позиции и размера плитки с учетом реального соотношения сторон
            var tileFrame = CGRect(
                x: CGFloat(position.0) * (tileWidth + innerMargin),
                y: CGFloat(position.1) * (tileHeight + innerMargin),
                width: tileWidth,
                height: tileHeight
            )
            
            // Специальная обработка для шаблонов:
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                // Левая плитка растягивается по высоте (занимает 2 ряда).
                tileFrame.size.height = tileHeight * 2 + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileFrame.size.height = tileHeight * 2 + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                // Верхняя плитка растягивается по ширине (занимает 2 столбца).
                tileFrame.size.width = tileWidth * 2 + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileFrame.size.width = tileWidth * 2 + innerMargin
            }
            
            let tileView = UIView()
            tileView.backgroundColor = .clear
            tileView.layer.borderColor = UIColor.white.cgColor
            tileView.layer.borderWidth = 1.0
            tileView.clipsToBounds = true
            tileView.tag = index // Устанавливаем тег для идентификации
            
            // Применяем специальные стили для креативных шаблонов после установки constraints
            DispatchQueue.main.async {
                self.applyCreativeStyle(to: tileView, template: template, position: position, index: index)
            }
            
            // Создаем imageView для placeholder.
            let imageView = UIImageView()
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .clear
            if let placeholder = UIImage(named: "placeholder") {
                imageView.image = placeholder
            }
            tileView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            // Настраиваем взаимодействие с пользователем
            tileView.isUserInteractionEnabled = true
            imageView.isUserInteractionEnabled = true
            imageView.tag = index
            
            // Добавляем gesture recognizer для выбора изображения
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageForTile(_:)))
            imageView.addGestureRecognizer(tapGesture)
            
            gridContainer.addSubview(tileView)
            
            // Устанавливаем constraints для плитки
            tileView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(tileFrame.origin.x)
                make.top.equalToSuperview().offset(tileFrame.origin.y)
                make.width.equalTo(tileFrame.size.width)
                make.height.equalTo(tileFrame.size.height)
            }
        }
        
        // Инициализируем базовые размеры сетки с учетом соотношения сторон
        initializeGridSizes(for: template, containerSize: workAreaSize)
        
        // Добавляем слайдеры между соседними фотографиями
        setupResizableSliders(for: template, in: gridContainer)
    }
    
    // MARK: - Bindings
    
    private func setupBindings() {
        viewModel.saveButtonEnabled
            .bind(to: saveButton.rx.isEnabled)
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("Save button tapped")
                self?.saveCollage()
            })
            .disposed(by: disposeBag)
        
        addTextButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.addTextLayer()
            })
            .disposed(by: disposeBag)
        
        addStickerButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.showStickerPicker()
            })
            .disposed(by: disposeBag)
        
        changeBackgroundButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.changeBackground()
            })
            .disposed(by: disposeBag)
        
        // Обработка изменений ползунка закругления углов
        cornerRadiusSlider.rx.value
            .skip(1) // Пропускаем начальное значение
            .subscribe(onNext: { [weak self] value in
                self?.updateCornerRadius(CGFloat(value))
            })
            .disposed(by: disposeBag)
        
        // Обработка изменений ползунка расстояния
        spacingSlider.rx.value
            .skip(1) // Пропускаем начальное значение
            .subscribe(onNext: { [weak self] value in
                self?.updateSpacing(CGFloat(value))
            })
            .disposed(by: disposeBag)
    }
    
    // MARK: - Grid Size Management
    
    private func initializeGridSizes(for template: CollageTemplate, containerSize: CGSize) {
        let innerMargin = currentInnerMargin
        let outerMargin = max(currentInnerMargin, 8)
        
        // Определяем размеры сетки
        let columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
        let rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        
        // Вычисляем доступное пространство
        let availableWidth = containerSize.width - 2 * outerMargin - CGFloat(columns - 1) * innerMargin
        let availableHeight = containerSize.height - 2 * outerMargin - CGFloat(rows - 1) * innerMargin
        
        // Базовые размеры (равномерное распределение)
        let baseColumnWidth = availableWidth / CGFloat(columns)
        let baseRowHeight = availableHeight / CGFloat(rows)
        
        // Инициализируем массивы размеров
        currentColumnWidths = Array(repeating: baseColumnWidth, count: columns)
        currentRowHeights = Array(repeating: baseRowHeight, count: rows)
    }
    
    // MARK: - Border Drag Views
    
    private func setupResizableSliders(for template: CollageTemplate, in gridContainer: UIView) {
        // Очищаем старые границы
        borderViews.forEach { $0.removeFromSuperview() }
        borderViews.removeAll()
        
        // Не создаем границы для специальных шаблонов с растянутыми плитками
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        if specialTemplates.contains(template.name) {
            print("⚠️ Ползунки изменения размера отключены для специального шаблона: \(template.name)")
            return
        }
        
        // Определяем, где нужны границы (между соседними фотографиями)
        for i in 0..<template.positions.count {
            for j in (i+1)..<template.positions.count {
                let pos1 = template.positions[i]
                let pos2 = template.positions[j]
                
                // Проверяем, являются ли фото соседними
                let isHorizontalNeighbors = abs(pos1.0 - pos2.0) == 1 && pos1.1 == pos2.1
                let isVerticalNeighbors = abs(pos1.1 - pos2.1) == 1 && pos1.0 == pos2.0
                
                if isHorizontalNeighbors || isVerticalNeighbors {
                    // Ищем плитки по индексу в массиве subviews
                    guard i < gridContainer.subviews.count, 
                          j < gridContainer.subviews.count else { continue }
                    
                    let tile1 = gridContainer.subviews[i]
                    let tile2 = gridContainer.subviews[j]
                    
                    // Проверяем, что это действительно плитки (не служебные view)
                    guard tile1.tag < 1000, tile2.tag < 1000 else { continue }
                    
                    let borderView = BorderDragView()
                    borderView.isVertical = isHorizontalNeighbors
                    borderView.delegate = self
                    borderView.tag = i * 100 + j // Уникальный тег для идентификации
                    borderView.ratio = 0.5 // Начальное соотношение
                    
                    gridContainer.addSubview(borderView)
                    
                    if isHorizontalNeighbors {
                        // Вертикальная граница между горизонтальными соседями
                        borderView.snp.makeConstraints { make in
                            make.leading.equalTo(tile1.snp.trailing)
                            make.trailing.equalTo(tile2.snp.leading)
                            make.top.equalTo(tile1.snp.top)
                            make.bottom.equalTo(tile1.snp.bottom)
                        }
                    } else {
                        // Горизонтальная граница между вертикальными соседями
                        borderView.snp.makeConstraints { make in
                            make.top.equalTo(tile1.snp.bottom)
                            make.bottom.equalTo(tile2.snp.top)
                            make.leading.equalTo(tile1.snp.leading)
                            make.trailing.equalTo(tile1.snp.trailing)
                        }
                    }
                    
                    borderViews.append(borderView)
                    print("🔧 Создана граница между плитками \(i) и \(j), тип: \(isHorizontalNeighbors ? "вертикальная" : "горизонтальная")")
                }
            }
        }
        
        print("✅ Создано \(borderViews.count) границ для изменения размеров")
    }
    
    // MARK: - Text Layers
    
    private func addTextLayer() {
        // Создаем текстовый слой с адаптивными размерами
        let textLayer = TextLayerView()

        // Настраиваем адаптацию текста
        textLayer.configureTextAdaptation(
            minFontSize: 12,
            maxFontSize: 48,
            adjustsFontSize: true,
            enablesWrapping: true
        )

        // Устанавливаем ограничения на основе размера коллажа
        let collageSize = collageView.bounds.size
        let maxTextWidth = min(collageSize.width * 0.8, 300) // Максимум 80% ширины коллажа или 300pt
        let maxTextHeight = min(collageSize.height * 0.6, 200) // Максимум 60% высоты коллажа или 200pt

        textLayer.updateTextConstraints(maxWidth: maxTextWidth, maxHeight: maxTextHeight)

        // Получаем адаптированный размер после настройки
        let adaptedSize = textLayer.adaptiveTextView.getAdaptedSize()
        let finalWidth = max(adaptedSize.width, 100) // Минимальная ширина
        let finalHeight = max(adaptedSize.height, 40) // Минимальная высота

        // Размещаем ближе к левому краю выше по экрану (примерно 1/4 от верха)
        let leftMargin: CGFloat = 30 // Отступ от левого края
        let centerX = leftMargin
        let centerY = collageView.bounds.height / 4 - finalHeight / 2

        textLayer.frame = CGRect(x: centerX, y: centerY, width: finalWidth, height: finalHeight)

        textLayer.onDelete = { [weak self] in
            self?.removeTextLayer(textLayer)
        }
        textLayer.onTap = { [weak self] in
            self?.selectTextLayer(textLayer)
        }

        collageView.addSubview(textLayer)
        textLayers.append(textLayer)
        selectTextLayer(textLayer)
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    private func changeBackground() {
        let backgroundPicker = BackgroundPickerViewController()
        backgroundPicker.delegate = self
        backgroundPicker.modalPresentationStyle = .overFullScreen
        backgroundPicker.modalTransitionStyle = .crossDissolve
        
        present(backgroundPicker, animated: true, completion: nil)
    }
    
    private func selectTextLayer(_ textLayer: TextLayerView) {
        // Снимаем выделение со всех текстовых слоев
        textLayers.forEach { $0.setSelected(false) }
        
        // Снимаем выделение с изображений
        gestureHandlers.forEach { $0.setSelected(false) }
        selectedImageView = nil
        
        // Выделяем текущий
        textLayer.setSelected(true)
        currentTextLayer = textLayer
        
        // Показываем панель редактирования
        showTextEditingPanel(for: textLayer)
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    private func removeTextLayer(_ textLayer: TextLayerView) {
        textLayer.removeFromSuperview()
        if let index = textLayers.firstIndex(of: textLayer) {
            textLayers.remove(at: index)
        }
        if currentTextLayer == textLayer {
            currentTextLayer = nil
            hideTextEditingPanel()
        }
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    /// Снимает выделение со всех текстовых слоев
    private func deselectAllTextLayers() {
        textLayers.forEach { $0.setSelected(false) }
        currentTextLayer = nil
        hideTextEditingPanel()
    }
    
    /// Добавляет жест для снятия выделения при тапе на пустое место
    private func setupCollageViewTapGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(collageViewTapped(_:)))
        tapGesture.cancelsTouchesInView = false
        collageView.addGestureRecognizer(tapGesture)
    }
    
    @objc private func collageViewTapped(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: collageView)
        
        // Проверяем, не попали ли в какой-то текстовый слой
        var hitTextLayer = false
        for textLayer in textLayers {
            if textLayer.frame.contains(location) {
                hitTextLayer = true
                break
            }
        }
        
        // Проверяем, не попали ли в какой-то стикер
        var hitSticker = false
        for stickerView in stickerViews {
            if stickerView.frame.contains(location) {
                hitSticker = true
                break
            }
        }
        
        // Проверяем, не попали ли в изображение
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        let locationInGrid = collageView.convert(location, to: gridContainer)
        var hitImage = false
        for subview in gridContainer.subviews {
            if subview.frame.contains(locationInGrid) && subview.tag < 1000 {
                hitImage = true
                break
            }
        }
        
        // Если не попали ни в текст, ни в стикер, ни в изображение, снимаем все выделения
        if !hitTextLayer && !hitSticker && !hitImage {
            deselectAllTextLayers()
            deselectAllStickers()
            gestureHandlers.forEach { $0.setSelected(false) }
            selectedImageView = nil
        }
    }
    
    private func showTextEditingPanel(for textLayer: TextLayerView) {
        hideTextEditingPanel()

        let panel = TextEditingPanel()
        panel.delegate = self
        view.addSubview(panel)

        // Панель занимает весь экран для правильного позиционирования относительно клавиатуры
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }

        let adaptationEnabled = textLayer.adaptiveTextView.adjustsFontSizeToFitWidth
        let currentAlignment = getCurrentTextAlignment(for: textLayer)
        panel.show(with: textLayer.archTextView.text, textAdaptationEnabled: adaptationEnabled, textAlignment: currentAlignment)
        textEditingPanel = panel

        // TextEditingPanel должна быть самой верхней, поэтому перемещаем её на передний план
        view.bringSubviewToFront(panel)

        // Убеждаемся, что кнопки остаются доступными после добавления панели
        ensureButtonsOnTop()
    }

    private func getCurrentTextAlignment(for textLayer: TextLayerView) -> NSTextAlignment {
        return textLayer.getTextAlignment()
    }

    private func hideTextEditingPanel() {
        textEditingPanel?.hide()
        textEditingPanel = nil
    }
    
    // MARK: - Save Collage
    
    /// Captures snapshots of each tile (with applied transformations) and draws them into the final collage image with white borders.
    private func saveCollage() {
        guard let template = viewModel.collageTemplate.value else {
            print("No template available")
            return
        }
        
        // Вычисляем финальный размер изображения на основе выбранного соотношения сторон
        let baseWidth: CGFloat = 2400
        let finalCollageSize = currentAspectRatio.sizeForWidth(baseWidth)
        
        // Получаем gridContainer для определения текущих пропорций
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else {
            print("Failed to retrieve grid container")
            return
        }
        gridContainer.layoutIfNeeded()
        
        // Begin final collage image context.
        UIGraphicsBeginImageContextWithOptions(finalCollageSize, false, 0)
        guard let context = UIGraphicsGetCurrentContext() else {
            print("Failed to get graphics context")
            return
        }
        defer { UIGraphicsEndImageContext() }
        
        // Рисуем фоновое изображение или цветной фон
        if let backgroundImage = backgroundImageView.image {
            // Рисуем фоновое изображение, растягивая его на весь финальный размер
            backgroundImage.draw(in: CGRect(origin: .zero, size: finalCollageSize))
        } else if let backgroundColor = backgroundImageView.backgroundColor, backgroundColor != .clear {
            // Если установлен цветной фон, заливаем этим цветом
            backgroundColor.setFill()
            context.fill(CGRect(origin: .zero, size: finalCollageSize))
        } else {
            // Если фона нет, заливаем белым цветом
            UIColor.white.setFill()
            context.fill(CGRect(origin: .zero, size: finalCollageSize))
        }
        
        // Вычисляем масштаб для перевода из текущих размеров в финальные
        let currentGridSize = gridContainer.bounds.size
        let scaleX = finalCollageSize.width / currentGridSize.width
        let scaleY = finalCollageSize.height / currentGridSize.height
        let scale = min(scaleX, scaleY)
        
        // Вычисляем смещение для центрирования
        let scaledGridWidth = currentGridSize.width * scale
        let scaledGridHeight = currentGridSize.height * scale
        let offsetX = (finalCollageSize.width - scaledGridWidth) / 2
        let offsetY = (finalCollageSize.height - scaledGridHeight) / 2
        
        // Получаем текущее значение закругления углов
        let currentCornerRadius = CGFloat(cornerRadiusSlider.value)
        
        // Для каждого элемента шаблона.
        for (index, _) in template.positions.enumerated() {
            // Получаем текущую плитку из UI
            guard let tileView = gridContainer.subviews[safe: index],
                  let imageView = tileView.subviews.first(where: { $0 is UIImageView }) as? UIImageView
            else {
                print("Failed to retrieve tile view or image view for index \(index)")
                continue
            }
            
            // Получаем изображение для элемента
            guard let image = imageView.image else { continue }
            
            // Получаем фрейм плитки относительно gridContainer
            let tileFrame = tileView.frame
            
            // Масштабируем фрейм плитки для финального изображения
            let scaledTileFrame = CGRect(
                x: tileFrame.origin.x * scale + offsetX,
                y: tileFrame.origin.y * scale + offsetY,
                width: tileFrame.width * scale,
                height: tileFrame.height * scale
            )
            
            // Сохраняем состояние контекста
            context.saveGState()
            
            // Создаем clipping path с текущим закруглением
            let roundedPath = UIBezierPath(roundedRect: scaledTileFrame, cornerRadius: currentCornerRadius * scale)
            roundedPath.addClip()
            
            // Перемещаем контекст в центр плитки
            let tileCenter = CGPoint(x: scaledTileFrame.midX, y: scaledTileFrame.midY)
            context.translateBy(x: tileCenter.x, y: tileCenter.y)
            
            // Применяем трансформацию изображения (масштаб, поворот, перемещение)
            let imageTransform = imageView.transform
            context.concatenate(imageTransform)
            
            // Вычисляем размер изображения с учетом contentMode (scaleAspectFill)
            let imageSize = image.size
            let tileSize = tileFrame.size
            
            // Для scaleAspectFill находим масштаб, который заполняет всю плитку
            let scaleX = tileSize.width / imageSize.width
            let scaleY = tileSize.height / imageSize.height
            let aspectFillScale = max(scaleX, scaleY)
            
            // Размер изображения после масштабирования
            let scaledImageSize = CGSize(
                width: imageSize.width * aspectFillScale * scale,
                height: imageSize.height * aspectFillScale * scale
            )
            
            // Рисуем изображение по центру плитки
            let imageRect = CGRect(
                x: -scaledImageSize.width / 2,
                y: -scaledImageSize.height / 2,
                width: scaledImageSize.width,
                height: scaledImageSize.height
            )
            
            image.draw(in: imageRect)
            
            // Восстанавливаем состояние контекста
            context.restoreGState()
            
            // Не рисуем рамки - они нужны только для редактирования, а не для финального изображения
        }
        
        // Рисуем текстовые слои поверх коллажа
        for textLayer in textLayers {
            context.saveGState()

            // 1. Вычисляем центр слоя в координатах финального изображения
            let centerInGrid = collageView.convert(textLayer.center, to: gridContainer)
            let scaledCenter = CGPoint(
                x: centerInGrid.x * scale + offsetX,
                y: centerInGrid.y * scale + offsetY
            )
            
            // 2. Перемещаем контекст в этот центр
            context.translateBy(x: scaledCenter.x, y: scaledCenter.y)

            // 3. Применяем трансформацию слоя, отмасштабированную на общий масштаб коллажа
            let finalTransform = textLayer.transform.scaledBy(x: scale, y: scale)
            context.concatenate(finalTransform)
            
            // 4. Рисуем текст с оригинальными атрибутами.
            // Трансформация контекста позаботится о масштабе и повороте.
            let attributes: [NSAttributedString.Key: Any] = [
                .font: textLayer.archTextView.font,
                .foregroundColor: textLayer.archTextView.textColor
            ]
            
            let text = textLayer.archTextView.text
            let textSize = text.size(withAttributes: attributes)
            
            // Рисуем текст, центрируя его относительно текущей точки (которая является центром слоя)
            let textRect = CGRect(
                x: -textSize.width / 2,
                y: -textSize.height / 2,
                width: textSize.width,
                height: textSize.height
            )
            
            text.draw(in: textRect, withAttributes: attributes)
            
            context.restoreGState()
        }
        
        // Рисуем стикеры поверх коллажа
        for stickerView in stickerViews {
            context.saveGState()
            
            // 1. Вычисляем центр стикера в координатах финального изображения
            let centerInGrid = collageView.convert(stickerView.center, to: gridContainer)
            let scaledCenter = CGPoint(
                x: centerInGrid.x * scale + offsetX,
                y: centerInGrid.y * scale + offsetY
            )
            
            // 2. Перемещаем контекст в этот центр
            context.translateBy(x: scaledCenter.x, y: scaledCenter.y)
            
            // 3. Применяем трансформацию стикера, отмасштабированную на общий масштаб коллажа
            let finalTransform = stickerView.transform.scaledBy(x: scale, y: scale)
            context.concatenate(finalTransform)
            
            // 4. Рисуем изображение стикера
            if let stickerImage = stickerView.subviews.first(where: { $0 is UIImageView }) as? UIImageView,
               let image = stickerImage.image {
                
                // Вычисляем размер стикера с учетом масштаба
                let stickerSize = stickerView.bounds.size
                let scaledStickerSize = CGSize(
                    width: stickerSize.width,
                    height: stickerSize.height
                )
                
                // Рисуем стикер, центрируя его относительно текущей точки
                let stickerRect = CGRect(
                    x: -scaledStickerSize.width / 2,
                    y: -scaledStickerSize.height / 2,
                    width: scaledStickerSize.width,
                    height: scaledStickerSize.height
                )
                
                image.draw(in: stickerRect)
            }
            
            context.restoreGState()
        }
        
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            // Сохраняем в фотоальбом
            UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            // Сохраняем в галерею приложения
            let templateName = viewModel.collageTemplate.value?.name ?? "Неизвестный шаблон"
            let savedCollage = SavedCollage(image: finalImage, templateName: templateName, aspectRatioId: currentAspectRatio.id)
            SavedCollagesManager.shared.saveCollage(savedCollage)
            
            print("Final collage image saved successfully!")
            
            // Показываем уведомление об успешном сохранении
            showSaveSuccessAlert()
        } else {
            print("Failed to generate final collage image")
        }
    }

    @objc private func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            print("Error saving collage image: \(error.localizedDescription)")
        } else {
            print("Collage image saved successfully!")
        }
    }
    
    private func showSaveSuccessAlert() {
        let alert = UIAlertController(
            title: "Коллаж сохранен!",
            message: "Ваш коллаж сохранен в галерею и фотоальбом",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Перейти в галерею", style: .default) { [weak self] _ in
            // Gallery navigation not implemented in current coordinator
            self?.navigationController?.popToRootViewController(animated: true)
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true)
    }
    
    // MARK: - Slider Methods
    
    private func updateCornerRadius(_ radius: CGFloat) {
        // Обновляем лейбл
        cornerRadiusLabel.text = "Закругление: \(Int(radius))"
        
        // Применяем закругление ко всем плиткам
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        for subview in gridContainer.subviews {
            if subview.tag < 1000 { // Только плитки, не служебные view
                subview.layer.cornerRadius = radius
            }
        }
    }
    
    private func updateSpacing(_ spacing: CGFloat) {
        // Обновляем лейбл
        spacingLabel.text = "Расстояние: \(Int(spacing))"
        
        // Сохраняем новое значение расстояния
        currentInnerMargin = spacing
        
        // Сохраняем в UserDefaults для сохранения состояния
        UserDefaults.standard.set(spacing, forKey: "currentInnerMargin")
        
        // Сохраняем текущие изображения
        let savedImages = saveCurrentImages()
        
        // Перестраиваем layout коллажа с новым расстоянием
        if let template = viewModel.collageTemplate.value {
            rebuildCollageLayoutWithAspectRatio(with: template, newInnerMargin: spacing)
            
            // Восстанавливаем изображения
            DispatchQueue.main.async {
                self.restoreImages(savedImages)
            }
        }
    }
    
    private func rebuildCollageLayoutWithAspectRatio(with template: CollageTemplate, newInnerMargin: CGFloat) {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        // Используем то же значение расстояния для внешних отступов
        let outerMargin: CGFloat = max(newInnerMargin, 8) // Минимум 8px для удобности
        
        // Определяем размеры сетки
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        let columns: Int
        let rows: Int
        if specialTemplates.contains(template.name) {
            columns = 2
            rows = 2
        } else {
            columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
            rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        }
        
        // Получаем размер collageView
        let containerWidth = collageView.bounds.width > 0 ? collageView.bounds.width : 200
        let containerHeight = collageView.bounds.height > 0 ? collageView.bounds.height : 200
        
        // Определяем оптимальный размер рабочей области с учетом новых внешних отступов
        let availableSize = CGSize(width: containerWidth - 2 * outerMargin, height: containerHeight - 2 * outerMargin)
        let workAreaSize = AspectRatioManager.shared.optimalSize(for: currentAspectRatio, in: availableSize, margin: 0)
        
        // КРИТИЧНО: Сохраняем существующие размеры BorderDragView или инициализируем базовыми
        let totalHorizontalSpacing = newInnerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = newInnerMargin * CGFloat(rows - 1)
        
        var columnWidths = currentColumnWidths
        var rowHeights = currentRowHeights
        
        // Если размеры не установлены, инициализируем равномерными
        if columnWidths.isEmpty || rowHeights.isEmpty {
            let baseColumnWidth = (workAreaSize.width - totalHorizontalSpacing) / CGFloat(columns)
            let baseRowHeight = (workAreaSize.height - totalVerticalSpacing) / CGFloat(rows)
            
            columnWidths = Array(repeating: baseColumnWidth, count: columns)
            rowHeights = Array(repeating: baseRowHeight, count: rows)
        } else {
            // Масштабируем существующие размеры под новую рабочую область
            let currentTotalWidth = columnWidths.reduce(0, +)
            let currentTotalHeight = rowHeights.reduce(0, +)
            
            let newTotalWidth = workAreaSize.width - totalHorizontalSpacing
            let newTotalHeight = workAreaSize.height - totalVerticalSpacing
            
            let widthScale = newTotalWidth / currentTotalWidth
            let heightScale = newTotalHeight / currentTotalHeight
            
            columnWidths = columnWidths.map { $0 * widthScale }
            rowHeights = rowHeights.map { $0 * heightScale }
        }
        
        // Сохраняем обновленные размеры
        currentColumnWidths = columnWidths
        currentRowHeights = rowHeights
        
        // Размер контейнера сетки точно соответствует выбранному соотношению
        let gridWidth = workAreaSize.width
        let gridHeight = workAreaSize.height
        
        // Обновляем размер gridContainer с учетом outerMargin
        gridContainer.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(gridWidth)
            make.height.equalTo(gridHeight)
            // ВАЖНО: Убеждаемся что gridContainer не выходит за пределы с учетом outerMargin
            make.leading.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-outerMargin)
            make.top.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-outerMargin)
        }
        
        // Обновляем позиции всех плиток с учетом сохраненных размеров BorderDragView
        for (index, position) in template.positions.enumerated() {
            guard let tileView = gridContainer.subviews[safe: index] else { continue }
            
            _ = position.0
            _ = position.1
            
            // Вычисляем позицию плитки с учетом переменных размеров колонок и строк
            var x: CGFloat = 0
            for i in 0..<position.0 {
                x += columnWidths[i] + newInnerMargin
            }
            
            var y: CGFloat = 0
            for i in 0..<position.1 {
                y += rowHeights[i] + newInnerMargin
            }
            
            // Базовые размеры плитки
            let tileWidth = columnWidths[position.0]
            let tileHeight = rowHeights[position.1]
            
            // Расчет позиции и размера плитки с учетом переменных размеров
            var tileFrame = CGRect(
                x: x,
                y: y,
                width: tileWidth,
                height: tileHeight
            )
            
            // Специальная обработка для расширенных плиток
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                tileFrame.size.height = rowHeights[0] + rowHeights[1] + newInnerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileFrame.size.height = rowHeights[0] + rowHeights[1] + newInnerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                tileFrame.size.width = columnWidths[0] + columnWidths[1] + newInnerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileFrame.size.width = columnWidths[0] + columnWidths[1] + newInnerMargin
            }
            
            // Обновляем constraints плитки
            tileView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(tileFrame.origin.x)
                make.top.equalToSuperview().offset(tileFrame.origin.y)
                make.width.equalTo(tileFrame.size.width)
                make.height.equalTo(tileFrame.size.height)
            }
            
            // Перенастраиваем gesture recognizer для тапа на imageView
            if let imageView = tileView.subviews.first as? UIImageView {
                // Удаляем старые gesture recognizers
                imageView.gestureRecognizers?.removeAll()
                
                // Добавляем новый tap gesture
                let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageForTile(_:)))
                imageView.addGestureRecognizer(tapGesture)
                imageView.isUserInteractionEnabled = true
                imageView.tag = index
            }
        }
        
        // ВАЖНО: Обновляем позиции BorderDragView вместо пересоздания (сохраняет состояние)
        updateBorderDragViewPositions(for: template, in: gridContainer)
        
        // Принудительно обновляем layout
        gridContainer.layoutIfNeeded()
        
        // Анимируем изменения
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
        
        print("🔄 Обновлены внутренние и внешние отступы (\(Int(newInnerMargin))px) с сохранением соотношения \(currentAspectRatio.displayName)")
    }
    
    /// Обновляет позиции BorderDragView после изменения размеров сетки
    private func updateBorderDragViewPositions(for template: CollageTemplate, in gridContainer: UIView) {
        // Удаляем старые BorderDragView
        borderViews.forEach { $0.removeFromSuperview() }
        borderViews.removeAll()
        
        // Создаем новые BorderDragView с обновленными позициями
        setupResizableSliders(for: template, in: gridContainer)
    }
    
    // MARK: - Helper Methods
    
    private func constrainImageViewToEditingArea(_ imageView: UIImageView) {
        guard let editingArea = collageView.viewWithTag(1000) else { return }
        
        let editingBounds = editingArea.bounds
        let imageFrame = imageView.frame
        
        // Проверяем, выходит ли изображение за границы области редактирования
        var constrainedFrame = imageFrame
        
        // Ограничиваем по X
        if imageFrame.minX < editingBounds.minX {
            constrainedFrame.origin.x = editingBounds.minX
        } else if imageFrame.maxX > editingBounds.maxX {
            constrainedFrame.origin.x = editingBounds.maxX - imageFrame.width
        }
        
        // Ограничиваем по Y
        if imageFrame.minY < editingBounds.minY {
            constrainedFrame.origin.y = editingBounds.minY
        } else if imageFrame.maxY > editingBounds.maxY {
            constrainedFrame.origin.y = editingBounds.maxY - imageFrame.height
        }
        
        // Применяем ограниченный фрейм если он изменился
        if !constrainedFrame.equalTo(imageFrame) {
            imageView.frame = constrainedFrame
        }
    }
    
    // MARK: - Model Synchronization
    
    private func initializeViewModelWithSelectedPhotos() {
        // Синхронизируем selectedPhotos с viewModel.selectedImages
        for (index, photo) in selectedPhotos.enumerated() {
            let indexPath = IndexPath(item: index, section: 0)
            if photo.size != .zero { // Не добавляем пустые заглушки
                viewModel.setImage(at: indexPath, image: photo)
            }
        }
    }
}
// MARK: - UIScrollViewDelegate
extension CollageEditorViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        // В данном варианте в tileView может отсутствовать UIScrollView,
        // поэтому возвращаем nil или можно вернуть imageView, если tileView содержит его.
        return nil
    }
}

extension UIImage {
    /// Returns an image transformed by the given transform and resized to the specified size.
    func transformed(with transform: CGAffineTransform, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, self.scale)
        defer { UIGraphicsEndImageContext() }
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        context.concatenate(transform)
        self.draw(in: CGRect(origin: .zero, size: size))
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

extension UIView {
    /// Captures a snapshot of the view's current appearance.
    func snapshot() -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(self.bounds.size, false, UIScreen.main.scale)
        defer { UIGraphicsEndImageContext() }
        if self.drawHierarchy(in: self.bounds, afterScreenUpdates: true) {
            return UIGraphicsGetImageFromCurrentImageContext()
        }
        return nil
    }
}

extension Collection {
    /// Returns the element at the specified index if it exists, otherwise nil.
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}

// MARK: - TextEditingPanelDelegate
extension CollageEditorViewController: TextEditingPanelDelegate {
    func textEditingPanel(_ panel: TextEditingPanel, didUpdateText text: String) {
        currentTextLayer?.updateText(text)
    }
    
    func textEditingPanel(_ panel: TextEditingPanel, didSelectColor color: UIColor) {
        currentTextLayer?.updateTextColor(color)
    }
    
    func textEditingPanel(_ panel: TextEditingPanel, didSelectFontSize size: CGFloat) {
        if let currentFont = currentTextLayer?.archTextView.font {
            currentTextLayer?.updateFont(currentFont.withSize(size))
        }
    }
    
        func textEditingPanel(_ panel: TextEditingPanel, didSelectFont fontName: String) {
        currentTextLayer?.updateFontByName(fontName)
    }

    func textEditingPanel(_ panel: TextEditingPanel, didChangeTextAdaptation enabled: Bool) {
        if let textLayer = currentTextLayer {
            textLayer.configureTextAdaptation(
                adjustsFontSize: enabled,
                enablesWrapping: enabled
            )
            // Если адаптация включена, сразу применяем её к текущему тексту
            if enabled {
                textLayer.adaptiveTextView.updateText(textLayer.adaptiveTextView.text)
            }
        }
    }

    func textEditingPanel(_ panel: TextEditingPanel, didChangeTextAlignment alignment: NSTextAlignment) {
        currentTextLayer?.setAdaptiveTextAlignment(alignment)
    }

    func textEditingPanelDidFinish(_ panel: TextEditingPanel) {
        hideTextEditingPanel()
        currentTextLayer?.setSelected(false)
        currentTextLayer = nil
    }
}

// MARK: - BorderDragViewDelegate
extension CollageEditorViewController: BorderDragViewDelegate {
    func borderDragView(_ view: BorderDragView, didChangeRatio ratio: CGFloat) {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag),
              let template = viewModel.collageTemplate.value else { return }
        
        // Сохраняем текущие изображения
        let savedImages = saveCurrentImages()
        
        // Получаем индексы плиток из тега границы
        let index1 = view.tag / 100
        let index2 = view.tag % 100
        
        // Пересчитываем размеры с учетом соотношения сторон
        recalculateGridLayoutWithAspectRatio(template: template, 
                                           gridContainer: gridContainer, 
                                           changedIndex1: index1, 
                                           changedIndex2: index2, 
                                           ratio: ratio)
        
        // Плавная анимация изменений
        UIView.animate(withDuration: 0.15, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            gridContainer.layoutIfNeeded()
        }) { _ in
            // Восстанавливаем изображения после изменения layout
            self.restoreImages(savedImages)
        }
    }
    
    private func recalculateGridLayoutWithAspectRatio(template: CollageTemplate, 
                                                    gridContainer: UIView, 
                                                    changedIndex1: Int, 
                                                    changedIndex2: Int, 
                                                    ratio: CGFloat) {
        
        // Используем текущие значения отступов (синхронизированные с ползунком)
        let innerMargin = currentInnerMargin
        let outerMargin = max(currentInnerMargin, 8)
        
        // Определяем размеры сетки
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        let columns: Int
        let rows: Int
        if specialTemplates.contains(template.name) {
            columns = 2
            rows = 2
        } else {
            columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
            rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        }
        
        // Получаем размер collageView
        let containerWidth = collageView.bounds.width > 0 ? collageView.bounds.width : 200
        let containerHeight = collageView.bounds.height > 0 ? collageView.bounds.height : 200
        
        // Определяем оптимальный размер рабочей области с учетом соотношения сторон
        let availableSize = CGSize(width: containerWidth - 2 * outerMargin, height: containerHeight - 2 * outerMargin)
        let workAreaSize = AspectRatioManager.shared.optimalSize(for: currentAspectRatio, in: availableSize, margin: 0)
        
        // Инициализируем или используем текущие размеры
        var columnWidths = currentColumnWidths
        var rowHeights = currentRowHeights
        
        // Если массивы пустые, инициализируем базовыми значениями
        if columnWidths.isEmpty || rowHeights.isEmpty {
            let totalHorizontalSpacing = innerMargin * CGFloat(columns - 1)
            let totalVerticalSpacing = innerMargin * CGFloat(rows - 1)
            
            let baseColumnWidth = (workAreaSize.width - totalHorizontalSpacing) / CGFloat(columns)
            let baseRowHeight = (workAreaSize.height - totalVerticalSpacing) / CGFloat(rows)
            
            columnWidths = Array(repeating: baseColumnWidth, count: columns)
            rowHeights = Array(repeating: baseRowHeight, count: rows)
        }
        
        // Применяем изменения для конкретной пары плиток
        let pos1 = template.positions[changedIndex1]
        let pos2 = template.positions[changedIndex2]
        
        // Определяем направление изменения
        let isHorizontal = pos1.1 == pos2.1 // Одинаковая строка = горизонтальные соседи
        
        if isHorizontal {
            // Изменяем ширину колонок при сохранении общей ширины
            let totalWidth = columnWidths[pos1.0] + columnWidths[pos2.0]
            let newWidth1 = totalWidth * ratio
            let newWidth2 = totalWidth * (1 - ratio)
            
            // Проверяем, что новые размеры не слишком малы (минимум 20px)
            let minSize: CGFloat = 20
            if newWidth1 >= minSize && newWidth2 >= minSize {
                columnWidths[pos1.0] = newWidth1
                columnWidths[pos2.0] = newWidth2
            }
        } else {
            // Изменяем высоту строк при сохранении общей высоты
            let totalHeight = rowHeights[pos1.1] + rowHeights[pos2.1]
            let newHeight1 = totalHeight * ratio
            let newHeight2 = totalHeight * (1 - ratio)
            
            // Проверяем, что новые размеры не слишком малы (минимум 20px)
            let minSize: CGFloat = 20
            if newHeight1 >= minSize && newHeight2 >= minSize {
                rowHeights[pos1.1] = newHeight1
                rowHeights[pos2.1] = newHeight2
            }
        }
        
        // КРИТИЧНО: Нормализуем размеры чтобы они точно помещались в доступную область
        let totalHorizontalSpacing = innerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = innerMargin * CGFloat(rows - 1)
        let maxAllowedWidth = workAreaSize.width - totalHorizontalSpacing
        let maxAllowedHeight = workAreaSize.height - totalVerticalSpacing
        
        let currentTotalWidth = columnWidths.reduce(0, +)
        let currentTotalHeight = rowHeights.reduce(0, +)
        
        // Масштабируем пропорционально если превышаем границы
        if currentTotalWidth > maxAllowedWidth {
            let scale = maxAllowedWidth / currentTotalWidth
            columnWidths = columnWidths.map { $0 * scale }
        }
        
        if currentTotalHeight > maxAllowedHeight {
            let scale = maxAllowedHeight / currentTotalHeight
            rowHeights = rowHeights.map { $0 * scale }
        }
        
        // Сохраняем обновленные размеры
        currentColumnWidths = columnWidths
        currentRowHeights = rowHeights
        
        // ВАЖНО: Проверяем, что общие размеры не превышают доступную область
        let actualGridWidth = columnWidths.reduce(0, +) + innerMargin * CGFloat(columns - 1)
        let actualGridHeight = rowHeights.reduce(0, +) + innerMargin * CGFloat(rows - 1)
        
        // Используем фактические размеры вместо workAreaSize
        let gridWidth = min(actualGridWidth, workAreaSize.width)
        let gridHeight = min(actualGridHeight, workAreaSize.height)
        
        // Обновляем размер gridContainer с проверкой границ и outerMargin
        gridContainer.snp.remakeConstraints { make in
            make.centerX.equalToSuperview()
            make.centerY.equalToSuperview()
            make.width.equalTo(gridWidth)
            make.height.equalTo(gridHeight)
            // ВАЖНО: Убеждаемся что gridContainer не выходит за пределы с учетом outerMargin
            make.leading.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.trailing.lessThanOrEqualToSuperview().offset(-outerMargin)
            make.top.greaterThanOrEqualToSuperview().offset(outerMargin)
            make.bottom.lessThanOrEqualToSuperview().offset(-outerMargin)
        }
        
        print("📐 Размеры контейнера: ширина=\(gridWidth), высота=\(gridHeight)")
        print("📊 Фактические размеры: ширина=\(actualGridWidth), высота=\(actualGridHeight)")
        
        // Пересоздаем constraints для всех плиток
        for (index, position) in template.positions.enumerated() {
            guard let tileView = gridContainer.viewWithTag(index) else { continue }
            
            _ = position.0
            _ = position.1
            
            // Вычисляем позицию плитки
            var x: CGFloat = 0
            for i in 0..<position.0 {
                x += columnWidths[i] + innerMargin
            }
            
            var y: CGFloat = 0
            for i in 0..<position.1 {
                y += rowHeights[i] + innerMargin
            }
            
            // Базовые размеры плитки
            var tileWidth = columnWidths[position.0]
            var tileHeight = rowHeights[position.1]
            
            // Специальная обработка для расширенных плиток
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                tileHeight = rowHeights[0] + rowHeights[1] + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileHeight = rowHeights[0] + rowHeights[1] + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                tileWidth = columnWidths[0] + columnWidths[1] + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileWidth = columnWidths[0] + columnWidths[1] + innerMargin
            }
            
            // Обновляем constraints плитки
            tileView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(x)
                make.top.equalToSuperview().offset(y)
                make.width.equalTo(tileWidth)
                make.height.equalTo(tileHeight)
            }
        }
        
        // Обновляем позиции границ
        updateBorderPositionsWithAspectRatio(template: template, gridContainer: gridContainer)
        
        print("🔧 Обновлены размеры плиток с соотношением \(currentAspectRatio.displayName), ratio: \(ratio)")
    }
    
    private func updateBorderPositionsWithAspectRatio(template: CollageTemplate, gridContainer: UIView) {
        // Обновляем позиции всех границ с учетом новых размеров
        for borderView in borderViews {
            let index1 = borderView.tag / 100
            let index2 = borderView.tag % 100
            
            guard let tile1 = gridContainer.viewWithTag(index1),
                  let tile2 = gridContainer.viewWithTag(index2) else { continue }
            
            let pos1 = template.positions[index1]
            let pos2 = template.positions[index2]
            
            let isHorizontalNeighbors = abs(pos1.0 - pos2.0) == 1 && pos1.1 == pos2.1
            
            // Пересоздаем constraints для границы
            borderView.snp.remakeConstraints { make in
                if isHorizontalNeighbors {
                    // Вертикальная граница между горизонтальными соседями
                    make.leading.equalTo(tile1.snp.trailing)
                    make.trailing.equalTo(tile2.snp.leading)
                    make.top.equalTo(tile1.snp.top)
                    make.bottom.equalTo(tile1.snp.bottom)
                } else {
                    // Горизонтальная граница между вертикальными соседями
                    make.top.equalTo(tile1.snp.bottom)
                    make.bottom.equalTo(tile2.snp.top)
                    make.leading.equalTo(tile1.snp.leading)
                    make.trailing.equalTo(tile1.snp.trailing)
                }
            }
        }
    }
}

// MARK: - Stickers
extension CollageEditorViewController {
    private func showStickerPicker() {
        let stickerPicker = StickerPickerViewController()
        stickerPicker.delegate = self
        stickerPicker.modalPresentationStyle = .pageSheet
        
        if let sheet = stickerPicker.sheetPresentationController {
            sheet.detents = [.medium(), .large()]
            sheet.prefersGrabberVisible = true
        }
        
        present(stickerPicker, animated: true)
    }
    
    private func addStickerView(with image: UIImage) {
        // Размещаем стикер в центре коллажа
        let centerX = collageView.bounds.width / 2 - 40
        let centerY = collageView.bounds.height / 2 - 40
        
        let stickerView = StickerView(image: image)
        stickerView.frame = CGRect(x: centerX, y: centerY, width: 80, height: 80)
        
        stickerView.onDelete = { [weak self] in
            self?.removeStickerView(stickerView)
        }
        
        stickerView.onTap = { [weak self] in
            self?.selectStickerView(stickerView)
        }
        
        collageView.addSubview(stickerView)
        stickerViews.append(stickerView)
        selectStickerView(stickerView)
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    private func selectStickerView(_ stickerView: StickerView) {
        // Снимаем выделение со всех стикеров
        stickerViews.forEach { $0.setSelected(false) }
        
        // Снимаем выделение с текстовых слоев
        textLayers.forEach { $0.setSelected(false) }
        currentTextLayer = nil
        hideTextEditingPanel()
        
        // Снимаем выделение с изображений
        gestureHandlers.forEach { $0.setSelected(false) }
        selectedImageView = nil
        
        // Выделяем текущий стикер
        stickerView.setSelected(true)
        currentStickerView = stickerView
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    private func removeStickerView(_ stickerView: StickerView) {
        stickerView.removeFromSuperview()
        if let index = stickerViews.firstIndex(of: stickerView) {
            stickerViews.remove(at: index)
        }
        if currentStickerView == stickerView {
            currentStickerView = nil
        }
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    /// Снимает выделение со всех стикеров
    private func deselectAllStickers() {
        stickerViews.forEach { $0.setSelected(false) }
        currentStickerView = nil
    }
}

// MARK: - StickerPickerDelegate
extension CollageEditorViewController: StickerPickerDelegate {
    func stickerPicker(_ picker: StickerPickerViewController, didSelectSticker image: UIImage) {
        addStickerView(with: image)
    }
}

// MARK: - BackgroundPickerDelegate
extension CollageEditorViewController: BackgroundPickerDelegate {
    func backgroundPicker(_ picker: BackgroundPickerViewController, didSelectColor color: UIColor) {
        // Устанавливаем цветной фон
        backgroundImageView.image = nil
        backgroundImageView.backgroundColor = color
    }
    
    func backgroundPicker(_ picker: BackgroundPickerViewController, didSelectImage image: UIImage) {
        // Устанавливаем изображение как фон
        backgroundImageView.backgroundColor = .clear
        backgroundImageView.image = image
    }
    
    func backgroundPickerDidRequestGallery(_ picker: BackgroundPickerViewController) {
        // Сначала закрываем BackgroundPicker, затем открываем галерею
        picker.dismiss(animated: true) { [weak self] in
            DispatchQueue.main.async {
                self?.openImagePickerForBackground()
            }
        }
    }
    
    private func openImagePickerForBackground() {
        let imagePicker = UIImagePickerController()
        imagePicker.delegate = self
        imagePicker.sourceType = .photoLibrary
        imagePicker.allowsEditing = false
        
        // Устанавливаем специальный тег для идентификации изменения фона
        imagePicker.view.tag = 999
        
        present(imagePicker, animated: true, completion: nil)
    }
}

// MARK: - UIImagePickerControllerDelegate
extension CollageEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let selectedImage = info[.originalImage] as? UIImage else { return }
            
            // Проверяем, вызван ли пикер для смены фона
            if picker.view.tag == 999 {
                // Изменяем фон коллажа
                self.backgroundImageView.image = selectedImage
            } else if let indexPath = self.currentIndexPath {
                // Обычное изменение изображения в плитке
                // Обновляем изображение в модели
                self.viewModel.setImage(at: indexPath, image: selectedImage)
                
                // Обновляем UI
                self.updateTileWithNewImage(at: indexPath.item, image: selectedImage)
                
                // Сбрасываем текущий индекс
                self.currentIndexPath = nil
            }
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true) { [weak self] in
            self?.currentIndexPath = nil
        }
    }
    
    private func updateTileWithNewImage(at index: Int, image: UIImage) {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag),
              index < gridContainer.subviews.count,
              let tileView = gridContainer.subviews[safe: index],
              let imageView = tileView.subviews.first(where: { $0 is UIImageView }) as? UIImageView else { return }
        
        // Обновляем изображение в UI
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        imageView.backgroundColor = .clear
        
        // Синхронизируем selectedPhotos массив
        if index < selectedPhotos.count {
            selectedPhotos[index] = image
        } else {
            // Расширяем массив если нужно
            while selectedPhotos.count <= index {
                selectedPhotos.append(UIImage()) // Добавляем пустые заглушки
            }
            selectedPhotos[index] = image
        }
        
        // Удаляем старые жесты
        imageView.gestureRecognizers?.removeAll()
        
        // Создаем новый продвинутый обработчик жестов
        let gestureHandler = AdvancedImageGestureHandler(imageView: imageView, containerView: collageView)
        gestureHandler.delegate = self
        gestureHandlers.append(gestureHandler)
        
        // Обновляем видимость кнопки удаления
        gestureHandler.updateDeleteButtonVisibility()
        
        imageView.isUserInteractionEnabled = true
    }

    // MARK: - Photo Editor Integration
    
    private func openPhotoEditor(with image: UIImage, for imageView: UIImageView) {
        guard image != UIImage(named: "placeholder"),
              let coordinator = coordinator else {
            print("❌ Не удалось открыть PhotoEditor")
            return
        }
        
        print("🎨 Открываем PhotoEditor для редактирования изображения")
        
        if let homeCoordinator = coordinator as? HomeViewCoordinator {
            homeCoordinator.showPhotoEditor(with: image)
        } else {
            // Fallback: show photo editor directly if no coordinator available
            let photoEditorViewModel = PhotoEditorViewModel(image: image)
            let photoEditorVC = PhotoEditorViewController(viewModel: photoEditorViewModel)
            photoEditorVC.modalPresentationStyle = .overFullScreen
            navigationController?.present(photoEditorVC, animated: true)
        }
    }
    
    private func handleEditedImage(_ editedImage: UIImage?, for imageView: UIImageView?) {
        guard let imageView = imageView else { return }
        
        if let editedImage = editedImage {
            print("✅ Получено отредактированное изображение из PhotoEditor")
            
            // Находим индекс изображения для обновления модели
            if let tileView = imageView.superview,
               let gridContainer = self.collageView.viewWithTag(self.gridContainerTag),
               let index = gridContainer.subviews.firstIndex(of: tileView) {
                
                // Обновляем изображение в UI
                imageView.image = editedImage
                
                // Обновляем модель
                let indexPath = IndexPath(item: index, section: 0)
                self.viewModel.setImage(at: indexPath, image: editedImage)
                
                // Обновляем selectedPhotos массив
                if index < self.selectedPhotos.count {
                    self.selectedPhotos[index] = editedImage
                }
                
                print("✅ Изображение обновлено в позиции \(index)")
            }
        } else {
            print("ℹ️ Редактирование отменено пользователем")
        }
    }
    
    // MARK: - Aspect Ratio Selector Methods
    
    private func setupAspectRatioSelector() {
        aspectRatioScrollView.backgroundColor = .systemBackground
        aspectRatioScrollView.showsHorizontalScrollIndicator = false
        aspectRatioScrollView.contentInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        
        aspectRatioStackView.axis = .horizontal
        aspectRatioStackView.spacing = 12
        aspectRatioStackView.alignment = .center
        
        aspectRatioScrollView.addSubview(aspectRatioStackView)
        
        aspectRatioStackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        createAspectRatioButtons()
    }
    
    private func createAspectRatioButtons() {
        aspectRatioButtons.removeAll()
        aspectRatioStackView.arrangedSubviews.forEach { $0.removeFromSuperview() }
        
        for aspectRatio in AspectRatioManager.shared.allRatios {
            let button = createAspectRatioButton(for: aspectRatio)
            aspectRatioButtons.append(button)
            aspectRatioStackView.addArrangedSubview(button)
        }
        
        updateAspectRatioButtonStates()
    }
    
    private func createAspectRatioButton(for aspectRatio: AspectRatio) -> UIButton {
        let button = UIButton(type: .system)
        button.backgroundColor = .systemBackground
        button.layer.cornerRadius = 8
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Создаем контейнер для кнопки
        let containerView = UIView()
        containerView.backgroundColor = .clear
        containerView.isUserInteractionEnabled = false
        
        // Создаем превью соотношения сторон
        let previewView = UIView()
        previewView.backgroundColor = .systemGray5
        previewView.layer.cornerRadius = 4
        previewView.isUserInteractionEnabled = false
        
        // Лейблы
        let titleLabel = UILabel()
        titleLabel.text = aspectRatio.name
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textAlignment = .center
        titleLabel.textColor = .label
        titleLabel.isUserInteractionEnabled = false
        
        let ratioLabel = UILabel()
        ratioLabel.text = aspectRatio.displayName
        ratioLabel.font = UIFont.systemFont(ofSize: 8)
        ratioLabel.textAlignment = .center
        ratioLabel.textColor = .secondaryLabel
        ratioLabel.isUserInteractionEnabled = false
        
        // Добавляем элементы
        button.addSubview(containerView)
        containerView.addSubview(previewView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(ratioLabel)
        
        // Constraints
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        // Вычисляем размер превью с учетом соотношения сторон
        let maxPreviewWidth: CGFloat = 25
        let maxPreviewHeight: CGFloat = 15
        let previewSize = aspectRatio.sizeForWidth(maxPreviewWidth)
        let finalWidth = min(maxPreviewWidth, previewSize.width)
        let finalHeight = min(maxPreviewHeight, previewSize.height)
        
        previewView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.centerX.equalToSuperview()
            make.width.equalTo(finalWidth)
            make.height.equalTo(finalHeight)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(previewView.snp.bottom).offset(3)
            make.leading.trailing.equalToSuperview().inset(2)
        }
        
        ratioLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(1)
            make.leading.trailing.equalToSuperview().inset(2)
            make.bottom.equalToSuperview().offset(-3)
        }
        
        button.snp.makeConstraints { make in
            make.width.equalTo(60)
            make.height.equalTo(60)
        }
        
        // Добавляем действие
        button.addTarget(self, action: #selector(aspectRatioButtonTapped(_:)), for: .touchUpInside)
        button.tag = AspectRatioManager.shared.allRatios.firstIndex(where: { $0.id == aspectRatio.id }) ?? 0
        
        return button
    }
    
    @objc private func aspectRatioButtonTapped(_ sender: UIButton) {
        let aspectRatio = AspectRatioManager.shared.allRatios[sender.tag]
        currentAspectRatio = aspectRatio
        UserDefaults.standard.selectedAspectRatioId = aspectRatio.id
        
        updateAspectRatioButtonStates()
        updateCollageViewAspectRatio()
        
        print("📐 Выбрано соотношение сторон: \(aspectRatio.displayName)")
    }
    
    private func updateAspectRatioButtonStates() {
        for (index, button) in aspectRatioButtons.enumerated() {
            let aspectRatio = AspectRatioManager.shared.allRatios[index]
            let isSelected = aspectRatio.id == currentAspectRatio.id
            
            if isSelected {
                button.layer.borderColor = UIColor.systemBlue.cgColor
                button.layer.borderWidth = 2
                button.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.1)
            } else {
                button.layer.borderColor = UIColor.systemGray4.cgColor
                button.layer.borderWidth = 1
                button.backgroundColor = .systemBackground
            }
        }
    }
    
    private func updateCollageViewAspectRatio() {
        guard let template = viewModel.collageTemplate.value else { return }
        
        // Проверяем, существует ли уже gridContainer
        if collageView.viewWithTag(gridContainerTag) != nil {
            // Если контейнер уже существует, используем быстрое обновление
            let currentImages = saveCurrentImages()
            
            print("🔄 Быстрое обновление соотношения сторон на: \(currentAspectRatio.displayName)")
            
            rebuildCollageLayoutWithAspectRatio(with: template, newInnerMargin: currentInnerMargin)
            
            // Восстанавливаем изображения
            restoreImages(currentImages)
        } else {
            // Если контейнера нет, создаем полностью новый
            print("🔄 Полная инициализация с соотношением: \(currentAspectRatio.displayName)")
            setupCollageView(with: template)
        }
    }
    
    // MARK: - Helper methods for smooth transitions
    
    private func saveCurrentImages() -> [Int: UIImage] {
        var savedImages: [Int: UIImage] = [:]
        
        if let gridContainer = collageView.viewWithTag(gridContainerTag) {
            for (index, subview) in gridContainer.subviews.enumerated() {
                if let imageView = subview.subviews.first(where: { $0 is UIImageView }) as? UIImageView,
                   let image = imageView.image,
                   image != UIImage(named: "placeholder") {
                    savedImages[index] = image
                }
            }
        }
        
        return savedImages
    }
    
    private func restoreImages(_ savedImages: [Int: UIImage]) {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        for (index, image) in savedImages {
            if index < gridContainer.subviews.count,
               let imageView = gridContainer.subviews[index].subviews.first(where: { $0 is UIImageView }) as? UIImageView {
                
                imageView.image = image
                imageView.contentMode = .scaleAspectFill
                
                // Настраиваем жесты для изображения с контентом
                setupImageGestures(for: imageView, at: index)
            }
        }
         }
     
     private func setupImageGestures(for imageView: UIImageView, at index: Int) {
         // Удаляем все существующие жесты
         imageView.gestureRecognizers?.removeAll()
         
         // Создаем новый обработчик жестов
         let gestureHandler = AdvancedImageGestureHandler(imageView: imageView, containerView: collageView)
         gestureHandler.delegate = self
         gestureHandlers.append(gestureHandler)
         
         // Настраиваем интерактивность
         imageView.isUserInteractionEnabled = true
         imageView.tag = index
         
         print("🎯 Настроены жесты для изображения в позиции \(index)")
     }
}

// MARK: - AdvancedImageGestureHandlerDelegate
extension CollageEditorViewController: AdvancedImageGestureHandlerDelegate {
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateTransform transform: CGAffineTransform, for imageView: UIImageView) {
        // Сохраняем трансформацию изображения
        imageView.transform = transform
        
        // Проверяем, не вышло ли изображение за границы
        handler.resetTransformIfNeeded()
        
        // Ограничиваем изображение в пределах квадратной области
        constrainImageViewToEditingArea(imageView)
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didUpdateFrame frame: CGRect, for imageView: UIImageView) {
        // Сохраняем новый фрейм изображения
        imageView.frame = frame
        
        // Проверяем, не вышло ли изображение за границы
        handler.resetTransformIfNeeded()
        
        // Ограничиваем изображение в пределах квадратной области
        constrainImageViewToEditingArea(imageView)
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
    }
    
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didTapImageView imageView: UIImageView) {
        // Снимаем выделение со всех других элементов (кроме текущего)
        gestureHandlers.forEach { gestureHandler in
            if gestureHandler !== handler {
                gestureHandler.setSelected(false)
            }
        }
        textLayers.forEach { $0.setSelected(false) }
        stickerViews.forEach { $0.setSelected(false) }
        currentTextLayer = nil
        currentStickerView = nil
        hideTextEditingPanel()
        
        selectedImageView = imageView
        
        // Убеждаемся, что кнопки остаются доступными
        ensureButtonsOnTop()
        
        // Если изображение пустое (placeholder), открываем выбор изображения
        if imageView.image == UIImage(named: "placeholder") {
            if let tileView = imageView.superview,
               let gridContainer = collageView.viewWithTag(gridContainerTag),
               let index = gridContainer.subviews.firstIndex(of: tileView) {
                currentIndexPath = IndexPath(item: index, section: 0)
                presentImagePicker()
            }
        } else {
            // Для изображений с контентом открываем PhotoEditor
            if let currentImage = imageView.image {
                openPhotoEditor(with: currentImage, for: imageView)
            }
            handler.updateDeleteButtonVisibility()
        }
    }
    
    func gestureHandler(_ handler: AdvancedImageGestureHandler, didDeleteImageView imageView: UIImageView) {
        // Находим индекс изображения
        if let tileView = imageView.superview,
           let gridContainer = collageView.viewWithTag(gridContainerTag),
           let index = gridContainer.subviews.firstIndex(of: tileView) {
            
            // Сбрасываем изображение на placeholder
            imageView.image = UIImage(named: "placeholder")
            imageView.contentMode = .scaleAspectFill
            imageView.backgroundColor = .lightGray
            
            // Скрываем кнопку удаления для placeholder
            handler.updateDeleteButtonVisibility()
            
            // Удаляем из массива выбранных фотографий
            if index < selectedPhotos.count {
                selectedPhotos[index] = UIImage() // Устанавливаем пустое изображение
            }
            
            // Удаляем обработчик жестов
            if let handlerIndex = gestureHandlers.firstIndex(of: handler) {
                gestureHandlers.remove(at: handlerIndex)
            }
            
            // Очищаем жесты
            imageView.gestureRecognizers?.removeAll()
            
            // Добавляем обратно тап для выбора изображения
            let tapGesture = UITapGestureRecognizer(target: self, action: #selector(selectImageForTile(_:)))
            imageView.addGestureRecognizer(tapGesture)
            imageView.tag = index
            imageView.isUserInteractionEnabled = true
            
            print("Изображение удалено из позиции \(index)")
        }
    }
    
    // MARK: - Image Addition with Frame Selection

    /// Показывает выбор изображения с последующим выбором формы рамки
    private func showImagePickerWithFrameSelection() {
        var configuration = PHPickerConfiguration()
        configuration.filter = .images
        configuration.selectionLimit = 1
        
        let picker = PHPickerViewController(configuration: configuration)
        picker.delegate = self
        
        isAddingNewImageWithFrame = true
        present(picker, animated: true)
    }

    /// Показывает выбор формы рамки для выбранного изображения
    private func showFrameSelectionForImage(_ image: UIImage) {
        selectedImageForFraming = image
        
        if framePickerView == nil {
            setupFramePickerForNewImage()
        } else {
            // При повторном показе тоже настраиваем callbacks (на случай если они были сброшены)
            framePickerView?.onShow = { [weak self] in
                self?.hideSaveButtonForFramePicker()
            }
            
            framePickerView?.onHide = { [weak self] in
                self?.showSaveButtonAfterFramePicker()
            }
            
            framePickerView?.show(animated: true)
        }
    }

    /// Настраивает FramePickerView для добавления нового изображения
    private func setupFramePickerForNewImage() {
        framePickerView = FramePickerView()
        framePickerView?.delegate = self
        
        // Настраиваем callbacks для управления кнопкой сохранения
        framePickerView?.onShow = { [weak self] in
            self?.hideSaveButtonForFramePicker()
        }
        
        framePickerView?.onHide = { [weak self] in
            self?.showSaveButtonAfterFramePicker()
        }
        
        if let framePickerView = framePickerView {
            view.addSubview(framePickerView)
            framePickerView.snp.makeConstraints { make in
                make.leading.trailing.bottom.equalToSuperview()
                make.height.equalTo(120)
            }
            view.bringSubviewToFront(framePickerView)
            framePickerView.show(animated: true)
        }
    }

    /// Создает изображение с применённой формой рамки и добавляет его в коллаж
    private func addImageWithFrame(_ image: UIImage, frameShape: FrameShape) {
        let framedImage = createImageWithFrame(image: image, frameShape: frameShape)
        
        let stickerView = StickerView(image: framedImage)
        let centerX = collageView.bounds.midX
        let centerY = collageView.bounds.midY
        stickerView.center = CGPoint(x: centerX, y: centerY)
        
        collageView.addSubview(stickerView)
        stickerViews.append(stickerView)
        
        stickerView.onTap = { [weak self] in
            self?.selectStickerView(stickerView)
        }
        stickerView.onDelete = { [weak self] in
            self?.removeStickerView(stickerView)
        }
        
        framePickerView?.hide(animated: true)
        selectedImageForFraming = nil
        isAddingNewImageWithFrame = false
        ensureButtonsOnTop()
    }

    /// Создает изображение с применённой маской формы
    private func createImageWithFrame(image: UIImage, frameShape: FrameShape) -> UIImage {
        guard frameShape != .none else { return image }
        
        let size = image.size
        UIGraphicsBeginImageContextWithOptions(size, false, image.scale)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return image }
        let bounds = CGRect(origin: .zero, size: size)
        guard let maskPath = frameShape.createPath(in: bounds) else { return image }
        
        context.addPath(maskPath.cgPath)
        context.clip()
        image.draw(in: bounds)
        
        guard let maskedImage = UIGraphicsGetImageFromCurrentImageContext() else { return image }
        return maskedImage
    }
    
    // MARK: - Save Button Management
    
    /// Скрывает кнопку сохранения при показе FramePickerView
    private func hideSaveButtonForFramePicker() {
        saveButton.isHidden = true
    }
    
    /// Показывает кнопку сохранения после скрытия FramePickerView
    private func showSaveButtonAfterFramePicker() {
        saveButton.isHidden = false
    }
}

// MARK: - PHPickerViewControllerDelegate
extension CollageEditorViewController: PHPickerViewControllerDelegate {
    func picker(_ picker: PHPickerViewController, didFinishPicking results: [PHPickerResult]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self else { return }
            
            // Если не добавляем новое изображение с рамкой, ничего не делаем
            guard self.isAddingNewImageWithFrame else { return }
            
            // Если нет результатов (отменили выбор), показываем кнопку сохранения обратно
            guard let result = results.first else {
                self.showSaveButtonAfterFramePicker()
                self.isAddingNewImageWithFrame = false
                return
            }
            
            result.itemProvider.loadObject(ofClass: UIImage.self) { [weak self] (object, error) in
                DispatchQueue.main.async {
                    guard let self = self else { return }
                    
                    // Если не удалось загрузить изображение, показываем кнопку сохранения обратно
                    guard let image = object as? UIImage else {
                        self.showSaveButtonAfterFramePicker()
                        self.isAddingNewImageWithFrame = false
                        return
                    }
                    
                    self.showFrameSelectionForImage(image)
                }
            }
        }
    }
}

// MARK: - FramePickerViewDelegate
extension CollageEditorViewController: FramePickerViewDelegate {
    func framePickerView(_ pickerView: FramePickerView, didSelectFrameShape frameShape: FrameShape) {
        if isAddingNewImageWithFrame, let image = selectedImageForFraming {
            addImageWithFrame(image, frameShape: frameShape)
        }
    }
}
