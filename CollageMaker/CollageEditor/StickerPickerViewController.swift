import UIKit
import SnapKit

// MARK: - Protocols

protocol StickerPickerDelegate: AnyObject {
    func stickerPicker(_ picker: StickerPickerViewController, didSelectSticker image: UIImage)
}

protocol MultiStickerPickerDelegate: AnyObject {
    func stickerPicker(_ picker: StickerPickerViewController, didSelectMultipleStickers images: [UIImage])
}

class StickerPickerViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: StickerPickerDelegate?
    weak var multiDelegate: MultiStickerPickerDelegate?
    
    // Режим выбора
    private var isMultiSelectionMode = false
    private let maxSelectionCount = 10
    
    // Категории и стикеры
    private var categorizedStickers: [StickerCategory: [StickerItem]] = [:]
    private var currentCategory: StickerCategory = .frequentlyUsed
    private var availableCategories: [StickerCategory] = []
    
    // UI Components
    private let categoryTabView = CategoryTabView()
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.allowsMultipleSelection = true
        return collectionView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "Выберите стикер"
        label.font = UIFont.boldSystemFont(ofSize: 20)
        label.textAlignment = .center
        return label
    }()
    
    private let closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .systemGray
        return button
    }()
    
    // Кнопка переключения режима
    private let modeToggleButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Множественный", for: .normal)
        button.setImage(UIImage(systemName: "square"), for: .normal)
        button.setImage(UIImage(systemName: "checkmark.square"), for: .selected)
        button.tintColor = .systemBlue
        button.titleLabel?.font = UIFont.systemFont(ofSize: 16)
        return button
    }()
    
    // Кнопка применения выбранных
    private let applySelectionButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Добавить выбранные (0)", for: .normal)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        button.isHidden = true
        return button
    }()
    
    // Массив стикеров текущей категории
    private var currentCategoryStickers: [StickerItem] = []
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadCategorizedStickers()
        preloadCurrentCategoryImages()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Регистрируем ячейку после создания collectionView
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: StickerCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        // Настройка CategoryTabView
        categoryTabView.delegate = self
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(modeToggleButton)
        view.addSubview(categoryTabView)
        view.addSubview(collectionView)
        view.addSubview(applySelectionButton)
    }
    
    private func setupConstraints() {
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }
        
        closeButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(20)
            make.width.height.equalTo(30)
        }
        
        modeToggleButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.equalToSuperview().offset(20)
            make.height.equalTo(30)
        }
        
        categoryTabView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(categoryTabView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(applySelectionButton.snp.top).offset(-20)
        }
        
        applySelectionButton.snp.makeConstraints { make in
            make.bottom.equalTo(view.safeAreaLayoutGuide).inset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(50)
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        modeToggleButton.addTarget(self, action: #selector(modeToggleButtonTapped), for: .touchUpInside)
        applySelectionButton.addTarget(self, action: #selector(applySelectionButtonTapped), for: .touchUpInside)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    @objc private func modeToggleButtonTapped() {
        isMultiSelectionMode.toggle()
        updateModeUI()
        clearAllSelections()
    }
    
    @objc private func applySelectionButtonTapped() {
        let selectedStickers = currentCategoryStickers.filter { $0.isSelected }
        let selectedImages = selectedStickers.compactMap { $0.generateImage() }
        
        if !selectedImages.isEmpty {
            // Отмечаем стикеры как использованные
            for sticker in selectedStickers {
                StickerManager.shared.markStickerAsUsed(sticker)
            }
            
            multiDelegate?.stickerPicker(self, didSelectMultipleStickers: selectedImages)
            dismiss(animated: true)
        }
    }
    
    private func updateModeUI() {
        modeToggleButton.isSelected = isMultiSelectionMode
        modeToggleButton.setTitle(isMultiSelectionMode ? "Одиночный" : "Множественный", for: .normal)
        applySelectionButton.isHidden = !isMultiSelectionMode
        titleLabel.text = isMultiSelectionMode ? "Выберите стикеры" : "Выберите стикер"
        
        updateSelectionCountUI()
    }
    
    private func updateSelectionCountUI() {
        if isMultiSelectionMode {
            let selectedCount = currentCategoryStickers.filter { $0.isSelected }.count
            applySelectionButton.setTitle("Добавить выбранные (\(selectedCount))", for: .normal)
            applySelectionButton.isEnabled = selectedCount > 0
            applySelectionButton.alpha = selectedCount > 0 ? 1.0 : 0.6
        }
    }
    
    private func clearAllSelections() {
        for i in 0..<currentCategoryStickers.count {
            currentCategoryStickers[i].isSelected = false
        }
        collectionView.reloadData()
        updateSelectionCountUI()
    }
    
    // MARK: - Sticker Loading
    private func loadCategorizedStickers() {
        categorizedStickers = StickerManager.shared.getAllStickers()
        availableCategories = StickerCategory.allCases.filter { categorizedStickers[$0]?.isEmpty == false }
        
        // Устанавливаем категорию по умолчанию (если часто используемые пусты, то эмоции)
        if categorizedStickers[.frequentlyUsed]?.isEmpty == true {
            currentCategory = .emotions
        }
        
        categoryTabView.configure(with: availableCategories, selectedCategory: currentCategory)
        updateCurrentCategoryStickers()
    }
    
    private func updateCurrentCategoryStickers() {
        currentCategoryStickers = categorizedStickers[currentCategory] ?? []
        
        // Анимированное обновление коллекции
        UIView.transition(with: collectionView, duration: 0.3, options: [.transitionCrossDissolve, .allowUserInteraction]) {
            self.collectionView.reloadData()
        } completion: { _ in
            // Анимация появления ячеек по очереди
            self.animateVisibleCells()
        }
        
        updateSelectionCountUI()
    }
    
    private func animateVisibleCells() {
        let visibleCells = collectionView.visibleCells
        
        // Сначала скрываем все ячейки
        visibleCells.forEach { cell in
            cell.alpha = 0
            cell.transform = CGAffineTransform(scaleX: 0.3, y: 0.3)
        }
        
        // Затем анимируем их появление по очереди
        for (index, cell) in visibleCells.enumerated() {
            UIView.animate(withDuration: 0.4, delay: Double(index) * 0.05, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction]) {
                cell.alpha = 1.0
                cell.transform = .identity
            }
        }
    }
    
    private func preloadCurrentCategoryImages() {
        // Предзагружаем изображения текущей категории
        StickerImageCache.shared.preloadImages(for: currentCategoryStickers)
        
        // Предзагружаем изображения других категорий в фоне
        DispatchQueue.global(qos: .background).async {
            for (category, stickers) in self.categorizedStickers {
                if category != self.currentCategory {
                    StickerImageCache.shared.preloadImages(for: stickers)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDataSource
extension StickerPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return currentCategoryStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.identifier, for: indexPath) as? StickerCell else {
            print("Ошибка: не удалось создать StickerCell")
            return UICollectionViewCell()
        }
        
        guard indexPath.item < currentCategoryStickers.count else {
            print("Ошибка: индекс \(indexPath.item) выходит за границы массива размером \(currentCategoryStickers.count)")
            return cell
        }
        
        let stickerItem = currentCategoryStickers[indexPath.item]
        cell.configure(with: stickerItem)
        
        // Устанавливаем состояние выбора ячейки в соответствии с режимом
        if isMultiSelectionMode && stickerItem.isSelected {
            collectionView.selectItem(at: indexPath, animated: false, scrollPosition: [])
        } else {
            collectionView.deselectItem(at: indexPath, animated: false)
        }
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StickerPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard indexPath.item < currentCategoryStickers.count else { return }
        
        if isMultiSelectionMode {
            // Множественный выбор
            let currentlySelected = currentCategoryStickers.filter { $0.isSelected }.count
            
            if currentCategoryStickers[indexPath.item].isSelected {
                // Убираем выбор
                currentCategoryStickers[indexPath.item].isSelected = false
            } else {
                // Добавляем выбор (с ограничением)
                if currentlySelected < maxSelectionCount {
                    currentCategoryStickers[indexPath.item].isSelected = true
                } else {
                    // Показываем предупреждение о лимите
                    let alert = UIAlertController(
                        title: "Лимит выбора", 
                        message: "Можно выбрать максимум \(maxSelectionCount) стикеров",
                        preferredStyle: .alert
                    )
                    alert.addAction(UIAlertAction(title: "ОК", style: .default))
                    present(alert, animated: true)
                    
                    // Убираем выделение ячейки
                    collectionView.deselectItem(at: indexPath, animated: true)
                    return
                }
            }
            
            // Обновляем ячейку
            if let cell = collectionView.cellForItem(at: indexPath) as? StickerCell {
                cell.setSelected(currentCategoryStickers[indexPath.item].isSelected)
            }
            
            updateSelectionCountUI()
        } else {
            // Одиночный выбор
            let stickerItem = currentCategoryStickers[indexPath.item]
            
            if let image = stickerItem.generateImage() {
                // Отмечаем стикер как использованный
                StickerManager.shared.markStickerAsUsed(stickerItem)
                
                delegate?.stickerPicker(self, didSelectSticker: image)
                dismiss(animated: true)
            }
        }
    }
    
    func collectionView(_ collectionView: UICollectionView, didDeselectItemAt indexPath: IndexPath) {
        // Этот метод вызывается только в множественном режиме
        if isMultiSelectionMode && indexPath.item < currentCategoryStickers.count {
            currentCategoryStickers[indexPath.item].isSelected = false
            if let cell = collectionView.cellForItem(at: indexPath) as? StickerCell {
                cell.setSelected(false)
            }
            updateSelectionCountUI()
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension StickerPickerViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        // Простой фиксированный размер для избежания проблем с расчетами
        return CGSize(width: 80, height: 80)
    }
}

// MARK: - CategoryTabViewDelegate
extension StickerPickerViewController: CategoryTabViewDelegate {
    func categoryTabView(_ view: CategoryTabView, didSelectCategory category: StickerCategory) {
        currentCategory = category
        updateCurrentCategoryStickers()
        clearAllSelections()
        preloadCurrentCategoryImages()
    }
}

 