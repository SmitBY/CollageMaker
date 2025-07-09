//
//  GalleryViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa
import SnapKit

// MARK: - Gallery Cell
class GalleryCollectionViewCell: UICollectionViewCell {
    static let identifier = "GalleryCollectionViewCell"
    
    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        imageView.clipsToBounds = true
        imageView.layer.cornerRadius = 8
        imageView.backgroundColor = .systemGray6
        return imageView
    }()
    
    private let deleteButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark.circle.fill"), for: .normal)
        button.tintColor = .red
        button.backgroundColor = .white
        button.layer.cornerRadius = 12
        return button
    }()
    
    private let dateLabel: UILabel = {
        let label = UILabel()
        label.font = UIFont.systemFont(ofSize: 10)
        label.textColor = .white
        label.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        label.textAlignment = .center
        label.layer.cornerRadius = 4
        label.clipsToBounds = true
        return label
    }()
    
    var onDelete: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        contentView.addSubview(imageView)
        contentView.addSubview(deleteButton)
        contentView.addSubview(dateLabel)
        
        imageView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        deleteButton.snp.makeConstraints { make in
            make.top.trailing.equalToSuperview().inset(4)
            make.size.equalTo(24)
        }
        
        dateLabel.snp.makeConstraints { make in
            make.bottom.leading.trailing.equalToSuperview().inset(4)
            make.height.equalTo(16)
        }
        
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
    }
    
    @objc private func deleteButtonTapped() {
        onDelete?()
    }
    
    func configure(with collage: SavedCollage) {
        imageView.image = collage.image
        
        let formatter = DateFormatter()
        formatter.dateFormat = "dd.MM.yy"
        dateLabel.text = formatter.string(from: collage.createdDate)
    }
}

// MARK: - Gallery View Controller
class GalleryViewController: UIViewController {
    var viewModel: GalleryViewModel!
    let disposeBag = DisposeBag()
    
    weak var coordinator: HomeTabBarCoordinator?
    
