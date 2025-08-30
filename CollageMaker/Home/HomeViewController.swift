//
//  HomeViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa
import Photos
import SnapKit

/// View controller for the Home screen - теперь это главный экран создания коллажей.
class HomeViewController: UIViewController {
    let viewModel: HomeViewModel
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    // Контейнер для фотографий (основная часть экрана)
    let photosContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
        return view
    }()
    
    let photosLabel: UILabel = {
        let label = UILabel()
        label.text = "Фотографии"
        label.font = UIFont.boldSystemFont(ofSize: 18)
        label.textAlignment = .left
        label.textColor = .white
        return label
    }()
    
    let photosCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsVerticalScrollIndicator = true
        return cv
    }()
    
    // Контейнер для шаблонов снизу (компактный)
    let templatesContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor(white: 1.0, alpha: 0.06)
        return view
    }()
    
    let templatesLabel: UILabel = {
        let label = UILabel()
        label.text = "Шаблоны коллажей"
        label.font = UIFont.boldSystemFont(ofSize: 16)
        label.textAlignment = .left
        label.textColor = .white
        return label
    }()
    
    let templatesCollectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .clear
        cv.showsHorizontalScrollIndicator = false
        return cv
    }()
    
    // Данные для коллекций
    private var collageTemplates: [CollageTemplate] = []
    private var userPhotos: [UIImage] = []
    private var selectedPhotos: [UIImage] = []
    
    // We'll store gridContainer's tag for later retrieval.
    private let gridContainerTag = 999
    
    /// Designated initializer with dependency injection.
    init(viewModel: HomeViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        print("[HomeViewController] init(viewModel:) called")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("[HomeViewController] viewDidLoad called")
        setupUI()
        setupCollectionViews()
        setupBindings()
        loadCollageTemplates()
        loadUserPhotos()
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Фон: изображение для остальных экранов
        removeBackgroundGradientLayers()
        setBackgroundImage(named: "loadback")
        
        // Добавляем все элементы интерфейса
        view.addSubview(photosContainerView)
        photosContainerView.addSubview(photosLabel)
        photosContainerView.addSubview(photosCollectionView)
        
        view.addSubview(templatesContainerView)
        templatesContainerView.addSubview(templatesLabel)
        templatesContainerView.addSubview(templatesCollectionView)
        
        // Настройка constraints
        
        // Фотографии занимают основную часть экрана
        photosContainerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(templatesContainerView.snp.top)
        }
        
        photosLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(24)
        }
        
        photosCollectionView.snp.makeConstraints { make in
            make.top.equalTo(photosLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        // Шаблоны внизу (компактно)
        templatesContainerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(view.safeAreaLayoutGuide)
            make.height.equalTo(120)
        }
        
        templatesLabel.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
        
        templatesCollectionView.snp.makeConstraints { make in
            make.top.equalTo(templatesLabel.snp.bottom).offset(4)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupCollectionViews() {
        // Регистрируем ячейки
        templatesCollectionView.register(TemplatePreviewCell.self, forCellWithReuseIdentifier: "TemplateCell")
        photosCollectionView.register(PhotoCell.self, forCellWithReuseIdentifier: "PhotoCell")
        
        // Устанавливаем делегаты
        templatesCollectionView.delegate = self
        templatesCollectionView.dataSource = self
        photosCollectionView.delegate = self
        photosCollectionView.dataSource = self
    }
    
    private func setupBindings() {
        // Пока нет других bindings
    }
    
    private func loadCollageTemplates() {
        updateTemplatesForSelectedPhotos()
    }
    
    private func updateTemplatesForSelectedPhotos() {
        let photoCount = selectedPhotos.count
        let allTemplates = CollageTemplatesManager.shared.templates
        
        if photoCount == 0 {
            // Показываем все доступные шаблоны
            collageTemplates = allTemplates
        } else {
            // Фильтруем шаблоны по количеству фотографий
            collageTemplates = allTemplates.filter { template in
                let requiredPhotos = template.positions.count
                return requiredPhotos >= photoCount && requiredPhotos <= photoCount + 5
            }
            
            // Если нет подходящих шаблонов, показываем все
            if collageTemplates.isEmpty {
                collageTemplates = allTemplates.filter { $0.positions.count >= photoCount }
            }
            
            // Если все еще пусто, показываем все шаблоны
            if collageTemplates.isEmpty {
                collageTemplates = allTemplates
            }
        }
        
        templatesCollectionView.reloadData()
        updateTemplatesLabel()
    }
    

    
    private func updatePhotosLabel() {
        let count = selectedPhotos.count
        if count == 0 {
            photosLabel.text = "Фотографии"
        } else {
            photosLabel.text = "Фотографии (выбрано: \(count))"
        }
    }
    
    private func updateTemplatesLabel() {
        let count = selectedPhotos.count
        if count == 0 {
            templatesLabel.text = "Примеры коллажей"
        } else {
            templatesLabel.text = "Шаблоны от \(count) до \(min(count + 5, 9)) фото"
        }
    }
    

    
    private func loadUserPhotos() {
        PhotoLibraryAccessManager.shared.checkPhotoLibraryAccess { [weak self] authorized in
            guard let self = self, authorized else { return }
            
            DispatchQueue.global(qos: .userInitiated).async {
                let fetchOptions = PHFetchOptions()
                fetchOptions.sortDescriptors = [NSSortDescriptor(key: "creationDate", ascending: false)]
                fetchOptions.fetchLimit = 50
                
                let assets = PHAsset.fetchAssets(with: .image, options: fetchOptions)
                var images: [UIImage] = []
                
                let imageManager = PHImageManager.default()
                let requestOptions = PHImageRequestOptions()
                requestOptions.isSynchronous = true
                requestOptions.deliveryMode = .highQualityFormat
                
                assets.enumerateObjects { asset, _, _ in
                    imageManager.requestImage(for: asset, targetSize: CGSize(width: 200, height: 200), contentMode: .aspectFill, options: requestOptions) { image, _ in
                        if let image = image {
                            images.append(image)
                        }
                    }
                }
                
                DispatchQueue.main.async {
                    self.userPhotos = images
                    self.photosCollectionView.reloadData()
                }
            }
        }
    }
    
    private func openCollageEditor(with template: CollageTemplate) {
        // Создаем массив фотографий для редактора
        var photosForEditor = selectedPhotos
        
        // Если выбрано меньше фото чем требует шаблон, добавляем пустые места
        let requiredPhotos = template.positions.count
        while photosForEditor.count < requiredPhotos {
            photosForEditor.append(UIImage()) // Пустое изображение как заглушка
        }
        
        // Используем координатор из view model
        if let coordinator = viewModel.coordinator {
            coordinator.showCollageEditor(with: template)
            return
        }
    }
}

// MARK: - UICollectionViewDataSource & UICollectionViewDelegate
extension HomeViewController: UICollectionViewDataSource, UICollectionViewDelegate, UICollectionViewDelegateFlowLayout {
    
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        if collectionView == templatesCollectionView {
            return collageTemplates.count
        } else if collectionView == photosCollectionView {
            return userPhotos.count
        }
        return 0
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        if collectionView == templatesCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "TemplateCell", for: indexPath) as! TemplatePreviewCell
            let template = collageTemplates[indexPath.item]
            cell.configure(with: template, selectedPhotos: selectedPhotos)
            return cell
        } else if collectionView == photosCollectionView {
            let cell = collectionView.dequeueReusableCell(withReuseIdentifier: "PhotoCell", for: indexPath) as! PhotoCell
            let photo = userPhotos[indexPath.item]
            let isSelected = selectedPhotos.contains { $0 === photo }
            cell.configure(with: photo, isSelected: isSelected)
            return cell
        }
        return UICollectionViewCell()
    }
    
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        if collectionView == templatesCollectionView {
            let template = collageTemplates[indexPath.item]
            openCollageEditor(with: template)
        } else if collectionView == photosCollectionView {
            let photo = userPhotos[indexPath.item]
            
            // Проверяем, выбрано ли уже это фото
            if let existingIndex = selectedPhotos.firstIndex(where: { $0 === photo }) {
                // Убираем фото из выбранных
                selectedPhotos.remove(at: existingIndex)
            } else {
                // Добавляем фото к выбранным
                selectedPhotos.append(photo)
            }
            
            // Обновляем шаблоны
            updateTemplatesForSelectedPhotos()
            
            // Обновляем подпись с количеством выбранных фото
            updatePhotosLabel()
            
            // Обновляем визуальное состояние ячейки
            photosCollectionView.reloadItems(at: [indexPath])
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        if collectionView == templatesCollectionView {
            return CGSize(width: 60, height: 60)
        } else if collectionView == photosCollectionView {
            // Вычисляем размер для сетки 3 колонки
            let padding: CGFloat = 16 * 2 + 8 * 2 // left + right + spacing
            let availableWidth = photosCollectionView.frame.width - padding
            let itemWidth = availableWidth / 3
            return CGSize(width: itemWidth, height: itemWidth)
        }
        return CGSize(width: 80, height: 80)
    }
}

