import UIKit
import SnapKit

// MARK: - StickerCell
class StickerCell: UICollectionViewCell {
    static let identifier = "StickerCell"
    
    private let imageView = UIImageView()
    private let checkmarkView = UIImageView()
    private var isItemSelected = false
    
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
        
        // Настройка индикатора выбора
        checkmarkView.image = UIImage(systemName: "checkmark.circle.fill")
        checkmarkView.tintColor = .systemBlue
        checkmarkView.backgroundColor = .white
        checkmarkView.layer.cornerRadius = 10
        checkmarkView.isHidden = true
        contentView.addSubview(checkmarkView)
        
        imageView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.height.equalTo(40)
        }
        
        checkmarkView.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(4)
            make.width.height.equalTo(20)
        }
    }
    
    func configure(with stickerItem: StickerItem) {
        imageView.contentMode = .scaleAspectFit
        
        // Используем кэшированное изображение или генерируем новое
        StickerImageCache.shared.generateAndCacheImage(for: stickerItem, size: CGSize(width: 60, height: 60)) { [weak self] image in
            self?.imageView.image = image
        }
        
        setSelected(stickerItem.isSelected)
    }
    
    func setSelected(_ selected: Bool) {
        isItemSelected = selected
        checkmarkView.isHidden = !selected
        
        if selected {
            backgroundColor = .systemBlue.withAlphaComponent(0.3)
            layer.borderWidth = 2
            layer.borderColor = UIColor.systemBlue.cgColor
        } else {
            backgroundColor = .systemGray6
            layer.borderWidth = 0
            layer.borderColor = UIColor.clear.cgColor
        }
    }
    
    override var isSelected: Bool {
        didSet {
            // Переопределяем стандартное поведение, используем свой setSelected метод
        }
    }
} 