//
//  HomeTabBarController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class HomeTabBarController: UIViewController {
    // MARK: - View Models
    var homeViewModel: HomeViewModel!
    var galleryViewModel: GalleryViewModel!
    var editViewModel: EditViewModel!
    
    // MARK: - Coordinator
    weak var coordinator: HomeTabBarCoordinator?
    
    // MARK: - Private Properties
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    // Title label displayed at the top of the screen (if needed)
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        return label
    }()
    
    // Settings button at the top-right corner
    let settingsButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "gear"), for: .normal)
        return button
    }()
    
    // Container view to host child view controllers
    let containerView: UIView = {
        let view = UIView()
        return view
    }()
    
    // Custom tab bar view
    let tabBarView: UIView = {
        let view = UIView()
        view.backgroundColor = .lightGray
        return view
    }()
    
    // Stack view to hold tab bar buttons
    let stackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        return stackView
    }()
    
    // Gallery tab button
    let galleryButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "photo.on.rectangle"), for: .normal)
        button.setTitle("Gallery", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.black, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    // Home tab button
    let homeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "house"), for: .normal)
        button.setTitle("Home", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.black, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    // Edit tab button
    let editButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "pencil"), for: .normal)
        button.setTitle("Edit", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 12)
        button.setTitleColor(.black, for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        return button
    }()
    
    // MARK: - Initializers
    
    init(viewModel: HomeViewModel, galleryViewModel: GalleryViewModel, editViewModel: EditViewModel) {
        self.homeViewModel = viewModel
        self.galleryViewModel = galleryViewModel
        self.editViewModel = editViewModel
        super.init(nibName: nil, bundle: nil)
        print("HomeTabBarController initialized with view models in init")
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Lifecycle Methods
    
    override func viewDidLoad() {
        super.viewDidLoad()
        print("HomeTabBarController viewDidLoad")
        setupUI()
        setupButtonBindings()
        observeDataLoading() // Метод можно оставить пустым
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        print("HomeTabBarController viewDidAppear")
        // If no child controller is present in containerView, delay the selection of Home tab
        if children.isEmpty {
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                print("[HomeTabBarController] Delayed selectTab(index: 1) call from viewDidAppear")
                self.selectTab(index: 1)
            }
        }
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        // Add subviews
        view.addSubview(titleLabel)
        view.addSubview(settingsButton)
        view.addSubview(containerView)
        view.addSubview(tabBarView)
        
        tabBarView.addSubview(stackView)
        stackView.addArrangedSubview(galleryButton)
        stackView.addArrangedSubview(homeButton)
        stackView.addArrangedSubview(editButton)
        
        // Setup constraints using SnapKit
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.centerX.equalToSuperview()
        }
        
        settingsButton.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.trailing.equalToSuperview().inset(20)
        }
        
        containerView.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
            make.bottom.equalTo(tabBarView.snp.top)
        }
        
        tabBarView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(60)
        }
        
        stackView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    // MARK: - Button Bindings
    
    private func setupButtonBindings() {
        // Bind gallery button tap to select tab 0
        galleryButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 0)
        }.disposed(by: disposeBag)
        
        // Bind home button tap to select tab 1
        homeButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 1)
        }.disposed(by: disposeBag)
        
        // Bind edit button tap to select tab 2
        editButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 2)
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Tab Selection and Child Controller Management
    
    private func selectTab(index: Int) {
        print("Selecting tab index: \(index)")
        // Remove any existing child view controllers from containerView
        removeAllChildViewControllers()
        
        var selectedVC: UIViewController?
        
        switch index {
        case 0:
            selectedVC = createGalleryViewController()
            if let galleryTitle = galleryViewModel?.title.value {
                navigationItem.title = galleryTitle
            }
        case 1:
            selectedVC = createHomeViewController()
            if let homeTitle = homeViewModel?.title.value {
                navigationItem.title = homeTitle
            }
        case 2:
            selectedVC = createEditViewController()
            if let editTitle = editViewModel?.title.value {
                navigationItem.title = editTitle
            }
        default:
            break
        }
        
        if let vc = selectedVC {
            addChild(vc)
            vc.view.frame = containerView.bounds
            containerView.addSubview(vc.view)
            vc.didMove(toParent: self)
            print("Child view controller added with frame: \(vc.view.frame)")
        }
    }
    
    // Remove all child view controllers from the container view
    private func removeAllChildViewControllers() {
        for child in children {
            child.willMove(toParent: nil)
            child.view.removeFromSuperview()
            child.removeFromParent()
        }
        print("All child view controllers removed from containerView")
    }
    
    // MARK: - Child View Controller Creators
    
    private func createGalleryViewController() -> GalleryViewController? {
        guard let galleryVM = galleryViewModel else {
            print("GalleryViewModel is nil")
            return nil
        }
        return GalleryViewController(viewModel: galleryVM)
    }
    
    private func createHomeViewController() -> HomeViewController? {
        guard let homeVM = homeViewModel else {
            print("HomeViewModel is nil")
            return nil
        }
        return HomeViewController(viewModel: homeVM)
    }
    
    private func createEditViewController() -> EditViewController? {
        guard let editVM = editViewModel else {
            print("EditViewModel is nil")
            return nil
        }
        return EditViewController(viewModel: editVM)
    }
    
    // MARK: - Data Loading Observation
    
    private func observeDataLoading() {
        // Removing subscription to isLoading since it's not needed.
    }
    
    // MARK: - Public Methods
    
    func selectGalleryTab() {
        selectTab(index: 0)
    }
}
