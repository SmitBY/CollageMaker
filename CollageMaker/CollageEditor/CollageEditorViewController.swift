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

/// View controller for the Collage Editor screen.
/// It is initialized with a CollageEditorViewModel.
class CollageEditorViewController: UIViewController {
    
    weak var coordinator: HomeTabBarCoordinator?
    
    // MARK: - Properties
    
    /// The view model for the editor screen.
    private let viewModel: CollageEditorViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    private let collageView = UIView()
    private let saveButton = UIButton(type: .system)
    private let addTextButton = UIButton(type: .system)
    
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
    private var borderViews: [BorderDragView] = [] // Границы для изменения размеров
    private var currentTextLayer: TextLayerView?
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
        super.init(nibName: nil, bundle: nil)
        print("[CollageEditorViewController] init(viewModel:) called")
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
        
        if let template = viewModel.collageTemplate.value {
            setupCollageView(with: template)
            // Сначала инициализируем модель с выбранными фотографиями
            initializeViewModelWithSelectedPhotos()
            fillCollageWithSelectedPhotos()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        title = "Редактор коллажа"
        
        // Настройка кнопки сохранения
        saveButton.setTitle("Сохранить", for: .normal)
        saveButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        saveButton.backgroundColor = .systemBlue
        saveButton.setTitleColor(.white, for: .normal)
        saveButton.layer.cornerRadius = 8
        
        // Настройка кнопки добавления текста
        addTextButton.setTitle("+ Текст", for: .normal)
        addTextButton.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        addTextButton.backgroundColor = .systemGreen
        addTextButton.setTitleColor(.white, for: .normal)
        addTextButton.layer.cornerRadius = 8
        
        // Настройка области коллажа
        collageView.backgroundColor = .lightGray
        collageView.layer.cornerRadius = 12
        collageView.clipsToBounds = true
        
        // Настройка контейнера для ползунков
        slidersContainerView.backgroundColor = .systemBackground
        slidersContainerView.layer.cornerRadius = 8
        slidersContainerView.layer.borderWidth = 1
        slidersContainerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Добавляем элементы на view
        view.addSubview(collageView)
        view.addSubview(slidersContainerView)
        view.addSubview(saveButton)
        view.addSubview(addTextButton)
        
        // Добавляем ползунки в контейнер
        slidersContainerView.addSubview(cornerRadiusLabel)
        slidersContainerView.addSubview(cornerRadiusSlider)
        slidersContainerView.addSubview(spacingLabel)
        slidersContainerView.addSubview(spacingSlider)
        
        // Настройка constraints
        collageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(slidersContainerView.snp.top).offset(-10)
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
        
        // Добавляем тень для лучшей видимости
        saveButton.layer.shadowColor = UIColor.black.cgColor
        saveButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        saveButton.layer.shadowOpacity = 0.3
        saveButton.layer.shadowRadius = 4
        
        addTextButton.layer.shadowColor = UIColor.black.cgColor
        addTextButton.layer.shadowOffset = CGSize(width: 0, height: 2)
        addTextButton.layer.shadowOpacity = 0.3
        addTextButton.layer.shadowRadius = 4
        
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
                  let imageView = tileView.subviews.first as? UIImageView else { continue }
            
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
    
    private func presentImagePicker() {
        let imagePickerController = UIImagePickerController()
        imagePickerController.delegate = self
        imagePickerController.sourceType = .photoLibrary
        imagePickerController.allowsEditing = false
        present(imagePickerController, animated: true, completion: nil)
    }
    
    // MARK: - Collage View Setup
    
    /// Configures the collage view based on the provided template.
    /// The preview displays a grid of square tiles with white borders and placeholder images,
    /// centered in collageView. Special templates (2x2 grid with one tile stretched) обрабатываются.
    private func setupCollageView(with template: CollageTemplate) {
        // Очищаем старый коллаж
        collageView.subviews.forEach { $0.removeFromSuperview() }
        
        // Сбрасываем сохраненные размеры сетки
        currentColumnWidths.removeAll()
        currentRowHeights.removeAll()
        
        // Force layout update to obtain correct bounds.
        view.layoutIfNeeded()
        print("Setting up collage view with template: \(template.name)")
        
        // Define margins.
        let outerMargin: CGFloat = 16
        let innerMargin: CGFloat = 8
        
        // Определяем, является ли шаблон специальным.
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        let columns: Int
        let rows: Int
        if specialTemplates.contains(template.name) {
            // Для специальных шаблонов считаем фиксированную сетку 2x2.
            columns = 2
            rows = 2
        } else {
            columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
            rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        }
        
        // Получаем размер collageView и создаем квадратную область
        let containerWidth = collageView.bounds.width > 0 ? collageView.bounds.width : 200
        let containerHeight = collageView.bounds.height > 0 ? collageView.bounds.height : 200
        
        // Определяем размер квадратной области (минимальная сторона минус отступы)
        let maxAvailableSize = min(containerWidth, containerHeight) - 2 * outerMargin
        
        // Вычисляем размер стандартной плитки для квадратной сетки
        let totalHorizontalSpacing = innerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = innerMargin * CGFloat(rows - 1)
        let tileSide = min((maxAvailableSize - totalHorizontalSpacing) / CGFloat(columns),
                           (maxAvailableSize - totalVerticalSpacing) / CGFloat(rows))
        
        // Размер всей сетки (квадрат).
        let gridContentWidth = CGFloat(columns) * tileSide + totalHorizontalSpacing
        let gridContentHeight = CGFloat(rows) * tileSide + totalVerticalSpacing
        let gridSize = max(gridContentWidth, gridContentHeight) + 2 * outerMargin
        
        // Создаем контейнер для сетки и центрируем его в collageView.
        let gridContainer = UIView()
        gridContainer.backgroundColor = .clear
        gridContainer.layer.borderColor = UIColor.lightGray.cgColor
        gridContainer.layer.borderWidth = 1
        gridContainer.layer.cornerRadius = 8
        gridContainer.tag = gridContainerTag
        collageView.addSubview(gridContainer)
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(gridSize) // Квадратный контейнер
        }
        
        // Вычисляем смещения для центрирования содержимого в квадрате
        let contentOffsetX = (gridSize - gridContentWidth) / 2
        let contentOffsetY = (gridSize - gridContentHeight) / 2
        
        // Для каждого элемента шаблона создаем tileView.
        for (index, position) in template.positions.enumerated() {
            let col = CGFloat(position.0)
            let row = CGFloat(position.1)
            
            // Начальный расчет: каждая плитка стандартного размера с центрированием
            var tileFrame = CGRect(x: contentOffsetX + col * (tileSide + innerMargin),
                                   y: contentOffsetY + row * (tileSide + innerMargin),
                                   width: tileSide,
                                   height: tileSide)
            
            // Специальная обработка для шаблонов:
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                // Левая плитка растягивается по высоте (занимает 2 ряда).
                tileFrame.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileFrame.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                // Верхняя плитка растягивается по ширине (занимает 2 столбца).
                tileFrame.size.width = tileSide * 2 + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileFrame.size.width = tileSide * 2 + innerMargin
            }
            
            let tileView = UIView()
            tileView.backgroundColor = .clear
            tileView.layer.borderColor = UIColor.white.cgColor
            tileView.layer.borderWidth = 1.0
            tileView.layer.cornerRadius = 4.0
            tileView.clipsToBounds = true
            tileView.tag = index // Устанавливаем тег для идентификации
            
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
            
            gridContainer.addSubview(tileView)
            
            // Устанавливаем constraints для плитки
            tileView.snp.makeConstraints { make in
                make.left.equalToSuperview().offset(tileFrame.origin.x)
                make.top.equalToSuperview().offset(tileFrame.origin.y)
                make.width.equalTo(tileFrame.size.width)
                make.height.equalTo(tileFrame.size.height)
            }
        }
        
