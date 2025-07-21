import UIKit
import SnapKit

protocol FramePickerViewDelegate: AnyObject {
    func framePickerView(_ pickerView: FramePickerView, didSelectFrameShape frameShape: FrameShape)
}

class FramePickerView: UIView {
    
    // MARK: - Properties
    weak var delegate: FramePickerViewDelegate?
    
    // Callbacks для управления видимостью кнопки сохранения
    var onShow: (() -> Void)?
    var onHide: (() -> Void)?    
    private let collectionView: UICollectionView
    private let titleLabel = UILabel()
    private let containerView = UIView()
    
    private let frameShapes = FrameShape.allCases
    private var selectedFrameShape: FrameShape = .none
    
    // MARK: - Initializer
    override init(frame: CGRect) {
        // Настройка layout для коллекции
        let layout = UICollectionViewFlowLayout()
        layout.scrollDirection = .horizontal
        layout.minimumLineSpacing = 8
        layout.minimumInteritemSpacing = 8
        layout.sectionInset = UIEdgeInsets(top: 8, left: 16, bottom: 8, right: 16)
        
        collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupCollectionView()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    private func setupUI() {
        backgroundColor = .clear
        
        // Container view с закругленными углами и тенью
        containerView.backgroundColor = UIColor.systemBackground.withAlphaComponent(0.95)
        containerView.layer.cornerRadius = 16
        containerView.layer.shadowColor = UIColor.black.cgColor
        containerView.layer.shadowOffset = CGSize(width: 0, height: 4)
        containerView.layer.shadowOpacity = 0.1
        containerView.layer.shadowRadius = 8
        
        // Title label
        titleLabel.text = "Выберите форму рамки"
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.textAlignment = .center
        
        // Collection view setup
        collectionView.backgroundColor = .clear
        collectionView.showsHorizontalScrollIndicator = false
        collectionView.allowsSelection = true
        
        // Add subviews
        addSubview(containerView)
        containerView.addSubview(titleLabel)
        containerView.addSubview(collectionView)
    }
    
    private func setupConstraints() {
        containerView.snp.makeConstraints { make in
            make.edges.equalToSuperview().inset(8)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(20)
        }
        
        collectionView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(80)
        }
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
        collectionView.register(FrameCell.self, forCellWithReuseIdentifier: FrameCell.identifier)
    }
    
    // MARK: - Public Methods
    
    /// Устанавливает выбранную форму рамки
    /// - Parameter frameShape: Форма рамки для выбора
    func setSelectedFrameShape(_ frameShape: FrameShape) {
        selectedFrameShape = frameShape
        
        // Обновляем выбранную ячейку
        if let index = frameShapes.firstIndex(of: frameShape) {
            let indexPath = IndexPath(item: index, section: 0)
            collectionView.selectItem(at: indexPath, animated: true, scrollPosition: .centeredHorizontally)
        }
    }
    
    /// Показывает picker с анимацией
    /// - Parameter animated: Использовать ли анимацию
    func show(animated: Bool = true) {
        isHidden = false
        onShow?() // Уведомляем о показе
        
        if animated {
            alpha = 0
            transform = CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: 20)
            
            UIView.animate(withDuration: 0.4, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5) {
                self.alpha = 1
                self.transform = .identity
            }
        }
    }
    
    /// Скрывает picker с анимацией
    /// - Parameter animated: Использовать ли анимацию
    /// - Parameter completion: Блок завершения
    func hide(animated: Bool = true, completion: (() -> Void)? = nil) {
        if animated {
            UIView.animate(withDuration: 0.3, delay: 0, usingSpringWithDamping: 0.8, initialSpringVelocity: 0.5, animations: {
                self.alpha = 0
                self.transform = CGAffineTransform(scaleX: 0.9, y: 0.9).translatedBy(x: 0, y: 20)
            }) { _ in
                self.isHidden = true
                self.onHide?() // Уведомляем о скрытии
                self.transform = .identity
                completion?()
            }
        } else {
            isHidden = true
            self.onHide?() // Уведомляем о скрытии
            completion?()
        }
    }
    
    /// Получает текущую выбранную форму рамки
    /// - Returns: Выбранная форма рамки
    func getSelectedFrameShape() -> FrameShape {
        return selectedFrameShape
    }
}

// MARK: - UICollectionViewDataSource
extension FramePickerView: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return frameShapes.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: FrameCell.identifier, for: indexPath) as! FrameCell
        
        let frameShape = frameShapes[indexPath.item]
        cell.configure(with: frameShape)
        
        // Устанавливаем выбранное состояние
        cell.isSelected = (frameShape == selectedFrameShape)
        
        return cell
    }
}

// MARK: - UICollectionViewDelegate
extension FramePickerView: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        let frameShape = frameShapes[indexPath.item]
        
        // Обновляем выбранную форму
        selectedFrameShape = frameShape
        
        // Haptic feedback
        let selectionFeedback = UISelectionFeedbackGenerator()
        selectionFeedback.selectionChanged()
        
        // Уведомляем delegate
        delegate?.framePickerView(self, didSelectFrameShape: frameShape)
        
        // Анимируем ячейку
        if let cell = collectionView.cellForItem(at: indexPath) {
            UIView.animate(withDuration: 0.1, animations: {
                cell.transform = CGAffineTransform(scaleX: 0.95, y: 0.95)
            }) { _ in
                UIView.animate(withDuration: 0.2, delay: 0, usingSpringWithDamping: 0.7, initialSpringVelocity: 0.5) {
                    cell.transform = CGAffineTransform(scaleX: 1.05, y: 1.05)
                }
            }
        }
    }
}

// MARK: - UICollectionViewDelegateFlowLayout
extension FramePickerView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        return CGSize(width: 60, height: 64)
    }
} 