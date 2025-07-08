import UIKit
import SnapKit

protocol CategoryTabViewDelegate: AnyObject {
    func categoryTabView(_ view: CategoryTabView, didSelectCategory category: StickerCategory)
}

class CategoryTabView: UIView {
    
    // MARK: - Properties
    weak var delegate: CategoryTabViewDelegate?
    private var categories: [StickerCategory] = []
    private var selectedCategory: StickerCategory = .frequentlyUsed
    
    private let scrollView: UIScrollView = {
        let scrollView = UIScrollView()
        scrollView.showsHorizontalScrollIndicator = false
        scrollView.scrollsToTop = false
        return scrollView
    }()
    
    private let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.spacing = 8
        stackView.distribution = .equalSpacing
        return stackView
    }()
    
    private var categoryButtons: [UIButton] = []
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .systemBackground
        
        addSubview(scrollView)
        scrollView.addSubview(stackView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.height.equalToSuperview()
        }
        
        // Добавляем разделительную линию снизу
        let separatorView = UIView()
        separatorView.backgroundColor = .systemGray4
        addSubview(separatorView)
        
        separatorView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(0.5)
        }
    }
    
    // MARK: - Public Methods
    func configure(with categories: [StickerCategory], selectedCategory: StickerCategory = .frequentlyUsed) {
        self.categories = categories
        self.selectedCategory = selectedCategory
        setupCategoryButtons()
    }
    
    func selectCategory(_ category: StickerCategory) {
        selectedCategory = category
        updateButtonStates()
        scrollToSelectedCategory()
    }
    
    // MARK: - Private Methods
    private func setupCategoryButtons() {
        // Удаляем существующие кнопки
        categoryButtons.forEach { $0.removeFromSuperview() }
        categoryButtons.removeAll()
        
        // Создаем кнопки для каждой категории
        for category in categories {
            let button = createCategoryButton(for: category)
            categoryButtons.append(button)
            stackView.addArrangedSubview(button)
        }
        
        updateButtonStates()
    }
    
    private func createCategoryButton(for category: StickerCategory) -> UIButton {
        let button = UIButton(type: .custom)
        
        // Конфигурация для иконки и текста
        var config = UIButton.Configuration.plain()
        config.image = UIImage(systemName: category.iconName)
        config.title = category.displayName
        config.imagePlacement = .top
        config.imagePadding = 4
        config.titleTextAttributesTransformer = UIConfigurationTextAttributesTransformer { attributes in
            var updatedAttributes = attributes
            updatedAttributes.font = UIFont.systemFont(ofSize: 12, weight: .medium)
            return updatedAttributes
        }
        
        button.configuration = config
        button.addTarget(self, action: #selector(categoryButtonTapped(_:)), for: .touchUpInside)
        
        // Устанавливаем размер кнопки
        button.snp.makeConstraints { make in
            make.width.equalTo(80)
        }
        
        return button
    }
    
    @objc private func categoryButtonTapped(_ sender: UIButton) {
        guard let index = categoryButtons.firstIndex(of: sender),
              index < categories.count else { return }
        
        let category = categories[index]
        selectedCategory = category
        updateButtonStates()
        delegate?.categoryTabView(self, didSelectCategory: category)
    }
    
    private func updateButtonStates() {
        for (index, button) in categoryButtons.enumerated() {
            let category = categories[index]
            let isSelected = category == selectedCategory
            
            // Анимированное обновление внешнего вида кнопки
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, options: [.allowUserInteraction, .curveEaseInOut]) {
                if isSelected {
                    button.configuration?.baseForegroundColor = .systemBlue
                    button.backgroundColor = .systemBlue.withAlphaComponent(0.15)
                    button.layer.cornerRadius = 12
                    button.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                } else {
                    button.configuration?.baseForegroundColor = .systemGray
                    button.backgroundColor = .clear
                    button.layer.cornerRadius = 0
                    button.transform = .identity
                }
            }
            
            // Добавляем пульсирующий эффект для выбранной кнопки
            if isSelected {
                addPulseAnimation(to: button)
            } else {
                button.layer.removeAnimation(forKey: "pulse")
            }
        }
    }
    
    private func addPulseAnimation(to button: UIButton) {
        let pulseAnimation = CABasicAnimation(keyPath: "transform.scale")
        pulseAnimation.duration = 1.0
        pulseAnimation.fromValue = 1.0
        pulseAnimation.toValue = 1.02
        pulseAnimation.autoreverses = true
        pulseAnimation.repeatCount = .infinity
        pulseAnimation.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        
        button.layer.add(pulseAnimation, forKey: "pulse")
    }
    
    private func scrollToSelectedCategory() {
        guard let selectedIndex = categories.firstIndex(of: selectedCategory),
              selectedIndex < categoryButtons.count else { return }
        
        let selectedButton = categoryButtons[selectedIndex]
        let buttonFrame = selectedButton.frame
        
        // Вычисляем оптимальную позицию для скролла
        let targetX = max(0, min(buttonFrame.midX - scrollView.frame.width / 2, 
                                scrollView.contentSize.width - scrollView.frame.width))
        
        scrollView.setContentOffset(CGPoint(x: targetX, y: 0), animated: true)
    }
}

// MARK: - CategoryTabCell
class CategoryTabCell: UICollectionViewCell {
    static let identifier = "CategoryTabCell"
    
    private let iconImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.tintColor = .systemGray
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .systemGray
        label.textAlignment = .center
        return label
    }()
    
    override var isSelected: Bool {
        didSet {
            updateAppearance()
        }
    }
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupCell() {
        contentView.addSubview(iconImageView)
        contentView.addSubview(titleLabel)
        
        iconImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(8)
            make.centerX.equalToSuperview()
            make.width.height.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(iconImageView.snp.bottom).offset(4)
            make.leading.trailing.equalToSuperview().inset(4)
            make.bottom.equalToSuperview().inset(8)
        }
    }
    
    func configure(with category: StickerCategory) {
        iconImageView.image = UIImage(systemName: category.iconName)
        titleLabel.text = category.displayName
        updateAppearance()
    }
    
    private func updateAppearance() {
        if isSelected {
            iconImageView.tintColor = .systemBlue
            titleLabel.textColor = .systemBlue
            backgroundColor = .systemBlue.withAlphaComponent(0.1)
            layer.cornerRadius = 8
        } else {
            iconImageView.tintColor = .systemGray
            titleLabel.textColor = .systemGray
            backgroundColor = .clear
            layer.cornerRadius = 0
        }
    }
} 