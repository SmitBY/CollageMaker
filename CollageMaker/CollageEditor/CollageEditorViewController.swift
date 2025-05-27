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
    
    // Данные для коллажа
    private var selectedPhotos: [UIImage] = [] // Выбранные пользователем фотографии
    
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
        view.backgroundColor = .white
        
        // Добавляем элементы интерфейса
        view.addSubview(collageView)
        view.addSubview(saveButton)
        
        // Настройка constraints
        collageView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(saveButton.snp.top).offset(-20)
        }
        
        saveButton.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-10)
            make.height.equalTo(50)
        }
    }
    

    
    private func fillCollageWithSelectedPhotos() {
        guard let gridContainer = collageView.viewWithTag(gridContainerTag) else { return }
        
        for (index, photo) in selectedPhotos.enumerated() {
            if index < gridContainer.subviews.count,
               let tileView = gridContainer.subviews[safe: index] as? UIView,
               let imageView = tileView.subviews.first as? UIImageView {
                
                imageView.image = photo
                imageView.contentMode = .scaleAspectFill
                
                let indexPath = IndexPath(item: index, section: 0)
                viewModel.setImage(at: indexPath, image: photo)
            }
        }
    }
    
    // MARK: - Collage View Setup
    
    /// Configures the collage view based on the provided template.
    /// The preview displays a grid of square tiles with white borders and placeholder images,
    /// centered in collageView. Special templates (2x2 grid with one tile stretched) обрабатываются.
    private func setupCollageView(with template: CollageTemplate) {
        // Очищаем старый коллаж
        collageView.subviews.forEach { $0.removeFromSuperview() }
        
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
            
            let tileView = UIView(frame: tileFrame)
            tileView.backgroundColor = .clear
            tileView.layer.borderColor = UIColor.white.cgColor
            tileView.layer.borderWidth = 1.0
            tileView.layer.cornerRadius = 4.0
            tileView.clipsToBounds = true
            tileView.tag = index // Устанавливаем тег для идентификации
            
            // Создаем imageView для placeholder.
            let imageView = UIImageView(frame: tileView.bounds)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .clear
            if let placeholder = UIImage(named: "placeholder") {
                imageView.image = placeholder.resized(to: tileView.bounds.size)
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
        }
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
        
        if let finalImage = UIGraphicsGetImageFromCurrentImageContext() {
            UIImageWriteToSavedPhotosAlbum(finalImage, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
            print("Final collage image saved successfully!")
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
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        let translation = gesture.translation(in: imageView.superview)
        imageView.center = CGPoint(x: imageView.center.x + translation.x,
                                   y: imageView.center.y + translation.y)
        gesture.setTranslation(.zero, in: imageView.superview)
    }
    
    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        imageView.transform = imageView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
        gesture.scale = 1.0
    }
    
    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
        guard let imageView = gesture.view as? UIImageView else { return }
        imageView.transform = imageView.transform.rotated(by: gesture.rotation)
        gesture.rotation = 0.0
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
