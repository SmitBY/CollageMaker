import UIKit
import SnapKit

class FrameCell: UICollectionViewCell {
    
    // MARK: - Properties
    static let identifier = "FrameCell"
    
    private let iconImageView = UIImageView()
    private let titleLabel = UILabel()
    private let containerView = UIView()
    
    private var frameShape: FrameShape = .none
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        // Container view для лучшего контроля layout
        containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.8)
        containerView.layer.cornerRadius = 8
        containerView.layer.borderWidth = 1
        containerView.layer.borderColor = UIColor.systemGray4.cgColor
        
        // Icon setup
        iconImageView.contentMode = .scaleAspectFit
        iconImageView.tintColor = .systemBlue
        
        // Label setup
        titleLabel.font = UIFont.systemFont(ofSize: 10, weight: .medium)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 1
        titleLabel.adjustsFontSizeToFitWidth = true
        titleLabel.minimumScaleFactor = 0.8
        
        // Add subviews
        contentView.addSubview(containerView)
        containerView.addSubview(iconImageView)
        containerView.addSubview(titleLabel)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(2)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(6)
            make.height.equalTo(iconImageView.snp.width)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(2)
            make.leading.trailing.bottom.equalToSuperview().inset(4)
            make.height.equalTo(12)
        }
    }
    
    // MARK: - Configuration
    func configure(with frameShape: FrameShape) {
        self.frameShape = frameShape
        
        // Настройка иконки
        iconImageView.image = UIImage(systemName: frameShape.iconName)
        
        // Настройка текста
        titleLabel.text = frameShape.displayName
        
        // Обновляем внешний вид
        updateAppearance()
    }
    
    // MARK: - Selection State
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    private func updateAppearance() {
        UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
            if self.isSelected {
                self.containerView.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.2)
                self.containerView.layer.borderColor = UIColor.systemBlue.cgColor
                self.containerView.layer.borderWidth = 2
                self.iconImageView.tintColor = .systemBlue
                self.titleLabel.textColor = .systemBlue
                self.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
            } else {
                self.containerView.backgroundColor = UIColor.systemGray6.withAlphaComponent(0.8)
                self.containerView.layer.borderColor = UIColor.systemGray4.cgColor
                self.containerView.layer.borderWidth = 1
                self.iconImageView.tintColor = .label
                self.titleLabel.textColor = .label
                self.transform = .identity
            }
        }
    }
    
    // MARK: - Touch Feedback
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesBegan(touches, with: event)
        
        UIView.animate(withDuration: 0.1) {
            self.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
        }
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesEnded(touches, with: event)
        
        UIView.animate(withDuration: 0.1) {
            self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
    }
    
    override func touchesCancelled(_ touches: Set<UITouch>, with event: UIEvent?) {
        super.touchesCancelled(touches, with: event)
        
        UIView.animate(withDuration: 0.1) {
            self.transform = self.isSelected ? CGAffineTransform(scaleX: 1.05, y: 1.05) : .identity
        }
    }
    
    // MARK: - Prepare for Reuse
    override func prepareForReuse() {
        super.prepareForReuse()
        
        iconImageView.image = nil
        titleLabel.text = nil
        isSelected = false
        transform = .identity
    }
} 