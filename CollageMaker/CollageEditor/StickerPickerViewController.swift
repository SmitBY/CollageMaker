import UIKit
import SnapKit

protocol StickerPickerDelegate: AnyObject {
    func stickerPicker(_ picker: StickerPickerViewController, didSelectSticker image: UIImage)
}

class StickerPickerViewController: UIViewController {
    
    // MARK: - Properties
    weak var delegate: StickerPickerDelegate?
    
    private let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
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
    
    // Массив доступных стикеров (будет заполнен динамически)
    private var availableStickers: [StickerItem] = []
    
    // Статический массив эмодзи и системных иконок
    private let defaultStickers: [StickerItem] = [
        // Эмодзи
        StickerItem(type: .emoji, content: "😀"),
        StickerItem(type: .emoji, content: "😍"),
        StickerItem(type: .emoji, content: "🤣"),
        StickerItem(type: .emoji, content: "😎"),
        StickerItem(type: .emoji, content: "🥳"),
        StickerItem(type: .emoji, content: "😇"),
        StickerItem(type: .emoji, content: "🤔"),
        StickerItem(type: .emoji, content: "😴"),
        StickerItem(type: .emoji, content: "🤗"),
        StickerItem(type: .emoji, content: "😘"),
        StickerItem(type: .emoji, content: "❤️"),
        StickerItem(type: .emoji, content: "💕"),
        StickerItem(type: .emoji, content: "💖"),
        StickerItem(type: .emoji, content: "✨"),
        StickerItem(type: .emoji, content: "🌟"),
        StickerItem(type: .emoji, content: "⭐"),
        StickerItem(type: .emoji, content: "🎉"),
        StickerItem(type: .emoji, content: "🎊"),
        StickerItem(type: .emoji, content: "🎈"),
        StickerItem(type: .emoji, content: "🎁"),
        StickerItem(type: .emoji, content: "🌈"),
        StickerItem(type: .emoji, content: "☀️"),
        StickerItem(type: .emoji, content: "🌙"),
        StickerItem(type: .emoji, content: "⚡"),
        StickerItem(type: .emoji, content: "🔥"),
        StickerItem(type: .emoji, content: "💎"),
        StickerItem(type: .emoji, content: "🌸"),
        StickerItem(type: .emoji, content: "🌺"),
        StickerItem(type: .emoji, content: "🌻"),
        StickerItem(type: .emoji, content: "🎵"),
        
        // Системные иконки
        StickerItem(type: .systemIcon, content: "heart.fill"),
        StickerItem(type: .systemIcon, content: "star.fill"),
        StickerItem(type: .systemIcon, content: "bolt.fill"),
        StickerItem(type: .systemIcon, content: "flame.fill"),
        StickerItem(type: .systemIcon, content: "crown.fill"),
        StickerItem(type: .systemIcon, content: "diamond.fill"),
        StickerItem(type: .systemIcon, content: "sparkles"),
        StickerItem(type: .systemIcon, content: "sun.max.fill"),
        StickerItem(type: .systemIcon, content: "moon.fill"),
        StickerItem(type: .systemIcon, content: "cloud.fill"),
        StickerItem(type: .systemIcon, content: "snowflake"),
        StickerItem(type: .systemIcon, content: "leaf.fill")
    ]
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupActions()
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        loadAllStickers()
    }
    
    // MARK: - Setup
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        // Регистрируем ячейку после создания collectionView
        collectionView.register(StickerCell.self, forCellWithReuseIdentifier: StickerCell.identifier)
        collectionView.delegate = self
        collectionView.dataSource = self
        
        view.addSubview(titleLabel)
        view.addSubview(closeButton)
        view.addSubview(collectionView)
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
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.bottom.equalToSuperview()
        }
    }
    
    private func setupActions() {
        closeButton.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
    }
    
    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }
    
    // MARK: - Sticker Loading
    private func loadAllStickers() {
        var allStickers: [StickerItem] = []
        
        // Добавляем стикеры из Assets
        let assetStickers = loadAssetStickers()
        allStickers.append(contentsOf: assetStickers)
        
        // Добавляем эмодзи и системные иконки
        allStickers.append(contentsOf: defaultStickers)
        
        availableStickers = allStickers
        collectionView.reloadData()
    }
    
    private func loadAssetStickers() -> [StickerItem] {
        var assetStickers: [StickerItem] = []
        
        // Список всех стикеров в папке Bundle
        let stickerNames = [
            "sticker_01", "sticker_02", "sticker_03", "sticker_04", "sticker_05",
            "image-DFOtpQFrS2TDZYYTKpe3t1xzBXxyqN", "image-nI4awJxBtlfLCLZ7nqsHrh1qJ6AcSI",
            "image-SLW4v3ZRvj7Si9YqPiWqBSY3K1J03w", "image-590phLtyyJKpI5cBKwpJTC0PQxprv2"
        ]
        
        print("Проверяем стикеры...")
        
        // Проверяем каждый стикер
        for stickerName in stickerNames {
            if UIImage(named: stickerName) != nil {
                print("Найден стикер: \(stickerName)")
                let stickerItem = StickerItem(type: .bundleImage, content: stickerName)
                assetStickers.append(stickerItem)
            } else {
                print("Стикер не найден: \(stickerName)")
            }
        }
        
        print("Загружено \(assetStickers.count) стикеров из Bundle")
        return assetStickers
    }
}

