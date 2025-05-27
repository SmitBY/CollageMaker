//
//  PhotoEditTest.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 06.02.2025.
//

import UIKit
import SnapKit
import RxSwift

class PhotoEditController: UIViewController {
    
    // MARK: - Properties
    
    let viewModel: PhotoEditorViewModel
    private let disposeBag = DisposeBag()
    weak var coordinator: HomeViewCoordinator?
    
    // Текущие offset'ы для crop‑окна (определяют разницу между размером контейнера и размером cropGridView).
    // Изначально: -40 означает, что размер cropGridView = view.width - 40.
    private var currentCropGridOffsetWidth: CGFloat = -40
    private var currentCropGridOffsetHeight: CGFloat = -40
    
    // Ограничения для изменения размера crop‑окна (CropGridView)
    private var gridWidthConstraint: Constraint?
    private var gridHeightConstraint: Constraint?
    
    // Ограничения для положения crop‑окна (левый и верхний отступы)
    private var cropGridLeftConstraint: Constraint?
    private var cropGridTopConstraint: Constraint?
    
    // MARK: - UI Elements
    
    /// ImageView для отображения выбранной фотографии.
    private let photoImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFit
        iv.clipsToBounds = true
        return iv
    }()
    
    /// CropGridView – окно кадрирования, которое можно изменять жестом.
    private let cropGridView: CropGridView = {
        let grid = CropGridView()
        // Для отладки задаём полупрозрачный цвет (можно изменить)
        grid.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
        grid.isUserInteractionEnabled = true
        return grid
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
    
    // MARK: - Lifecycle Methods
    init(viewModel: PhotoEditorViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        print("[PhotoEditorViewController] init(viewModel:) called")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .black.withAlphaComponent(0.4)
        setupUI()
        setupGestureRecognizers()
        setupBindings()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        print("CropGridView frame: \(cropGridView.frame)")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Добавляем photoImageView на весь экран
        view.addSubview(photoImageView)
        photoImageView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(20)
            make.top.equalToSuperview().offset(100)
            make.width.equalTo(view.snp.width).offset(-40)
            make.height.equalTo(view.snp.width).offset(-40)
        }
        
        // Добавляем cropGridView поверх photoImageView
        view.addSubview(cropGridView)
        cropGridView.snp.makeConstraints { make in
            // Задаём положение через 4 ограничения: левый, верхний, ширина и высота.
            self.cropGridLeftConstraint = make.left.equalToSuperview().offset(20).constraint
            self.cropGridTopConstraint = make.top.equalToSuperview().offset(100).constraint
            self.gridWidthConstraint = make.width.equalTo(view.snp.width).offset(-40).constraint
            self.gridHeightConstraint = make.height.equalTo(view.snp.width).offset(-40).constraint
        }
        
        // Добавляем кнопки
        view.addSubview(buttonStackView)
        buttonStackView.addArrangedSubview(cancelButton)
        buttonStackView.addArrangedSubview(saveButton)
        buttonStackView.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40)
            make.left.right.equalToSuperview().inset(16)
            make.height.equalTo(44)
        }
    }
    
    // MARK: - Gesture Recognizers Setup
    
    private func setupGestureRecognizers() {
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropGridPan(_:)))
//        panGesture.delegate = self
//        panGesture.maximumNumberOfTouches = 1
//        panGesture.cancelsTouchesInView = false
//        cropGridView.addGestureRecognizer(panGesture)
        cropGridView.isUserInteractionEnabled = false
        
        photoImageView.isUserInteractionEnabled = true
        
        // Добавляем стандартный pinch gesture для масштабирования.
        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
        // Добавляем стандартный rotation gesture для вращения.
        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
        pinchGesture.delegate = self
        rotationGesture.delegate = self
        photoImageView.addGestureRecognizer(pinchGesture)
        photoImageView.addGestureRecognizer(rotationGesture)
    }
    
    // MARK: - Gesture Handler
    
    @objc private func handleCropGridPan(_ gesture: UIPanGestureRecognizer) {
        
        // Если более одного касания – не обрабатываем pan для CropGridView
            if gesture.numberOfTouches > 1 {
                return
            }
        // Получаем положение касания внутри cropGridView
        let location = gesture.location(in: cropGridView)
        let bounds = cropGridView.bounds
        
        // Задаём порог для краевой зоны – 20 пунктов
        let edgeThreshold: CGFloat = 40.0
        // Определяем центральную зону для перемещения: прямоугольник 30×30, центрированный в cropGridView (от центра ±15)
        let centerZone = CGRect(x: bounds.midX - 15, y: bounds.midY - 15, width: 40, height: 40)
        
        // Получаем смещение жеста относительно основного view
        let translation = gesture.translation(in: view)
        
        if centerZone.contains(location) {
            // Если касание в центральной зоне – перемещаем cropGridView, обновляя левый и верхний отступы.
            if let leftConstraint = cropGridLeftConstraint, let topConstraint = cropGridTopConstraint {
                let currentLeft = leftConstraint.layoutConstraints.first?.constant ?? 20
                let currentTop = topConstraint.layoutConstraints.first?.constant ?? 100
                leftConstraint.update(offset: currentLeft + translation.x)
                topConstraint.update(offset: currentTop + translation.y)
            }
            gesture.setTranslation(.zero, in: view)
            view.layoutIfNeeded()
            return
        }
        
        // Если касание происходит вне центральной зоны – обрабатываем изменение размера.
        let activeLeft = location.x <= edgeThreshold
        let activeRight = location.x >= (bounds.width - edgeThreshold)
        let activeTop = location.y <= edgeThreshold
        let activeBottom = location.y >= (bounds.height - edgeThreshold)
        
        // Если одновременно активна горизонтальная и вертикальная сторона – угол
        let isCorner = (activeLeft || activeRight) && (activeTop || activeBottom)
        
        if isCorner {
            // Равномерное масштабирование с сохранением квадратного соотношения.
            var deltaH: CGFloat = 0
            var deltaV: CGFloat = 0
            if activeLeft {
                deltaH = -translation.x
            } else if activeRight {
                deltaH = translation.x
            }
            if activeTop {
                deltaV = -translation.y
            } else if activeBottom {
                deltaV = translation.y
            }
            let uniformDelta = (deltaH + deltaV) / 2.0
            currentCropGridOffsetWidth += uniformDelta
            currentCropGridOffsetHeight += uniformDelta
            
            let containerWidth = view.bounds.width
            let maxAllowed = containerWidth - 10
            let minSize: CGFloat = 50.0
            let newDimensionUnclamped = containerWidth + currentCropGridOffsetWidth  // одинаково для ширины и высоты
            let newDimension = min(max(newDimensionUnclamped, minSize), maxAllowed)
            currentCropGridOffsetWidth = newDimension - containerWidth
            currentCropGridOffsetHeight = newDimension - containerWidth
            
            gridWidthConstraint?.update(offset: currentCropGridOffsetWidth)
            gridHeightConstraint?.update(offset: currentCropGridOffsetHeight)
        } else {
            // Обработка одиночных сторон
            // Если тянем за левый край – обновляем левый отступ и ширину.
            if activeLeft {
                if let leftConstraint = cropGridLeftConstraint, let widthConstraint = gridWidthConstraint {
                    let currentLeft = leftConstraint.layoutConstraints.first?.constant ?? 20
                    let newLeft = currentLeft + translation.x
                    let containerWidth = view.bounds.width
                    let currentWidth = containerWidth + (widthConstraint.layoutConstraints.first?.constant ?? -40)
                    let rightEdge = currentLeft + currentWidth
                    let newWidth = rightEdge - newLeft
                    let minSize: CGFloat = 50.0
                    let maxAllowed = containerWidth - 10
                    let clampedNewLeft = min(max(newLeft, 0), containerWidth - minSize)
                    let clampedNewWidth = min(max(newWidth, minSize), maxAllowed)
                    leftConstraint.update(offset: clampedNewLeft)
                    widthConstraint.update(offset: clampedNewWidth - containerWidth)
                }
            } else if activeRight {
                if let widthConstraint = gridWidthConstraint {
                    let containerWidth = view.bounds.width
                    let currentWidth = containerWidth + (widthConstraint.layoutConstraints.first?.constant ?? -40)
                    let newWidth = currentWidth + translation.x
                    let minSize: CGFloat = 50.0
                    let maxAllowed = containerWidth - 10
                    let clampedNewWidth = min(max(newWidth, minSize), maxAllowed)
                    widthConstraint.update(offset: clampedNewWidth - containerWidth)
                }
            }
            
            // Вертикальная обработка
            if activeTop {
                if let topConstraint = cropGridTopConstraint, let heightConstraint = gridHeightConstraint {
                    let currentTop = topConstraint.layoutConstraints.first?.constant ?? 100
                    let newTop = currentTop + translation.y
                    let containerHeight = view.bounds.height
                    let currentHeight = containerHeight + (heightConstraint.layoutConstraints.first?.constant ?? -40)
                    let bottomEdge = currentTop + currentHeight
                    let newHeight = bottomEdge - newTop
                    let minSize: CGFloat = 50.0
                    let maxAllowed = containerHeight - 10
                    let clampedNewTop = min(max(newTop, 0), containerHeight - minSize)
                    let clampedNewHeight = min(max(newHeight, minSize), maxAllowed)
                    topConstraint.update(offset: clampedNewTop)
                    heightConstraint.update(offset: clampedNewHeight - containerHeight)
                }
            } else if activeBottom {
                if let heightConstraint = gridHeightConstraint {
                    let containerHeight = view.bounds.height
                    let currentHeight = containerHeight + (heightConstraint.layoutConstraints.first?.constant ?? -40)
                    let newHeight = currentHeight + translation.y
                    let minSize: CGFloat = 50.0
                    let maxAllowed = containerHeight - 10
                    let clampedNewHeight = min(max(newHeight, minSize), maxAllowed)
                    heightConstraint.update(offset: clampedNewHeight - containerHeight)
                }
            }
        }
        
        gesture.setTranslation(.zero, in: view)
        view.layoutIfNeeded()
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
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.image
            .asObservable()
            .subscribe(onNext: { [weak self] image in
                guard let self = self, let image = image else { return }
                
                // Вывод оригинального разрешения в пикселях:
                print("Original image resolution: \(image.size.width * image.scale) x \(image.size.height * image.scale)")
                
                self.photoImageView.image = image
                
                // Обновляем ограничения imageView для сохранения соотношения сторон:
                self.photoImageView.snp.remakeConstraints { make in
                    make.center.equalToSuperview()
                    make.width.equalTo(self.view.frame.width - 40.0)
                    let aspectRatio = image.size.height / image.size.width
                    make.height.equalTo(self.view.frame.width).multipliedBy(aspectRatio)
                }
                
                self.view.layoutIfNeeded()
            })
            .disposed(by: disposeBag)
        
        cancelButton.rx.tap
            .subscribe(onNext: { [weak self] in
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
        
        saveButton.rx.tap
            .subscribe(onNext: { [weak self] in
                print("Save button tapped")
                self?.dismiss(animated: true, completion: nil)
            })
            .disposed(by: disposeBag)
    }
}

// MARK: - UIGestureRecognizerDelegate

extension PhotoEditController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        if gestureRecognizer.view == cropGridView, gestureRecognizer is UIPanGestureRecognizer {
            // Если в данный момент задействовано более одного касания, не обрабатывать жест на cropGridView
            if touch.phase == .began && gestureRecognizer.numberOfTouches > 1 {
                return false
            }
            // Альтернативно можно проверить event.allTouches, если оно доступно.
        }
        return true
    }
    
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        return true
    }
}

