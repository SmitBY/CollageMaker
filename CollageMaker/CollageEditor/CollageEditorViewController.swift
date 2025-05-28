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
    let viewModel: CollageEditorViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    let collageView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        return view
    }()
    
    let saveButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Сохранить", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.setTitleColor(.white, for: .normal)
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 12
        return button
    }()
    
    let addTextButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "textformat"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = .systemBlue
        button.layer.cornerRadius = 22
        return button
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
    
    /// Stores the currently selected image's index path (for image picker usage)
    private var currentIndexPath: IndexPath?
    
    // We'll store gridContainer's tag for later retrieval.
    private let gridContainerTag = 999
    
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
            fillCollageWithSelectedPhotos()
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        view.backgroundColor = .systemGray6
        
        // Добавляем элементы интерфейса
        view.addSubview(collageView)
        view.addSubview(saveButton)
        view.addSubview(addTextButton)
        
        // Настройка квадратной области редактирования
        setupSquareEditingArea()
        
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }
        
        addTextButton.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(saveButton.snp.top).offset(-20)
            make.size.equalTo(44)
        }
    }
    
    private func setupSquareEditingArea() {
        // Вычисляем размер квадратной области
        let screenWidth = UIScreen.main.bounds.width
        let margin: CGFloat = 20
        let availableWidth = screenWidth - (margin * 2)
        
        // Учитываем высоту для кнопок снизу
        let buttonAreaHeight: CGFloat = 120 // кнопка сохранить + отступы + кнопка текста
        let topMargin: CGFloat = 20
        let availableHeight = view.bounds.height - view.safeAreaInsets.top - view.safeAreaInsets.bottom - buttonAreaHeight - topMargin
        
        // Берем минимальное значение для создания квадрата
        let squareSize = min(availableWidth, availableHeight)
        
        // Настраиваем collageView как квадратную область
        collageView.backgroundColor = .white
        collageView.layer.cornerRadius = 12
        collageView.layer.borderWidth = 2
        collageView.layer.borderColor = UIColor.systemBlue.cgColor
        collageView.layer.shadowColor = UIColor.black.cgColor
        collageView.layer.shadowOffset = CGSize(width: 0, height: 2)
        collageView.layer.shadowRadius = 8
        collageView.layer.shadowOpacity = 0.1
        collageView.clipsToBounds = true
        
        collageView.snp.makeConstraints { make in
            make.centerX.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(topMargin)
            make.width.height.equalTo(squareSize)
        }
    }
    
    private func fillCollageWithSelectedPhotos() {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        for (index, photo) in selectedPhotos.enumerated() {
            if index < gridContainer.subviews.count,
               let tileView = gridContainer.subviews[safe: index] as? UIView,
               let imageView = tileView.subviews.first as? UIImageView {
                
                // Проверяем, является ли изображение пустым (заглушкой)
                if photo.size == .zero {
                    // Устанавливаем placeholder и добавляем возможность выбора
                    imageView.image = UIImage(named: "placeholder")
                    imageView.contentMode = .scaleAspectFill
                    
                    // Добавляем кнопку "+" для выбора изображения
                    let addButton = UIButton(type: .system)
                    addButton.setImage(UIImage(systemName: "plus.circle.fill"), for: .normal)
                    addButton.tintColor = .systemBlue
                    addButton.backgroundColor = .white
                    addButton.layer.cornerRadius = 20
                    addButton.tag = index
                    
                    tileView.addSubview(addButton)
                    addButton.snp.makeConstraints { make in
                        make.center.equalToSuperview()
                        make.size.equalTo(40)
                    }
                    
                    addButton.addTarget(self, action: #selector(addImageButtonTapped(_:)), for: .touchUpInside)
                } else {
                    // Обычное изображение
                    imageView.image = photo
                    imageView.contentMode = .scaleAspectFill
                    
                    let indexPath = IndexPath(item: index, section: 0)
                    viewModel.setImage(at: indexPath, image: photo)
                }
            }
        }
    }
    
    @objc private func addImageButtonTapped(_ sender: UIButton) {
        currentIndexPath = IndexPath(item: sender.tag, section: 0)
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
        
        // Получаем размер collageView.
        let containerWidth = collageView.bounds.width > 0 ? collageView.bounds.width : 200
        let containerHeight = collageView.bounds.height > 0 ? collageView.bounds.height : 200
        
        // Вычисляем общую площадь для плиток с учётом внешних и внутренних отступов.
        let totalHorizontalSpacing = outerMargin * 2 + innerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = outerMargin * 2 + innerMargin * CGFloat(rows - 1)
        let tileSide = min((containerWidth - totalHorizontalSpacing) / CGFloat(columns),
                           (containerHeight - totalVerticalSpacing) / CGFloat(rows))
        
        // Размер стандартной плитки (квадрат).
        let standardTileSize = CGSize(width: tileSide, height: tileSide)
        
        // Размер всей сетки.
        let gridWidth = outerMargin * 2 + CGFloat(columns) * tileSide + innerMargin * CGFloat(columns - 1)
        let gridHeight = outerMargin * 2 + CGFloat(rows) * tileSide + innerMargin * CGFloat(rows - 1)
        let gridSize = CGSize(width: gridWidth, height: gridHeight)
        
        // Создаем контейнер для сетки и центрируем его в collageView.
        let gridContainer = UIView()
        gridContainer.backgroundColor = .clear
        // Для дальнейшего сохранения можем задать тег, если понадобится.
        gridContainer.tag = 999
        collageView.addSubview(gridContainer)
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(gridSize)
        }
        
        // Для каждого элемента шаблона создаем tileView.
        for (index, position) in template.positions.enumerated() {
            let col = CGFloat(position.0)
            let row = CGFloat(position.1)
            
            // Начальный расчет: каждая плитка стандартного размера.
            var tileFrame = CGRect(x: outerMargin + col * (tileSide + innerMargin),
                                   y: outerMargin + row * (tileSide + innerMargin),
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
            
            // Убираем tap gesture, так как теперь фотографии выбираются автоматически
            tileView.isUserInteractionEnabled = true
            
            // Добавляем редактирующие жесты к imageView (для перемещения, масштабирования, вращения).
            imageView.isUserInteractionEnabled = true
            let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
            let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
            let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
            imageView.addGestureRecognizer(panGesture)
            imageView.addGestureRecognizer(pinchGesture)
            imageView.addGestureRecognizer(rotationGesture)
            
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
        initializeGridSizes(for: template, containerSize: CGSize(width: containerWidth, height: containerHeight))
        
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
    }
    
    private func selectTextLayer(_ textLayer: TextLayerView) {
        // Снимаем выделение со всех текстовых слоев
        textLayers.forEach { $0.setSelected(false) }
        
        // Выделяем текущий
        textLayer.setSelected(true)
        currentTextLayer = textLayer
        
        // Показываем панель редактирования
        showTextEditingPanel(for: textLayer)
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
    }
    
    private func showTextEditingPanel(for textLayer: TextLayerView) {
        hideTextEditingPanel()
        
        let panel = TextEditingPanel()
        panel.delegate = self
        view.addSubview(panel)
        panel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        panel.show(with: textLayer.archTextView.text)
        textEditingPanel = panel
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
        
        // Final collage image size: 2400 x 2400 pixels.
        let finalCollageSize = CGSize(width: 2400, height: 2400)
        
        // Define margins.
        let outerMargin: CGFloat = 16
        let innerMargin: CGFloat = 8
        
        // Determine grid dimensions.
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
        
        // Calculate available space for tiles in the final image.
        let availableWidth = finalCollageSize.width - 2 * outerMargin - CGFloat(columns - 1) * innerMargin
        let availableHeight = finalCollageSize.height - 2 * outerMargin - CGFloat(rows - 1) * innerMargin
        
        // Calculate side length of each square tile.
        let tileSide = min(availableWidth / CGFloat(columns), availableHeight / CGFloat(rows))
        
        // Overall grid size.
        let gridWidth = outerMargin * 2 + CGFloat(columns) * tileSide + innerMargin * CGFloat(columns - 1)
        let gridHeight = outerMargin * 2 + CGFloat(rows) * tileSide + innerMargin * CGFloat(rows - 1)
        let gridSize = CGSize(width: gridWidth, height: gridHeight)
        
        // Calculate offsets to center the grid in the final image.
        let offsetX = (finalCollageSize.width - gridWidth) / 2
        let offsetY = (finalCollageSize.height - gridHeight) / 2
        
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
        
        // Получаем gridContainer, который создавался в setupCollageView (его tag установлен, например, равен gridContainerTag).
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else {
            print("Failed to retrieve grid container")
            return
        }
        gridContainer.layoutIfNeeded()
        // Получаем его frame относительно collageView.
        let gridFrame = collageView.convert(gridContainer.frame, from: gridContainer.superview)
        
        // Общие смещения для центрирования.
        let totalOffsetX = gridFrame.origin.x + offsetX
        let totalOffsetY = gridFrame.origin.y + offsetY
        
        // Для каждого элемента шаблона.
        for (index, position) in template.positions.enumerated() {
            let col = CGFloat(position.0)
            let row = CGFloat(position.1)
            
            // Базовый прямоугольник для стандартной плитки.
            var drawRect = CGRect(x: outerMargin + col * (tileSide + innerMargin),
                                  y: outerMargin + row * (tileSide + innerMargin),
                                  width: tileSide,
                                  height: tileSide)
            // Специальная обработка для некоторых шаблонов.
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                drawRect.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                drawRect.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                drawRect.size.width = tileSide * 2 + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                drawRect.size.width = tileSide * 2 + innerMargin
            }
            
            // Смещаем drawRect для центрирования.
            drawRect.origin.x += offsetX
            drawRect.origin.y += offsetY
            
            // Получаем индекс элемента.
            let indexPath = IndexPath(item: index, section: 0)
            
            // Получаем изображение для элемента (если пользователь выбрал его, иначе placeholder).
            let imageToDraw = viewModel.getImage(at: indexPath) ?? UIImage(named: "placeholder")
            guard let img = imageToDraw else { continue }
            
            // Извлекаем пользовательскую трансформацию.
            // Предполагаем, что в gridContainer плитки добавлялись с tileView.tag = index,
            // и внутри tileView первым subview является imageView, к которому применяются трансформации.
            guard let tileView = gridContainer.subviews[safe: index],
                  let imageView = tileView.subviews.first as? UIImageView
            else {
                print("Failed to retrieve tile view or image view for index \(index)")
                continue
            }
            let userTransform = imageView.transform
            
            // Применяем clipping path с округлением.
            context.saveGState()
            // Создаем clipping path с округленными краями.
            let roundedPath = UIBezierPath(roundedRect: drawRect, cornerRadius: 16)
            roundedPath.addClip()
            
            // Перемещаем контекст в центр drawRect.
            let center = CGPoint(x: drawRect.midX, y: drawRect.midY)
            context.translateBy(x: center.x, y: center.y)
            // Применяем пользовательскую трансформацию.
            context.concatenate(userTransform)
            // Рисуем изображение так, чтобы его центр совпадал с (0,0) в трансформированном контексте.
            let transformedDrawingRect = CGRect(x: -drawRect.width / 2, y: -drawRect.height / 2, width: drawRect.width, height: drawRect.height)
            img.draw(in: transformedDrawingRect)
            context.restoreGState()
            
            // Отрисовываем белую рамку с округленными углами поверх.
            let borderPath = UIBezierPath(roundedRect: drawRect, cornerRadius: 16)
            UIColor.white.setStroke()
            borderPath.lineWidth = 1.0
            borderPath.stroke()
        }
        
        // Рисуем текстовые слои поверх коллажа
        for textLayer in textLayers {
            context.saveGState()
            
            // Конвертируем координаты текстового слоя
            let textFrame = collageView.convert(textLayer.frame, from: textLayer.superview)
            let scale = finalCollageSize.width / collageView.bounds.width
            
            let scaledFrame = CGRect(
                x: textFrame.origin.x * scale,
                y: textFrame.origin.y * scale,
                width: textFrame.width * scale,
                height: textFrame.height * scale
            )
            
            // Применяем трансформацию текстового слоя
            context.translateBy(x: scaledFrame.midX, y: scaledFrame.midY)
            context.concatenate(textLayer.transform)
            
            // Рисуем текст
            let attributes: [NSAttributedString.Key: Any] = [
                .font: textLayer.archTextView.font.withSize(textLayer.archTextView.font.pointSize * scale),
                .foregroundColor: textLayer.archTextView.textColor
            ]
            
            let text = textLayer.archTextView.text
            let textSize = text.size(withAttributes: attributes)
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
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView,
              let tileView = imageView.superview else { return }
        
        let translation = gesture.translation(in: tileView)
        let newCenter = CGPoint(x: imageView.center.x + translation.x,
                               y: imageView.center.y + translation.y)
        
        // Ограничиваем движение в пределах плитки
        let constrainedCenter = constrainImageViewCenter(newCenter, 
                                                        imageView: imageView, 
                                                        containerView: tileView)
        
        imageView.center = constrainedCenter
        gesture.setTranslation(.zero, in: tileView)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView,
              let tileView = imageView.superview else { return }
        
        let newTransform = imageView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        
        // Проверяем, не станет ли изображение слишком маленьким
        let minScale: CGFloat = 0.5
        let maxScale: CGFloat = 3.0
        
        // Получаем текущий масштаб
        let currentScale = sqrt(newTransform.a * newTransform.a + newTransform.c * newTransform.c)
        
        if currentScale >= minScale && currentScale <= maxScale {
            imageView.transform = newTransform
            
            // После изменения масштаба корректируем позицию
            let constrainedCenter = constrainImageViewCenter(imageView.center, 
                                                            imageView: imageView, 
                                                            containerView: tileView)
            imageView.center = constrainedCenter
        }
        
        gesture.scale = 1.0
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView,
              let tileView = imageView.superview else { return }
        
        imageView.transform = imageView.transform.rotated(by: gesture.rotation)
        
        // После поворота корректируем позицию
        let constrainedCenter = constrainImageViewCenter(imageView.center, 
                                                        imageView: imageView, 
                                                        containerView: tileView)
        imageView.center = constrainedCenter
        
        gesture.rotation = 0.0
    }
    
    // MARK: - Helper Methods
    
    private func constrainImageViewCenter(_ center: CGPoint, 
                                        imageView: UIImageView, 
                                        containerView: UIView) -> CGPoint {
        // Получаем размеры изображения с учетом трансформации
        let imageFrame = imageView.frame
        let containerBounds = containerView.bounds
        
        // Вычисляем минимальные и максимальные позиции центра
        let minX = imageFrame.width / 2
        let maxX = containerBounds.width - imageFrame.width / 2
        let minY = imageFrame.height / 2
        let maxY = containerBounds.height - imageFrame.height / 2
        
        // Ограничиваем позицию центра
        let constrainedX = max(minX, min(maxX, center.x))
        let constrainedY = max(minY, min(maxY, center.y))
        
        return CGPoint(x: constrainedX, y: constrainedY)
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
    
    func textEditingPanel(_ panel: TextEditingPanel, didChangeArchCurve intensity: CGFloat) {
        currentTextLayer?.applyArchEffect(intensity: intensity)
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
        
        guard let tile1 = gridContainer.viewWithTag(index1),
              let tile2 = gridContainer.viewWithTag(index2) else { return }
        
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
        
        // Проверяем, не превышает ли новый размер сетки максимально допустимый
        let maxWidth = collageView.bounds.width
        let maxHeight = collageView.bounds.height
        
        let newGridWidth = outerMargin * 2 + columnWidths.reduce(0, +) + innerMargin * CGFloat(columnWidths.count - 1)
        let newGridHeight = outerMargin * 2 + rowHeights.reduce(0, +) + innerMargin * CGFloat(rowHeights.count - 1)
        
        // Если размер превышает максимальный, масштабируем пропорционально
        if newGridWidth > maxWidth || newGridHeight > maxHeight {
            let scaleX = maxWidth / newGridWidth
            let scaleY = maxHeight / newGridHeight
            let scale = min(scaleX, scaleY)
            
            // Применяем масштабирование
            for i in 0..<columnWidths.count {
                columnWidths[i] *= scale
            }
            for i in 0..<rowHeights.count {
                rowHeights[i] *= scale
            }
        }
        
        // Сохраняем обновленные размеры
        currentColumnWidths = columnWidths
        currentRowHeights = rowHeights
        
        // Обновляем размер gridContainer
        let finalGridWidth = outerMargin * 2 + columnWidths.reduce(0, +) + innerMargin * CGFloat(columnWidths.count - 1)
        let finalGridHeight = outerMargin * 2 + rowHeights.reduce(0, +) + innerMargin * CGFloat(rowHeights.count - 1)
        
        gridContainer.snp.remakeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalTo(finalGridWidth)
            make.height.equalTo(finalGridHeight)
        }
        
        // Пересоздаем constraints для всех плиток
        for (index, position) in template.positions.enumerated() {
            guard let tileView = gridContainer.viewWithTag(index) else { continue }
            
            let col = position.0
            let row = position.1
            
            // Вычисляем позицию плитки
            var x: CGFloat = outerMargin
            for i in 0..<col {
                x += columnWidths[i] + innerMargin
            }
            
            var y: CGFloat = outerMargin
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
              let tileView = gridContainer.subviews[safe: index] as? UIView,
              let imageView = tileView.subviews.first as? UIImageView else { return }
        
        // Обновляем изображение
        imageView.image = image
        imageView.contentMode = .scaleAspectFill
        
        // Удаляем кнопку "+" если она есть
        tileView.subviews.forEach { subview in
            if let button = subview as? UIButton, button.tag == index {
                button.removeFromSuperview()
            }
        }
        
        // Обновляем массив selectedPhotos
        if index < selectedPhotos.count {
            selectedPhotos[index] = image
        }
    }
}