// MARK: - UICollectionViewDataSource
extension StickerPickerViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return availableStickers.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        guard let cell = collectionView.dequeueReusableCell(withReuseIdentifier: StickerCell.identifier, for: indexPath) as? StickerCell else {
            print("Ошибка: не удалось создать StickerCell")
            return UICollectionViewCell()
        }
        
        guard indexPath.item < availableStickers.count else {
            print("Ошибка: индекс \(indexPath.item) выходит за границы массива размером \(availableStickers.count)")
            return cell
        }
        
        let stickerItem = availableStickers[indexPath.item]
        cell.configure(with: stickerItem)
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension StickerPickerViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let stickerItem = availableStickers[indexPath.item]
        
        if let image = stickerItem.generateImage() {
            delegate?.stickerPicker(self, didSelectSticker: image)
            dismiss(animated: true)
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

// MARK: - StickerItem
struct StickerItem {
    enum StickerType {
        case emoji
        case systemIcon
        case assetImage
        case bundleImage
    }
    
    let type: StickerType
    let content: String
    
    func generateImage(size: CGSize = CGSize(width: 60, height: 60)) -> UIImage? {
        switch type {
        case .emoji:
            return generateEmojiImage(emoji: content, size: size)
        case .systemIcon:
            return generateSystemIconImage(iconName: content, size: size)
        case .assetImage:
            return UIImage(named: content)
        case .bundleImage:
            return UIImage(named: content)
        }
    }
    
    private func generateEmojiImage(emoji: String, size: CGSize) -> UIImage? {
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        defer { UIGraphicsEndImageContext() }
        
        let font = UIFont.systemFont(ofSize: size.width * 0.7)
        let attributes: [NSAttributedString.Key: Any] = [.font: font]
        let textSize = emoji.size(withAttributes: attributes)
        
        let rect = CGRect(
            x: (size.width - textSize.width) / 2,
            y: (size.height - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        
        emoji.draw(in: rect, withAttributes: attributes)
        return UIGraphicsGetImageFromCurrentImageContext()
    }
    
    private func generateSystemIconImage(iconName: String, size: CGSize) -> UIImage? {
        let config = UIImage.SymbolConfiguration(pointSize: size.width * 0.6, weight: .medium)
        return UIImage(systemName: iconName, withConfiguration: config)?.withTintColor(.systemBlue, renderingMode: .alwaysOriginal)
    }
}

// MARK: - StickerCell
class StickerCell: UICollectionViewCell {
    static let identifier = "StickerCell"
    
    private let imageView = UIImageView()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        backgroundColor = .systemGray6
        layer.cornerRadius = 12
        
        imageView.contentMode = .scaleAspectFit
        contentView.addSubview(imageView)
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
    }
    
    func configure(with stickerItem: StickerItem) {
        if stickerItem.type == .assetImage {
            // Для файловых стикеров используем оригинальный размер
            imageView.contentMode = .scaleAspectFit
            imageView.image = stickerItem.generateImage()
        } else {
            // Для эмодзи и иконок используем стандартный размер
            imageView.contentMode = .scaleAspectFit
            imageView.image = stickerItem.generateImage()
        }
    }
    
    override var isSelected: Bool {
        didSet {
            backgroundColor = isSelected ? .systemBlue.withAlphaComponent(0.3) : .systemGray6
        }
    }
} 