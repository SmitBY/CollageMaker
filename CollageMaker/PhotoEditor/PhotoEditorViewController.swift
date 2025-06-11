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
    
    // Новые свойства для хранения ограничений ширины и высоты CropGridView
    private var cropGridWidthConstraint: NSLayoutConstraint?
    private var cropGridHeightConstraint: NSLayoutConstraint?
    
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
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        
        print("photoContainerView bounds: \(photoContainerView.bounds)")
        
        // Обновляем cropOverlayView.cropRect
        if imageView.image != nil {
            let cropRect = photoContainerView.convert(cropGridView.frame, to: imageView)
            cropOverlayView.cropRect = cropRect
        }
        
        // Если ограничения еще не установлены, создаем их
        if cropGridWidthConstraint == nil || cropGridHeightConstraint == nil {
            updateCropGridViewConstraints()
        }
    }
    
    // MARK: - UI Setup
    private func setupUI() {
        view.backgroundColor = .white
        
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
    
    private func updateCropGridViewConstraints() {
        // Удаляем старые ограничения, если они есть
        cropGridView.constraints.forEach { constraint in
            cropGridView.removeConstraint(constraint)
        }
        
        // Создаем новые ограничения
        cropGridWidthConstraint = cropGridView.widthAnchor.constraint(equalTo: photoContainerView.widthAnchor, constant: -40)
        cropGridHeightConstraint = cropGridView.heightAnchor.constraint(equalTo: photoContainerView.widthAnchor, constant: -40)
        
        // Устанавливаем приоритет ограничений
        if let widthConstraint = cropGridWidthConstraint, let heightConstraint = cropGridHeightConstraint {
            widthConstraint.priority = .defaultHigh
            heightConstraint.priority = .defaultHigh
            NSLayoutConstraint.activate([widthConstraint, heightConstraint])
        }
        
        // Центрируем CropGridView
        cropGridView.translatesAutoresizingMaskIntoConstraints = false
        cropGridView.centerXAnchor.constraint(equalTo: photoContainerView.centerXAnchor).isActive = true
        cropGridView.centerYAnchor.constraint(equalTo: photoContainerView.centerYAnchor).isActive = true
    }
    
    // MARK: - Bindings
    private func setupBindings() {
        viewModel.image
            .asObservable()
            .subscribe(onNext: { [weak self] image in
                guard let self = self, let image = image else { return }
                
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
        
        // Добавляем pan gesture для CropGridView
        let gridPanGesture = UIPanGestureRecognizer(target: self, action: #selector(handleCropGridPan(_:)))
        gridPanGesture.delegate = self
        cropGridView.addGestureRecognizer(gridPanGesture)
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
    
    @objc private func handleCropGridPan(_ gesture: UIPanGestureRecognizer) {
        guard let cropGridView = gesture.view else { return }
        
        let location = gesture.location(in: cropGridView)
        let threshold: CGFloat = 20.0
        let gridBounds = cropGridView.bounds
        
        // Определяем, в какой зоне находится касание
        let isNearLeft = location.x <= threshold
        let isNearRight = location.x >= (gridBounds.width - threshold)
        let isNearTop = location.y <= threshold
        let isNearBottom = location.y >= (gridBounds.height - threshold)
        
        let translation = gesture.translation(in: photoContainerView)
        
        switch gesture.state {
        case .began, .changed:
            if isNearLeft || isNearRight || isNearTop || isNearBottom {
                // Режим изменения размера
                let minCropSize: CGFloat = 50.0
                let maxCropSize = min(photoContainerView.bounds.width, photoContainerView.bounds.height) - 40
                
                var newWidth = cropGridView.frame.width
                var newHeight = cropGridView.frame.height
                
                if isNearLeft {
                    newWidth -= translation.x
                } else if isNearRight {
                    newWidth += translation.x
                }
                
                if isNearTop {
                    newHeight -= translation.y
                } else if isNearBottom {
                    newHeight += translation.y
                }
                
                // Ограничиваем минимальный и максимальный размер
                newWidth = max(minCropSize, min(newWidth, maxCropSize))
                newHeight = max(minCropSize, min(newHeight, maxCropSize))
                
                // Обновляем размеры CropGridView
                cropGridWidthConstraint?.constant = newWidth - photoContainerView.bounds.width
                cropGridHeightConstraint?.constant = newHeight - photoContainerView.bounds.height
                
                // Обновляем layout
                view.layoutIfNeeded()
            } else {
                // Режим перемещения
                var newCenter = CGPoint(
                    x: cropGridView.center.x + translation.x,
                    y: cropGridView.center.y + translation.y
                )
                
                // Ограничиваем движение CropGridView внутри photoContainerView
                let containerBounds = photoContainerView.bounds
                let halfWidth = cropGridView.bounds.width / 2
                let halfHeight = cropGridView.bounds.height / 2
                
                newCenter.x = max(halfWidth + 20, min(newCenter.x, containerBounds.width - halfWidth - 20))
                newCenter.y = max(halfHeight + 20, min(newCenter.y, containerBounds.height - halfHeight - 20))
                
                cropGridView.center = newCenter
            }
            
            // Сбрасываем смещение жеста
            gesture.setTranslation(.zero, in: photoContainerView)
            
        default:
            break
        }
    }
}

// MARK: - UIGestureRecognizerDelegate
extension PhotoEditorViewController: UIGestureRecognizerDelegate {
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
        // Разрешаем одновременное распознавание жестов для разных элементов
        return true
    }
}
