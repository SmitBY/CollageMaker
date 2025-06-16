import UIKit
import SnapKit

class FilterCollectionViewCell: UICollectionViewCell {
    static let identifier = "FilterCollectionViewCell"
    
    // MARK: - UI Elements
    private let imageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = 8
        return iv
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let selectionOverlay: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.3)
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    private let selectionBorder: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.systemBlue.cgColor
        view.layer.borderWidth = 2
        view.layer.cornerRadius = 8
        view.isHidden = true
        return view
    }()
    
    // MARK: - Properties
    override var isSelected: Bool {
        didSet {
            updateSelectionState()
        }
    }
    
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
        contentView.backgroundColor = .clear
        
        contentView.addSubview(imageView)
        contentView.addSubview(selectionOverlay)
        contentView.addSubview(selectionBorder)
        contentView.addSubview(titleLabel)
        
        imageView.snp.makeConstraints { make in
            make.top.left.right.equalToSuperview()
            make.height.equalTo(imageView.snp.width)
        }
        
        selectionOverlay.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        
        selectionBorder.snp.makeConstraints { make in
            make.edges.equalTo(imageView)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(imageView.snp.bottom).offset(4)
            make.left.right.bottom.equalToSuperview()
        }
    }
    
    // MARK: - Configuration
    func configure(with image: UIImage?, title: String) {
        imageView.image = image
        titleLabel.text = title
        updateSelectionState()
    }
    
    private func updateSelectionState() {
        selectionOverlay.isHidden = !isSelected
        selectionBorder.isHidden = !isSelected
        titleLabel.textColor = isSelected ? .systemBlue : .white
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        imageView.image = nil
        titleLabel.text = nil
        isSelected = false
    }
} 