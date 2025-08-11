//
//  FullscreenCollageViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import SnapKit

class FullscreenCollageViewController: UIViewController {
    
    // MARK: - Properties
    private let collage: SavedCollage
    private var initialFrame: CGRect = .zero
    
    // MARK: - UI Elements
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.backgroundColor = .black
        scrollView.minimumZoomScale = 1.0
        scrollView.maximumZoomScale = 3.0
        scrollView.showsVerticalScrollIndicator = false
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.bouncesZoom = true
        return scrollView
    }()
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.isUserInteractionEnabled = true
        return imageView
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    
    private let shareButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "square.and.arrow.up.circle.fill"), for: .normal)
        button.tintColor = .white
        button.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        button.layer.cornerRadius = 20
        button.layer.masksToBounds = true
        return button
    }()
    
    private let infoLabel: UILabel = {
        let label = UILabel()
        label.textColor = .white
        label.font = UIFont.systemFont(ofSize: 14)
        label.textAlignment = .center
        label.backgroundColor = UIColor.black.withAlphaComponent(0.5)
        label.layer.cornerRadius = 8
        label.layer.masksToBounds = true
        label.numberOfLines = 2
        return label
    }()
    
    // Gesture recognizers
    private var panGestureRecognizer: UIPanGestureRecognizer!
    private var tapGestureRecognizer: UITapGestureRecognizer!
    
    // MARK: - Initialization
    init(collage: SavedCollage) {
        self.collage = collage
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .overFullScreen
        modalTransitionStyle = .crossDissolve
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupGestures()
        configureCollage()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        // Скрываем статус бар для полноэкранного просмотра
        setNeedsStatusBarAppearanceUpdate()
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    // MARK: - Setup Methods
    private func setupUI() {
        removeBackgroundGradientLayers()
        setBackgroundImage(named: "loadback")
        
        // Добавляем элементы на view
        view.addSubview(scrollView)
        scrollView.addSubview(imageView)
        view.addSubview(closeButton)
        view.addSubview(shareButton)
        view.addSubview(infoLabel)
        
        // Настраиваем constraints
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().offset(-20)
            make.size.equalTo(40)
        }
        
        shareButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalTo(closeButton.snp.leading).offset(-16)
            make.size.equalTo(40)
        }
        
        infoLabel.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).offset(-20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.greaterThanOrEqualTo(44)
        }
        
        // Настраиваем scroll view
        scrollView.delegate = self
        
        // Добавляем действия для кнопок
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        shareButton.addTarget(self, action: #selector(shareButtonTapped), for: .touchUpInside)
    }
    
    private func setupGestures() {
        // Pan gesture для свайпа вниз для закрытия
        panGestureRecognizer = UIPanGestureRecognizer(target: self, action: #selector(handlePanGesture(_:)))
        view.addGestureRecognizer(panGestureRecognizer)
        
        // Tap gesture для скрытия/показа UI элементов
        tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTapGesture(_:)))
        tapGestureRecognizer.require(toFail: scrollView.panGestureRecognizer)
        view.addGestureRecognizer(tapGestureRecognizer)
    }
    
    private func configureCollage() {
        imageView.image = collage.image
        
        // Вычисляем размер изображения с учетом соотношения сторон
        let imageSize = collage.image.size
        let screenSize = view.bounds.size
        
        // Определяем размер imageView для правильного отображения
        let aspectRatio = imageSize.width / imageSize.height
        let screenAspectRatio = screenSize.width / screenSize.height
        
        var finalSize: CGSize
        if aspectRatio > screenAspectRatio {
            // Изображение шире экрана
            finalSize = CGSize(width: screenSize.width, height: screenSize.width / aspectRatio)
        } else {
            // Изображение выше экрана
            finalSize = CGSize(width: screenSize.height * aspectRatio, height: screenSize.height)
        }
        
        imageView.frame = CGRect(
            x: (screenSize.width - finalSize.width) / 2,
            y: (screenSize.height - finalSize.height) / 2,
            width: finalSize.width,
            height: finalSize.height
        )
        
        scrollView.contentSize = finalSize
        
        // Настраиваем информационную метку
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yyyy HH:mm"
        let aspectRatioName = AspectRatioManager.shared.ratio(by: collage.aspectRatioId)?.displayName ?? collage.aspectRatioId
        
        infoLabel.text = "Шаблон: \(collage.templateName)\nСоздан: \(formatter.string(from: collage.createdDate)) • \(aspectRatioName)"
    }
    
    // MARK: - Actions
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func shareButtonTapped() {
        print("🔗 FullscreenCollage: Начинаем sharing коллажа")
        
        SharingManager.shared.shareCollage(
            collage.image,
            templateName: collage.templateName,
            sourceView: shareButton,
            sourceRect: shareButton.bounds,
            from: self
        ) {
            print("✅ Sharing completed from FullscreenCollage")
        }
    }
    
    @objc private func handlePanGesture(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: view)
        let velocity = gesture.velocity(in: view)
        
        switch gesture.state {
        case .began:
            initialFrame = view.frame
            
        case .changed:
            // Позволяем только движение вниз для закрытия
            if translation.y > 0 {
                let progress = min(translation.y / 200, 1.0)
                view.transform = CGAffineTransform(translationX: 0, y: translation.y)
                view.alpha = 1.0 - progress * 0.5
            }
            
        case .ended, .cancelled:
            let shouldDismiss = translation.y > 100 || velocity.y > 500
            
            if shouldDismiss {
                UIView.animate(withDuration: 0.3, animations: {
                    self.view.transform = CGAffineTransform(translationX: 0, y: self.view.bounds.height)
                    self.view.alpha = 0
                }) { _ in
                    self.dismiss(animated: false)
                }
            } else {
                UIView.animate(withDuration: 0.3) {
                    self.view.transform = .identity
                    self.view.alpha = 1.0
                }
            }
            
        default:
            break
        }
    }
    
    @objc private func handleTapGesture(_ gesture: UITapGestureRecognizer) {
        // Переключаем видимость UI элементов
        let isHidden = closeButton.alpha == 0
        
        UIView.animate(withDuration: 0.3) {
            self.closeButton.alpha = isHidden ? 1 : 0
            self.shareButton.alpha = isHidden ? 1 : 0
            self.infoLabel.alpha = isHidden ? 1 : 0
        }
    }
}

// MARK: - UIScrollViewDelegate
extension FullscreenCollageViewController: UIScrollViewDelegate {
    func viewForZooming(in scrollView: UIScrollView) -> UIView? {
        return imageView
    }
    
    func scrollViewDidZoom(_ scrollView: UIScrollView) {
        // Центрируем изображение после зума
        let boundsSize = scrollView.bounds.size
        var frameToCenter = imageView.frame
        
        if frameToCenter.size.width < boundsSize.width {
            frameToCenter.origin.x = (boundsSize.width - frameToCenter.size.width) / 2
        } else {
            frameToCenter.origin.x = 0
        }
        
        if frameToCenter.size.height < boundsSize.height {
            frameToCenter.origin.y = (boundsSize.height - frameToCenter.size.height) / 2
        } else {
            frameToCenter.origin.y = 0
        }
        
        imageView.frame = frameToCenter
    }
} 