    private lazy var collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumInteritemSpacing = 10
        layout.minimumLineSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 20, left: 20, bottom: 20, right: 20)
        
        let collectionView = UICollectionView(frame: .zero, collectionViewLayout: layout)
        collectionView.backgroundColor = .systemBackground
        collectionView.register(GalleryCollectionViewCell.self, forCellWithReuseIdentifier: GalleryCollectionViewCell.identifier)
        return collectionView
    }()
    
    private let emptyStateView: UIView = {
        let view = UIView()
        view.isHidden = true
        return view
    }()
    
    private let emptyImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo.on.rectangle")
        imageView.tintColor = .systemGray3
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let emptyLabel: UILabel = {
        let label = UILabel()
        label.text = "Нет сохраненных коллажей"
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 18, weight: .medium)
        label.textColor = .systemGray2
        return label
    }()
    
    private let emptySubLabel: UILabel = {
        let label = UILabel()
        label.text = "Создайте свой первый коллаж на вкладке \"Главная\""
        label.textAlignment = .center
        label.font = UIFont.systemFont(ofSize: 14)
        label.textColor = .systemGray3
        label.numberOfLines = 0
        return label
    }()
    
    private let activityIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.hidesWhenStopped = true
        return indicator
    }()
    
    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupBindings()
        setupCollectionView()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        viewModel.loadSavedCollages()
    }
    
    private func setupUI() {
        view.backgroundColor = .systemBackground
        
        view.addSubview(collectionView)
        view.addSubview(emptyStateView)
        view.addSubview(activityIndicator)
        
        emptyStateView.addSubview(emptyImageView)
        emptyStateView.addSubview(emptyLabel)
        emptyStateView.addSubview(emptySubLabel)
        
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        emptyStateView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.leading.trailing.equalToSuperview().inset(40)
        }
        
        emptyImageView.snp.makeConstraints { make in
            make.top.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        
        emptyLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyImageView.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview()
        }
        
        emptySubLabel.snp.makeConstraints { make in
            make.top.equalTo(emptyLabel.snp.bottom).offset(8)
            make.leading.trailing.bottom.equalToSuperview()
        }
        
        activityIndicator.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
    }
    
    private func setupBindings() {
        viewModel.title.bind(to: self.rx.title).disposed(by: disposeBag)
        
        viewModel.savedCollages
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] collages in
                self?.updateEmptyState(isEmpty: collages.isEmpty)
                self?.collectionView.reloadData()
            })
            .disposed(by: disposeBag)
        
        viewModel.isLoading
            .observe(on: MainScheduler.instance)
            .subscribe(onNext: { [weak self] isLoading in
                if isLoading {
                    self?.activityIndicator.startAnimating()
                } else {
                    self?.activityIndicator.stopAnimating()
                }
            })
            .disposed(by: disposeBag)
    }
    
    private func setupCollectionView() {
        collectionView.delegate = self
        collectionView.dataSource = self
    }
    
    private func updateEmptyState(isEmpty: Bool) {
        emptyStateView.isHidden = !isEmpty
        collectionView.isHidden = isEmpty
    }
    
    private func showDeleteConfirmation(for index: Int) {
        guard viewModel.getCollage(at: index) != nil else { return }
        
        let alert = UIAlertController(
            title: "Удалить коллаж?",
            message: "Это действие нельзя отменить",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.viewModel.deleteCollage(at: index)
        })
        
        present(alert, animated: true)
    }
    
    private func showCollageOptions(for index: Int) {
        guard let collage = viewModel.getCollage(at: index) else { return }
        
        let alert = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        
        alert.addAction(UIAlertAction(title: "Просмотр", style: .default) { [weak self] _ in
            self?.viewCollageFullscreen(collage)
        })
        
        alert.addAction(UIAlertAction(title: "Редактировать", style: .default) { [weak self] _ in
            self?.editCollage(collage)
        })
        
        alert.addAction(UIAlertAction(title: "Поделиться", style: .default) { [weak self] _ in
            self?.shareCollage(collage)
        })
        
        alert.addAction(UIAlertAction(title: "Удалить", style: .destructive) { [weak self] _ in
            self?.showDeleteConfirmation(for: index)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        if let popover = alert.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(alert, animated: true)
    }
    
    private func editCollage(_ collage: SavedCollage) {
        // Здесь будет переход к редактору с загруженным коллажем
        // Пока что просто показываем сообщение
        let alert = UIAlertController(
            title: "Редактирование",
            message: "Функция редактирования будет добавлена в следующем обновлении",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
    
    private func viewCollageFullscreen(_ collage: SavedCollage) {
        let fullscreenVC = FullscreenCollageViewController(collage: collage)
        present(fullscreenVC, animated: true)
    }
    
    private func shareCollage(_ collage: SavedCollage) {
        let activityVC = UIActivityViewController(activityItems: [collage.image], applicationActivities: nil)
        
        if let popover = activityVC.popoverPresentationController {
            popover.sourceView = view
            popover.sourceRect = CGRect(x: view.bounds.midX, y: view.bounds.midY, width: 0, height: 0)
        }
        
        present(activityVC, animated: true)
    }
}

// MARK: - Collection View Data Source
extension GalleryViewController: UICollectionViewDataSource {
    func collectionView(_ collectionView: UICollectionView, numberOfItemsInSection section: Int) -> Int {
        return viewModel.savedCollages.value.count
    }
    
    func collectionView(_ collectionView: UICollectionView, cellForItemAt indexPath: IndexPath) -> UICollectionViewCell {
        let cell = collectionView.dequeueReusableCell(withReuseIdentifier: GalleryCollectionViewCell.identifier, for: indexPath) as! GalleryCollectionViewCell
        
        let collage = viewModel.savedCollages.value[indexPath.item]
        cell.configure(with: collage)
        
        cell.onDelete = { [weak self] in
            self?.showDeleteConfirmation(for: indexPath.item)
        }
        
        return cell
    }
}

// MARK: - Collection View Delegate
extension GalleryViewController: UICollectionViewDelegate {
    func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        showCollageOptions(for: indexPath.item)
    }
}

// MARK: - Collection View Flow Layout Delegate
extension GalleryViewController: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView, layout collectionViewLayout: UICollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> CGSize {
        let padding: CGFloat = 20
        let spacing: CGFloat = 10
        let availableWidth = collectionView.frame.width - (padding * 2) - spacing
        let itemWidth = availableWidth / 2
        
        // Получаем коллаж для определения его соотношения сторон
        let collage = viewModel.savedCollages.value[indexPath.item]
        
        // Получаем соотношение сторон из AspectRatioManager
        if let aspectRatio = AspectRatioManager.shared.ratio(by: collage.aspectRatioId) {
            let itemHeight = itemWidth / aspectRatio.ratio
            return CGSize(width: itemWidth, height: itemHeight)
        } else {
            // Если не найдено соотношение, используем соотношение самого изображения
            let imageSize = collage.image.size
            let aspectRatio = imageSize.width / imageSize.height
            let itemHeight = itemWidth / aspectRatio
            return CGSize(width: itemWidth, height: itemHeight)
        }
    }
}

extension Reactive where Base: GalleryViewController {
    var title: Binder<String> {
        return Binder(base) { viewController, title in
            viewController.title = title
        }
    }
}