// MARK: - Custom Cells

class TemplatePreviewCell: UICollectionViewCell {
    private let previewImageView = UIImageView()
    private let countLabel = UILabel()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(previewImageView)
        contentView.addSubview(countLabel)
        
        previewImageView.contentMode = .scaleAspectFit
        previewImageView.backgroundColor = .lightGray
        previewImageView.layer.cornerRadius = 8
        previewImageView.clipsToBounds = true
        
        countLabel.font = UIFont.boldSystemFont(ofSize: 10)
        countLabel.textColor = .white
        countLabel.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
        countLabel.textAlignment = .center
        countLabel.layer.cornerRadius = 8
        countLabel.clipsToBounds = true
        
        previewImageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        countLabel.snp.makeConstraints { make in
            make.bottom.trailing.equalToSuperview().inset(2)
            make.width.equalTo(16)
            make.height.equalTo(16)
        }
    }
    
    func configure(with template: CollageTemplate, selectedPhotos: [UIImage] = []) {
        // Создаем превью шаблона с выбранными фотографиями
        previewImageView.image = generateTemplatePreview(template: template, photos: selectedPhotos)
        
        // Показываем количество изображений в шаблоне
        countLabel.text = "\(template.positions.count)"
    }
    
    private func generateTemplatePreview(template: CollageTemplate, photos: [UIImage] = []) -> UIImage? {
        let size = CGSize(width: 60, height: 60)
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        guard let context = UIGraphicsGetCurrentContext() else { return nil }
        
        // Белый фон
        UIColor.white.setFill()
        context.fill(CGRect(origin: .zero, size: size))
        
        // Рисуем сетку шаблона
        let columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
        let rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        
        let cellWidth = size.width / CGFloat(columns)
        let cellHeight = size.height / CGFloat(rows)
        
        for (index, position) in template.positions.enumerated() {
            let rect = CGRect(x: CGFloat(position.0) * cellWidth + 1,
                             y: CGFloat(position.1) * cellHeight + 1,
                             width: cellWidth - 2,
                             height: cellHeight - 2)
            
            if index < photos.count {
                // Рисуем фотографию
                photos[index].draw(in: rect)
            } else {
                // Рисуем серый placeholder
                UIColor.lightGray.setFill()
                context.fill(rect)
            }
            
            // Рисуем рамку
            UIColor.white.setStroke()
            context.setLineWidth(1)
            context.stroke(rect)
        }
        
        return UIGraphicsGetImageFromCurrentImageContext()
    }
}

class PhotoCell: UICollectionViewCell {
    private let imageView = UIImageView()
    private let selectionOverlay = UIView()
    private let checkmarkImageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(checkmarkImageView)
        
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        
        selectionOverlay.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        selectionOverlay.layer.cornerRadius = 8
        selectionOverlay.isHidden = true
        
        checkmarkImageView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkImageView.tintColor = .systemBlue
        checkmarkImageView.backgroundColor = .white
        checkmarkImageView.layer.cornerRadius = 12
        checkmarkImageView.isHidden = true
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        checkmarkImageView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(4)
            make.size.equalTo(24)
        }
    }
    
    func configure(with image: UIImage, isSelected: Bool = false) {
        imageView.image = image
        selectionOverlay.isHidden = !isSelected
        checkmarkImageView.isHidden = !isSelected
        
        if isSelected {
            layer.borderColor = UIColor.systemBlue.cgColor
            layer.borderWidth = 2
        } else {
            layer.borderColor = UIColor.clear.cgColor
            layer.borderWidth = 0
        }
        layer.cornerRadius = 8
    }
}

extension Array {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
