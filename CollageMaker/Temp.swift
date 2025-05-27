//
//
//import UIKit
//import SnapKit
//import RxSwift
//import RxCocoa
//import RxRelay
//
//class PhotoEditorViewController: UIViewController {
//    
//    // MARK: - Properties
//    
//    let viewModel: PhotoEditorViewModel
//    private let disposeBag = DisposeBag()
//    
//    weak var coordinator: HomeViewCoordinator?
//    
//    // MARK: - UI Elements
//
//    
//    /// Контейнер для изображения. Фон установлен в .black, чтобы если изображение выходит за crop‑окно, оно показывалось на черном фоне.
//    private let photoContainerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .black
//        view.layer.cornerRadius = 4
//        // Разрешаем imageView выходить за пределы контейнера.
//        view.clipsToBounds = false
//        return view
//    }()
//    
//    /// ImageView для отображения выбранного изображения.
//    private let imageView: UIImageView = {
//        let iv = UIImageView()
//        iv.contentMode = .scaleAspectFit  // Сохраняет пропорции исходного изображения.
//        iv.clipsToBounds = false
//        return iv
//    }()
//    
//    /// CropOverlayView затемняет область вне cropRect.
//    private let cropOverlayView: CropOverlayView = {
//        let overlay = CropOverlayView()
//        overlay.backgroundColor = .clear
//        overlay.isUserInteractionEnabled = false
//        return overlay
//    }()
//    
//    /// CropGridView – ваша существующая сетка для кадрирования.
//    private let cropGridView: CropGridView = {
//        let grid = CropGridView()
//        grid.backgroundColor = .clear
//        grid.isUserInteractionEnabled = false
//        return grid
//    }()
//    
//    /// UIStackView для кнопок Cancel и Save.
//    private let buttonStackView: UIStackView = {
//        let sv = UIStackView()
//        sv.axis = .horizontal
//        sv.alignment = .fill
//        sv.distribution = .fillEqually
//        sv.spacing = 16
//        return sv
//    }()
//    
//    private let cancelButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Cancel", for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemGray
//        button.layer.cornerRadius = 4
//        return button
//    }()
//    
//    private let saveButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Save", for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemBlue
//        button.layer.cornerRadius = 4
//        return button
//    }()
//    
//    // MARK: - Initializer
//    
//    init(viewModel: PhotoEditorViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//        print("[PhotoEditorViewController] init(viewModel:) called")
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Lifecycle Methods
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//        setupGestureRecognizers()
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        // Обновляем cropOverlayView.cropRect.
//        // Здесь мы задаем cropRect как центральный квадрат с inset 20 от краёв photoContainerView.
//        let cropRect = photoContainerView.frame.insetBy(dx: 20, dy: 20)
//        cropOverlayView.cropRect = cropRect
//    }
//    
//    // MARK: - UI Setup
//    
//    private func setupUI() {
//        view.backgroundColor = .white
//        
//        view.addSubview(photoContainerView)
//        photoContainerView.snp.makeConstraints { make in
//            make.left.equalToSuperview().offset(16)
//            make.right.equalToSuperview().inset(16)
//            make.centerY.equalToSuperview()
//            // Задаем контейнер квадратным для crop‑окна.
//            make.height.equalTo(photoContainerView.snp.width)
//        }
//        
//        photoContainerView.addSubview(imageView)
//        imageView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        // Добавляем CropOverlayView поверх imageView.
//        view.addSubview(cropOverlayView)
//        cropOverlayView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        // Добавляем CropGridView поверх cropOverlayView.
//        photoContainerView.addSubview(cropGridView)
//        cropGridView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//            // Задаем отступы, чтобы cropGridView оставалось квадратным и в центре.
//            make.left.equalToSuperview().offset(20)
//            make.right.equalToSuperview().inset(20)
//            make.height.equalTo(cropGridView.snp.width)
//        }
//        
//        view.addSubview(buttonStackView)
//        buttonStackView.addArrangedSubview(cancelButton)
//        buttonStackView.addArrangedSubview(saveButton)
//        buttonStackView.snp.makeConstraints { make in
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40)
//            make.left.equalToSuperview().offset(16)
//            make.right.equalToSuperview().inset(16)
//            make.height.equalTo(44)
//        }
//    }
//    
//    // MARK: - Bindings
//    
//    private func setupBindings() {
//        viewModel.image
//            .asObservable()
//            .bind(to: imageView.rx.image)
//            .disposed(by: disposeBag)
//        
//        cancelButton.rx.tap
//            .subscribe(onNext: { [weak self] in
//                self?.dismiss(animated: true, completion: nil)
//            })
//            .disposed(by: disposeBag)
//        
//        saveButton.rx.tap
//            .subscribe(onNext: { [weak self] in
//                print("Save button tapped")
//                self?.dismiss(animated: true, completion: nil)
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    // MARK: - Gesture Recognizers Setup
//    
//    private func setupGestureRecognizers() {
//        imageView.isUserInteractionEnabled = true
//        
//        // Добавляем стандартный pinch gesture для масштабирования.
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        // Добавляем стандартный rotation gesture для вращения.
//        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
//        pinchGesture.delegate = self
//        rotationGesture.delegate = self
//        imageView.addGestureRecognizer(pinchGesture)
//        imageView.addGestureRecognizer(rotationGesture)
//        
//        // Добавляем pan gesture для перемещения.
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        imageView.addGestureRecognizer(panGesture)
//    }
//    
//    // MARK: - Gesture Handlers
//    
//    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let imageView = gesture.view else { return }
//        if gesture.state == .changed || gesture.state == .ended {
//            imageView.transform = imageView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
//            gesture.scale = 1.0
//        }
//    }
//    
//    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
//        guard let imageView = gesture.view else { return }
//        if gesture.state == .changed || gesture.state == .ended {
//            imageView.transform = imageView.transform.rotated(by: gesture.rotation)
//            gesture.rotation = 0.0
//        }
//    }
//    
//    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
//        guard let imageView = gesture.view as? UIImageView,
//              let container = imageView.superview else { return }
//        let translation = gesture.translation(in: container)
//        var newCenter = CGPoint(x: imageView.center.x + translation.x,
//                                y: imageView.center.y + translation.y)
//        
//        let currentFrame = imageView.frame
//        // Используем cropRect, заданный как photoContainerView.bounds.insetBy(dx:20, dy:20)
//        let cropRect = photoContainerView.bounds.insetBy(dx: 20, dy: 20)
//        
//        if currentFrame.minX + translation.x > cropRect.minX {
//            newCenter.x -= (currentFrame.minX + translation.x - cropRect.minX)
//        }
//        if currentFrame.maxX + translation.x < cropRect.maxX {
//            newCenter.x += (cropRect.maxX - (currentFrame.maxX + translation.x))
//        }
//        if currentFrame.minY + translation.y > cropRect.minY {
//            newCenter.y -= (currentFrame.minY + translation.y - cropRect.minY)
//        }
//        if currentFrame.maxY + translation.y < cropRect.maxY {
//            newCenter.y += (cropRect.maxY - (currentFrame.maxY + translation.y))
//        }
//        
//        imageView.center = newCenter
//        gesture.setTranslation(.zero, in: container)
//    }
//}
//
//// MARK: - UIGestureRecognizerDelegate
//
//extension PhotoEditorViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        return true
//    }
//}