        // Инициализируем базовые размеры сетки
        initializeGridSizes(for: template, containerSize: CGSize(width: maxAvailableSize, height: maxAvailableSize))
        
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
        let outerMargin: CGFloat = 16
        let innerMargin: CGFloat = 8
        
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
        
        // Определяем, где нужны границы (между соседними фотографиями)
        for i in 0..<template.positions.count {
            for j in (i+1)..<template.positions.count {
                let pos1 = template.positions[i]
                let pos2 = template.positions[j]
                
                // Проверяем, являются ли фото соседними
                let isHorizontalNeighbors = abs(pos1.0 - pos2.0) == 1 && pos1.1 == pos2.1
                let isVerticalNeighbors = abs(pos1.1 - pos2.1) == 1 && pos1.0 == pos2.0
                
                if isHorizontalNeighbors || isVerticalNeighbors {
                    guard let tile1 = gridContainer.viewWithTag(i),
                          let tile2 = gridContainer.viewWithTag(j) else { continue }
                    
                    let borderView = BorderDragView()
                    borderView.isVertical = isHorizontalNeighbors
                    borderView.delegate = self
                    borderView.tag = i * 100 + j // Уникальный тег для идентификации
                    
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
                }
            }
        }
    }
    
    // MARK: - Text Layers
    
    private func addTextLayer() {
        // Размещаем текстовый слой в центре квадратной области
        let centerX = collageView.bounds.width / 2 - 100
        let centerY = collageView.bounds.height / 2 - 25
        
        let textLayer = TextLayerView(frame: CGRect(x: centerX, y: centerY, width: 200, height: 50))
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
        
        // Если не попали ни в текст, ни в изображение, снимаем все выделения
        if !hitTextLayer && !hitImage {
            deselectAllTextLayers()
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
        
        panel.show(with: textLayer.archTextView.text)
        textEditingPanel = panel
        
        // Убеждаемся, что кнопки остаются доступными после добавления панели
        ensureButtonsOnTop()
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
        
        // Final collage image size: 2400 x 2400 pixels (квадрат).
        let finalCollageSize = CGSize(width: 2400, height: 2400)
        
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
        
        // Fill background with white.
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: finalCollageSize))
        
        // Вычисляем масштаб для перевода из текущих размеров в финальные
        let currentGridSize = gridContainer.bounds.size
        let scale = finalCollageSize.width / max(currentGridSize.width, currentGridSize.height)
        
        // Вычисляем смещение для центрирования в квадрате
        let offsetX = (finalCollageSize.width - currentGridSize.width * scale) / 2
        let offsetY = (finalCollageSize.height - currentGridSize.height * scale) / 2
        
        // Получаем текущее значение закругления углов
        let currentCornerRadius = CGFloat(cornerRadiusSlider.value)
        
        // Для каждого элемента шаблона.
        for (index, _) in template.positions.enumerated() {
            // Получаем текущую плитку из UI
            guard let tileView = gridContainer.subviews[safe: index],
                  let imageView = tileView.subviews.first as? UIImageView
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
            
            // Рисуем белую рамку поверх с текущим закруглением
            let borderPath = UIBezierPath(roundedRect: scaledTileFrame, cornerRadius: currentCornerRadius * scale)
            UIColor.white.setStroke()
            borderPath.lineWidth = 2.0 * scale
            borderPath.stroke()
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
        
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            // Сохраняем в фотоальбом
            UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            
            // Сохраняем в галерею приложения
            let templateName = viewModel.collageTemplate.value?.name ?? "Неизвестный шаблон"
            let savedCollage = SavedCollage(image: finalImage, templateName: templateName)
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
            self?.coordinator?.showGallery()
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
        
        // Перестраиваем layout коллажа с новым расстоянием
        if let template = viewModel.collageTemplate.value {
            rebuildCollageLayout(with: template, newInnerMargin: spacing)
        }
    }
    
    private func rebuildCollageLayout(with template: CollageTemplate, newInnerMargin: CGFloat) {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        let outerMargin: CGFloat = 16
        
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
        
        // Определяем размер квадратной области
        let maxAvailableSize = min(containerWidth, containerHeight) - 2 * outerMargin
        
        // Вычисляем размер стандартной плитки с новым расстоянием
        let totalHorizontalSpacing = newInnerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = newInnerMargin * CGFloat(rows - 1)
        let tileSide = min((maxAvailableSize - totalHorizontalSpacing) / CGFloat(columns),
                           (maxAvailableSize - totalVerticalSpacing) / CGFloat(rows))
        
        // Размер всей сетки
        let gridContentWidth = CGFloat(columns) * tileSide + totalHorizontalSpacing
        let gridContentHeight = CGFloat(rows) * tileSide + totalVerticalSpacing
        let gridSize = max(gridContentWidth, gridContentHeight) + 2 * outerMargin
        
        // Обновляем размер gridContainer
        gridContainer.snp.updateConstraints { make in
            make.width.height.equalTo(gridSize)
        }
        
        // Вычисляем смещения для центрирования содержимого в квадрате
        let contentOffsetX = (gridSize - gridContentWidth) / 2
        let contentOffsetY = (gridSize - gridContentHeight) / 2
        
        // Обновляем позиции всех плиток
        for (index, position) in template.positions.enumerated() {
            guard let tileView = gridContainer.subviews[safe: index] else { continue }
            
            let col = CGFloat(position.0)
            let row = CGFloat(position.1)
            
            // Начальный расчет
            var tileFrame = CGRect(x: contentOffsetX + col * (tileSide + newInnerMargin),
                                   y: contentOffsetY + row * (tileSide + newInnerMargin),
                                   width: tileSide,
                                   height: tileSide)
            
            // Специальная обработка для шаблонов
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                tileFrame.size.height = tileSide * 2 + newInnerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileFrame.size.height = tileSide * 2 + newInnerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                tileFrame.size.width = tileSide * 2 + newInnerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileFrame.size.width = tileSide * 2 + newInnerMargin
            }
            
            // Обновляем constraints плитки
            tileView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(tileFrame.origin.x)
                make.top.equalToSuperview().offset(tileFrame.origin.y)
                make.width.equalTo(tileFrame.size.width)
                make.height.equalTo(tileFrame.size.height)
            }
        }
        
        // Анимируем изменения
        UIView.animate(withDuration: 0.3) {
            self.view.layoutIfNeeded()
        }
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
        
        // Получаем индексы плиток из тега границы
        let index1 = view.tag / 100
        let index2 = view.tag % 100
        
        let pos1 = template.positions[index1]
        let pos2 = template.positions[index2]
        
        // Определяем направление изменения размера
        let isHorizontal = pos1.1 == pos2.1
        
        // Пересчитываем размеры всей сетки
        recalculateGridLayout(template: template, 
                            gridContainer: gridContainer, 
                            changedIndex1: index1, 
                            changedIndex2: index2, 
                            ratio: ratio, 
                            isHorizontal: isHorizontal)
        
        // Плавная анимация изменений
        UIView.animate(withDuration: 0.1, delay: 0, options: [.allowUserInteraction, .beginFromCurrentState], animations: {
            gridContainer.layoutIfNeeded()
        })
    }
    
    private func recalculateGridLayout(template: CollageTemplate, 
                                     gridContainer: UIView, 
                                     changedIndex1: Int, 
                                     changedIndex2: Int, 
                                     ratio: CGFloat, 
                                     isHorizontal: Bool) {
        
        let outerMargin: CGFloat = 16
        let innerMargin: CGFloat = 8
        
        // Используем текущие размеры вместо пересчета с нуля
        var columnWidths = currentColumnWidths
        var rowHeights = currentRowHeights
        
        // Если массивы пустые (первый запуск), инициализируем их
        if columnWidths.isEmpty || rowHeights.isEmpty {
            let containerSize = gridContainer.bounds.size
            initializeGridSizes(for: template, containerSize: containerSize)
            columnWidths = currentColumnWidths
            rowHeights = currentRowHeights
        }
        
        // Применяем изменения для конкретной пары плиток
        let pos1 = template.positions[changedIndex1]
        let pos2 = template.positions[changedIndex2]
        
        if isHorizontal {
            // Изменяем ширину колонок
            let totalWidth = columnWidths[pos1.0] + columnWidths[pos2.0]
            columnWidths[pos1.0] = totalWidth * ratio
            columnWidths[pos2.0] = totalWidth * (1 - ratio)
        } else {
            // Изменяем высоту строк
            let totalHeight = rowHeights[pos1.1] + rowHeights[pos2.1]
            rowHeights[pos1.1] = totalHeight * ratio
            rowHeights[pos2.1] = totalHeight * (1 - ratio)
        }
        
        // ВАЖНО: Поддерживаем квадратную форму сетки
        // Вычисляем общие размеры сетки
        let totalGridWidth = columnWidths.reduce(0, +) + innerMargin * CGFloat(columnWidths.count - 1)
        let totalGridHeight = rowHeights.reduce(0, +) + innerMargin * CGFloat(rowHeights.count - 1)
        
        // Определяем максимальный размер для квадрата
        let maxAvailableSize = min(collageView.bounds.width, collageView.bounds.height) - 2 * outerMargin
        let currentMaxSize = max(totalGridWidth, totalGridHeight)
        
        // Если сетка превышает максимальный размер или не квадратная, масштабируем
        if currentMaxSize > maxAvailableSize {
            let scale = maxAvailableSize / currentMaxSize
            
            // Применяем масштабирование ко всем размерам
            for i in 0..<columnWidths.count {
                columnWidths[i] *= scale
            }
            for i in 0..<rowHeights.count {
                rowHeights[i] *= scale
            }
        }
        
        // Пересчитываем финальные размеры сетки
        let finalGridWidth = outerMargin * 2 + columnWidths.reduce(0, +) + innerMargin * CGFloat(columnWidths.count - 1)
        let finalGridHeight = outerMargin * 2 + rowHeights.reduce(0, +) + innerMargin * CGFloat(rowHeights.count - 1)
        
        // Обеспечиваем квадратную форму - используем максимальный размер для обеих сторон
        let squareSize = max(finalGridWidth, finalGridHeight)
        
        // Сохраняем обновленные размеры
        currentColumnWidths = columnWidths
        currentRowHeights = rowHeights
        
        // Обновляем размер gridContainer как квадрат
        gridContainer.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(squareSize)
        }
        
        // Пересоздаем constraints для всех плиток
        for (index, position) in template.positions.enumerated() {
            guard let tileView = gridContainer.viewWithTag(index) else { continue }
            
            let col = position.0
            let row = position.1
            
            // Вычисляем позицию плитки с центрированием в квадрате
            let contentWidth = columnWidths.reduce(0, +) + innerMargin * CGFloat(columnWidths.count - 1)
            let contentHeight = rowHeights.reduce(0, +) + innerMargin * CGFloat(rowHeights.count - 1)
            
            let offsetX = (squareSize - contentWidth) / 2
            let offsetY = (squareSize - contentHeight) / 2
            
            var x: CGFloat = offsetX
            for i in 0..<col {
                x += columnWidths[i] + innerMargin
            }
            
            var y: CGFloat = offsetY
            for i in 0..<row {
                y += rowHeights[i] + innerMargin
            }
            
            let width = columnWidths[col]
            let height = rowHeights[row]
            
            // Специальная обработка для растянутых плиток
            var finalWidth = width
            var finalHeight = height
            
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                finalHeight = rowHeights[0] + rowHeights[1] + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                finalHeight = rowHeights[0] + rowHeights[1] + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                finalWidth = columnWidths[0] + columnWidths[1] + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                finalWidth = columnWidths[0] + columnWidths[1] + innerMargin
            }
            
            // Пересоздаем constraints
            tileView.snp.remakeConstraints { make in
                make.left.equalToSuperview().offset(x)
                make.top.equalToSuperview().offset(y)
                make.width.equalTo(finalWidth)
                make.height.equalTo(finalHeight)
            }
        }
        
        // Обновляем позиции границ
        updateBorderPositions(template: template, gridContainer: gridContainer)
    }
    
    private func updateBorderPositions(template: CollageTemplate, gridContainer: UIView) {
        // Обновляем позиции всех границ
        for borderView in borderViews {
            let index1 = borderView.tag / 100
            let index2 = borderView.tag % 100
            
            guard let tile1 = gridContainer.viewWithTag(index1),
                  let tile2 = gridContainer.viewWithTag(index2) else { continue }
            
            let pos1 = template.positions[index1]
            let pos2 = template.positions[index2]
            
            let isHorizontalNeighbors = abs(pos1.0 - pos2.0) == 1 && pos1.1 == pos2.1
            
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

// MARK: - UIImagePickerControllerDelegate
extension CollageEditorViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: true) { [weak self] in
            guard let self = self,
                  let selectedImage = info[.originalImage] as? UIImage,
                  let indexPath = self.currentIndexPath else { return }
            
            // Обновляем изображение в модели
            self.viewModel.setImage(at: indexPath, image: selectedImage)
            
            // Обновляем UI
            self.updateTileWithNewImage(at: indexPath.item, image: selectedImage)
            
            // Сбрасываем текущий индекс
            self.currentIndexPath = nil
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
              let imageView = tileView.subviews.first as? UIImageView else { return }
        
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
        
        imageView.isUserInteractionEnabled = true
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
}
