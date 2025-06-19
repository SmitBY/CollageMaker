import UIKit
import SnapKit

class AspectRatioCell: UICollectionViewCell {
    static let identifier = "AspectRatioCell"
    
    // MARK: - UI Elements
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 12, weight: .medium)
        label.textColor = .white
        label.textAlignment = .center
        label.numberOfLines = 1
        return label
    }()
    
    private let backgroundContainer: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        return view
    }()
    
    // MARK: - Initialization
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupCell()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupCell() {
        contentView.addSubview(backgroundContainer)
        backgroundContainer.addSubview(titleLabel)
        
        backgroundContainer.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        titleLabel.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(4)
        }
    }
    
    // MARK: - Configuration
    func configure(with format: PhotoEditorViewController.AspectRatioFormat, isSelected: Bool) {
        titleLabel.text = format.rawValue
        
        if isSelected {
            backgroundContainer.backgroundColor = UIColor.systemBlue.withAlphaComponent(0.8)
            backgroundContainer.layer.borderColor = UIColor.systemBlue.cgColor
            titleLabel.textColor = .white
        } else {
            backgroundContainer.backgroundColor = UIColor.white.withAlphaComponent(0.2)
            backgroundContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
            titleLabel.textColor = .white
        }
    }
    
    override func prepareForReuse() {
        super.prepareForReuse()
        titleLabel.text = nil
        backgroundContainer.backgroundColor = UIColor.white.withAlphaComponent(0.2)
        backgroundContainer.layer.borderColor = UIColor.white.withAlphaComponent(0.3).cgColor
        titleLabel.textColor = .white
    }
} 