//import UIKit
//import SnapKit
//import RxSwift
//import RxCocoa
//import RxRelay
//
//class PhotoEditorViewController: UIViewController {
//    
//    // MARK: - Properties
//    
//    let viewModel: PhotoEditorViewModel
//    private let disposeBag = DisposeBag()
//    
//    weak var coordinator: HomeViewCoordinator?
//    
//    // MARK: - UI Elements
//
//    
//    /// Контейнер для изображения. Фон установлен в .black, чтобы если изображение выходит за crop‑окно, оно показывалось на черном фоне.
//    private let photoContainerView: UIView = {
//        let view = UIView()
//        view.backgroundColor = .black
//        view.layer.cornerRadius = 4
//        // Разрешаем imageView выходить за пределы контейнера.
//        view.clipsToBounds = false
//        return view
//    }()
//    
//    /// ImageView для отображения выбранного изображения.
//    private let imageView: UIImageView = {
//        let iv = UIImageView()
//        iv.contentMode = .scaleAspectFit  // Сохраняет пропорции исходного изображения.
//        iv.clipsToBounds = false
//        return iv
//    }()
//    
//    /// CropOverlayView затемняет область вне cropRect.
//    private let cropOverlayView: CropOverlayView = {
//        let overlay = CropOverlayView()
//        overlay.backgroundColor = .clear
//        overlay.isUserInteractionEnabled = false
//        return overlay
//    }()
//    
//    /// CropGridView – ваша существующая сетка для кадрирования.
//    private let cropGridView: CropGridView = {
//        let grid = CropGridView()
//        grid.backgroundColor = .clear
//        grid.isUserInteractionEnabled = false
//        return grid
//    }()
//    
//    private var cropGridWidthConstraint: Constraint?
//    private let rightHandle: UIView = {
//        let handle = UIView()
//        handle.backgroundColor = .white
//        handle.layer.cornerRadius = 10  // handle размером 20x20
//        handle.clipsToBounds = true
//        return handle
//    }()
//    private let bottomHandle: UIView = {
//        let handle = UIView()
//        handle.backgroundColor = .white
//        handle.layer.cornerRadius = 10
//        handle.clipsToBounds = true
//        return handle
//    }()
//    
//    /// UIStackView для кнопок Cancel и Save.
//    private let buttonStackView: UIStackView = {
//        let sv = UIStackView()
//        sv.axis = .horizontal
//        sv.alignment = .fill
//        sv.distribution = .fillEqually
//        sv.spacing = 16
//        return sv
//    }()
//    
//    private let cancelButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Cancel", for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemGray
//        button.layer.cornerRadius = 4
//        return button
//    }()
//    
//    private let saveButton: UIButton = {
//        let button = UIButton(type: .system)
//        button.setTitle("Save", for: .normal)
//        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
//        button.setTitleColor(.white, for: .normal)
//        button.backgroundColor = .systemBlue
//        button.layer.cornerRadius = 4
//        return button
//    }()
//    
//    // MARK: - Initializer
//    
//    init(viewModel: PhotoEditorViewModel) {
//        self.viewModel = viewModel
//        super.init(nibName: nil, bundle: nil)
//        print("[PhotoEditorViewController] init(viewModel:) called")
//    }
//    
//    required init?(coder: NSCoder) {
//        fatalError("init(coder:) has not been implemented")
//    }
//    
//    // MARK: - Lifecycle Methods
//    
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        setupUI()
//        setupBindings()
//        setupGestureRecognizers()
//    }
//    
//    override func viewDidLayoutSubviews() {
//        super.viewDidLayoutSubviews()
//        // Обновляем cropOverlayView.cropRect.
//        // Здесь мы задаем cropRect как центральный квадрат с inset 20 от краёв photoContainerView.
//        let cropRect = photoContainerView.frame.insetBy(dx: 20, dy: 20)
//        cropOverlayView.cropRect = cropRect
//    }
//    
//    // MARK: - UI Setup
//    
//    private func setupUI() {
//        view.backgroundColor = .white
//        
//        view.addSubview(photoContainerView)
//        photoContainerView.snp.makeConstraints { make in
//            make.left.equalToSuperview().offset(16)
//            make.right.equalToSuperview().inset(16)
//            make.centerY.equalToSuperview()
//            // Задаем контейнер квадратным для crop‑окна.
//            make.height.equalTo(photoContainerView.snp.width)
//        }
//        
//        photoContainerView.addSubview(imageView)
//        imageView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        // Добавляем CropOverlayView поверх imageView.
//        view.addSubview(cropOverlayView)
//        cropOverlayView.snp.makeConstraints { make in
//            make.edges.equalToSuperview()
//        }
//        
//        // Добавляем CropGridView поверх cropOverlayView.
//        photoContainerView.addSubview(cropGridView)
//        cropGridView.snp.makeConstraints { make in
//            make.center.equalToSuperview()
//            // Сохраняем ограничение ширины; исходное значение: ширина контейнера минус 40 (то есть inset 20 с каждой стороны)
//            self.cropGridWidthConstraint = make.width.equalTo(photoContainerView.snp.width).offset(-40).constraint
//            make.height.equalTo(cropGridView.snp.width)
//        }
//
//        // Добавляем handle для изменения размера справа:
//        cropGridView.addSubview(rightHandle)
//        rightHandle.snp.makeConstraints { make in
//            make.width.height.equalTo(20)
//            make.centerY.equalToSuperview()
//            make.right.equalToSuperview()
//        }
//
//        // Добавляем handle для изменения размера снизу:
//        cropGridView.addSubview(bottomHandle)
//        bottomHandle.snp.makeConstraints { make in
//            make.width.height.equalTo(20)
//            make.centerX.equalToSuperview()
//            make.bottom.equalToSuperview()
//        }
//        
//        // Pan gesture для правого handle
//        let rightPan = UIPanGestureRecognizer(target: self, action: #selector(handleRightHandlePan(_:)))
//        rightHandle.isUserInteractionEnabled = true
//        rightHandle.addGestureRecognizer(rightPan)
//
//        // Pan gesture для нижнего handle
//        let bottomPan = UIPanGestureRecognizer(target: self, action: #selector(handleBottomHandlePan(_:)))
//        bottomHandle.isUserInteractionEnabled = true
//        bottomHandle.addGestureRecognizer(bottomPan)
//        
//        view.addSubview(buttonStackView)
//        buttonStackView.addArrangedSubview(cancelButton)
//        buttonStackView.addArrangedSubview(saveButton)
//        buttonStackView.snp.makeConstraints { make in
//            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).inset(40)
//            make.left.equalToSuperview().offset(16)
//            make.right.equalToSuperview().inset(16)
//            make.height.equalTo(44)
//        }
//    }
//    
//    // MARK: - Bindings
//    
//    private func setupBindings() {
//        // В методе setupBindings() внутри подписки на viewModel.image:
//        viewModel.image
//            .asObservable()
//            .subscribe(onNext: { [weak self] image in
//                guard let self = self, let image = image else { return }
//                // Вывод разрешения оригинальной фотографии в лог:
//                print("Original image resolution: \(image.size.width * image.scale) x \(image.size.height * image.scale)")
//                
//                self.imageView.image = image
//                // Обновляем ограничения imageView для сохранения соотношения сторон:
//                self.imageView.snp.remakeConstraints { make in
//                    make.center.equalToSuperview()
//                    make.width.equalTo(self.photoContainerView.snp.width)
//                    let aspectRatio = image.size.height / image.size.width
//                    make.height.equalTo(self.photoContainerView.snp.width).multipliedBy(aspectRatio)
//                }
//                self.view.layoutIfNeeded()
//            })
//            .disposed(by: disposeBag)
//        
//        cancelButton.rx.tap
//            .subscribe(onNext: { [weak self] in
//                self?.dismiss(animated: true, completion: nil)
//            })
//            .disposed(by: disposeBag)
//        
//        saveButton.rx.tap
//            .subscribe(onNext: { [weak self] in
//                print("Save button tapped")
//                self?.dismiss(animated: true, completion: nil)
//            })
//            .disposed(by: disposeBag)
//    }
//    
//    // MARK: - Gesture Recognizers Setup
//    
//    private func setupGestureRecognizers() {
//        imageView.isUserInteractionEnabled = true
//        
//        // Добавляем стандартный pinch gesture для масштабирования.
//        let pinchGesture = UIPinchGestureRecognizer(target: self, action: #selector(handlePinch(_:)))
//        // Добавляем стандартный rotation gesture для вращения.
//        let rotationGesture = UIRotationGestureRecognizer(target: self, action: #selector(handleRotation(_:)))
//        pinchGesture.delegate = self
//        rotationGesture.delegate = self
//        imageView.addGestureRecognizer(pinchGesture)
//        imageView.addGestureRecognizer(rotationGesture)
//        
//        // Добавляем pan gesture для перемещения.
//        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
//        imageView.addGestureRecognizer(panGesture)
//    }
//    
//    // MARK: - Gesture Handlers
//    
//    @objc private func handlePinch(_ gesture: UIPinchGestureRecognizer) {
//        guard let imageView = gesture.view else { return }
//        if gesture.state == .changed || gesture.state == .ended {
//            imageView.transform = imageView.transform.scaledBy(x: gesture.scale, y: gesture.scale)
//            gesture.scale = 1.0
//        }
//    }
//    
//    @objc private func handleRotation(_ gesture: UIRotationGestureRecognizer) {
//        guard let imageView = gesture.view else { return }
//        if gesture.state == .changed || gesture.state == .ended {
//            imageView.transform = imageView.transform.rotated(by: gesture.rotation)
//            gesture.rotation = 0.0
//        }
//    }
//    
//    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
//        guard let imageView = gesture.view as? UIImageView,
//              let container = imageView.superview else { return }
//        let translation = gesture.translation(in: container)
//        var newCenter = CGPoint(x: imageView.center.x + translation.x,
//                                y: imageView.center.y + translation.y)
//        
//        let currentFrame = imageView.frame
//        // Используем cropRect, заданный как photoContainerView.bounds.insetBy(dx:20, dy:20)
//        let cropRect = photoContainerView.bounds.insetBy(dx: 20, dy: 20)
//        
//        if currentFrame.minX + translation.x > cropRect.minX {
//            newCenter.x -= (currentFrame.minX + translation.x - cropRect.minX)
//        }
//        if currentFrame.maxX + translation.x < cropRect.maxX {
//            newCenter.x += (cropRect.maxX - (currentFrame.maxX + translation.x))
//        }
//        if currentFrame.minY + translation.y > cropRect.minY {
//            newCenter.y -= (currentFrame.minY + translation.y - cropRect.minY)
//        }
//        if currentFrame.maxY + translation.y < cropRect.maxY {
//            newCenter.y += (cropRect.maxY - (currentFrame.maxY + translation.y))
//        }
//        
//        imageView.center = newCenter
//        gesture.setTranslation(.zero, in: container)
//    }
//    
//    @objc private func handleRightHandlePan(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: photoContainerView)
//        // Обновляем ограничение ширины CropGridView. Изначальное значение offset: -40 (20 пунктов от каждой стороны).
//        // При смещении handle вправо увеличиваем размер.
//        cropGridWidthConstraint?.update(offset: -40 + translation.x)
//        gesture.setTranslation(.zero, in: photoContainerView)
//        view.layoutIfNeeded()
//    }
//
//    @objc private func handleBottomHandlePan(_ gesture: UIPanGestureRecognizer) {
//        let translation = gesture.translation(in: photoContainerView)
//        // Аналогично обновляем ограничение через смещение по Y.
//        cropGridWidthConstraint?.update(offset: -40 + translation.y)
//        gesture.setTranslation(.zero, in: photoContainerView)
//        view.layoutIfNeeded()
//    }
//}
//
//// MARK: - UIGestureRecognizerDelegate
//
//extension PhotoEditorViewController: UIGestureRecognizerDelegate {
//    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer,
//                           shouldRecognizeSimultaneouslyWith otherGestureRecognizer: UIGestureRecognizer) -> Bool {
//        // Если один из жестов принадлежит handle'у, не разрешаем одновременное распознавание.
//        if let view1 = gestureRecognizer.view, let view2 = otherGestureRecognizer.view {
//            if view1 == rightHandle || view1 == bottomHandle || view2 == rightHandle || view2 == bottomHandle {
//                return false
//            }
//        }
//        return true
//    }
//}
//
