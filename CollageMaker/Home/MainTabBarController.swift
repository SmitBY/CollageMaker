//
//  MainTabBarController.swift
//  CollageMaker
//
//  Created by AI Assistant on 02.02.2025.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

class MainTabBarController: UIViewController {
    
    // MARK: - Properties
    
    weak var coordinator: MainTabBarCoordinator?
    private let disposeBag = DisposeBag()
    
    // MARK: - UI Elements
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let customTabBar: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.black.withAlphaComponent(0.9)
        return view
    }()
    
    private let tabStackView: UIStackView = {
        let stackView = UIStackView()
        stackView.axis = .horizontal
        stackView.distribution = .fillEqually
        stackView.alignment = .center
        return stackView
    }()
    
    // Tab buttons
    private let homeButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Home"), for: .normal)
        button.setTitle("Home", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.systemBlue, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        return button
    }()
    
    private let templatesButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Template"), for: .normal)
        button.setTitle("Templates", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.systemBlue, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        return button
    }()
    
    private let createButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Create"), for: .normal)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        button.backgroundColor = UIColor.systemPurple
        button.layer.cornerRadius = 25
        return button
    }()
    
    private let projectsButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "Projects"), for: .normal)
        button.setTitle("Projects", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.systemBlue, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        return button
    }()
    
    private let moreButton: UIButton = {
        let button = UIButton(type: .custom)
        button.setImage(UIImage(named: "More"), for: .normal)
        button.setTitle("More", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.setTitleColor(.systemBlue, for: .selected)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 10)
        button.imageView?.contentMode = .scaleAspectFit
        button.tintColor = .white
        return button
    }()
    
    // Current displayed view controller
    private var currentViewController: UIViewController?
    private var selectedTabIndex: Int = 0
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupTabButtons()
        setupBindings()
        selectTab(index: 0) // По умолчанию показываем Home
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        view.backgroundColor = .black
        
        view.addSubview(containerView)
        view.addSubview(customTabBar)
        customTabBar.addSubview(tabStackView)
        
        // Добавляем кнопки в стек
        tabStackView.addArrangedSubview(homeButton)
        tabStackView.addArrangedSubview(templatesButton)
        tabStackView.addArrangedSubview(createButton)
        tabStackView.addArrangedSubview(projectsButton)
        tabStackView.addArrangedSubview(moreButton)
        
        // Constraints
        containerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.bottom.equalTo(customTabBar.snp.top)
        }
        
        customTabBar.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.height.equalTo(90) // Включая safe area
        }
        
        tabStackView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(10)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(view.safeAreaLayoutGuide.snp.bottom).offset(-10)
        }
        
        // Настраиваем кнопки
        setupTabButtons()
    }
    
    private func setupTabButtons() {
        // Настраиваем внешний вид кнопок
        let normalButtons = [homeButton, templatesButton, projectsButton, moreButton]
        
        for button in normalButtons {
            button.titleEdgeInsets = UIEdgeInsets(top: 0, left: -(button.imageView?.frame.width ?? 0), bottom: -20, right: 0)
            button.imageEdgeInsets = UIEdgeInsets(top: -15, left: 0, bottom: 0, right: -(button.titleLabel?.frame.width ?? 0))
            
            button.snp.makeConstraints { make in
                make.height.equalTo(50)
            }
        }
        
        // Центральная кнопка Create больше
        createButton.snp.makeConstraints { make in
            make.size.equalTo(50)
        }
    }
    
    private func setupBindings() {
        homeButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 0)
        }.disposed(by: disposeBag)
        
        templatesButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 1)
        }.disposed(by: disposeBag)
        
        createButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 2) // Переключаемся на вкладку создания коллажа
        }.disposed(by: disposeBag)
        
        projectsButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 3)
        }.disposed(by: disposeBag)
        
        moreButton.rx.tap.bind { [weak self] in
            self?.selectTab(index: 4)
        }.disposed(by: disposeBag)
    }
    
    // MARK: - Tab Management
    
    func selectTab(index: Int) { // Изменил на public для доступа из MainViewController
        guard index != selectedTabIndex || currentViewController == nil else { return }
        
        selectedTabIndex = index
        updateTabButtonStates()
        
        // Удаляем текущий view controller
        if let current = currentViewController {
            current.willMove(toParent: nil)
            current.view.removeFromSuperview()
            current.removeFromParent()
        }
        
        // Создаем новый view controller
        let newViewController = createViewController(for: index)
        currentViewController = newViewController
        
        // Добавляем новый view controller
        if let newVC = newViewController {
            addChild(newVC)
            newVC.view.frame = containerView.bounds
            containerView.addSubview(newVC.view)
            newVC.didMove(toParent: self)
        }
        
        // Обновляем стиль статус-бара после смены вкладки
        setNeedsStatusBarAppearanceUpdate()
    }

    // MARK: - Status Bar
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    override var childForStatusBarStyle: UIViewController? { nil }
    
    private func createViewController(for index: Int) -> UIViewController? {
        switch index {
        case 0: // Home
            let mainVC = MainViewController()
            mainVC.coordinator = coordinator
            return mainVC
        case 1: // Templates
            return createTemplatesViewController()
        case 2: // Create (этот кейс не должен использоваться, так как Create - это действие)
            return createCreateViewController()
        case 3: // Projects
            return createProjectsViewController()
        case 4: // More
            return createMoreViewController()
        default:
            return nil
        }
    }
    
    private func createTemplatesViewController() -> UIViewController {
        let vc = UIViewController()
        // Фон: mainback
        vc.removeBackgroundGradientLayers()
        vc.setBackgroundImage(named: "mainback")

        // Заголовок по центру сверху
        let titleLabel = UILabel()
        titleLabel.text = "Templates"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 24)
        titleLabel.textColor = .white
        titleLabel.textAlignment = .center
        vc.view.addSubview(titleLabel)

        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(vc.view.safeAreaLayoutGuide).offset(16)
            make.centerX.equalToSuperview()
        }

        return vc
    }
    
    private func createProjectsViewController() -> UIViewController {
        // Создаем рабочую галерею вместо заглушки
        let galleryViewModel = GalleryViewModel()
        let galleryViewController = GalleryViewController(viewModel: galleryViewModel)
        
        // Устанавливаем координатор для навигации
        if let mainCoordinator = coordinator {
            // Используем тот же координатор для совместимости
            galleryViewController.coordinator = mainCoordinator as? HomeTabBarCoordinator
        }
        
        return galleryViewController
    }
    
    private func createCreateViewController() -> UIViewController {
        // Создаем HomeViewController для создания коллажа
        let homeVM = HomeViewModel()
        let homeVC = HomeViewController(viewModel: homeVM)
        
        // Создаем специальный wrapper coordinator для навигации из HomeViewController
        if let mainCoordinator = coordinator {
            // Используем существующий координатор для навигации
            // HomeViewController будет использовать openCollageEditor для перехода к редактору
        }
        
        return homeVC
    }
    
    private func createMoreViewController() -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .black
        
        // ScrollView для контента
        let scrollView = UIScrollView()
        vc.view.addSubview(scrollView)
        
        let contentView = UIView()
        scrollView.addSubview(contentView)
        
        scrollView.snp.makeConstraints { make in
            make.edges.equalTo(vc.view.safeAreaLayoutGuide)
        }
        
        contentView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
            make.width.equalToSuperview()
        }
        
        // Создаем секции меню
        var lastView: UIView = contentView
        
        // Секция "Текущий план"
        let subscriptionSection = createSubscriptionSection()
        contentView.addSubview(subscriptionSection)
        subscriptionSection.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = subscriptionSection
        
        // Секция "Настройки"
        let settingsSection = createMenuSection(
            title: "Настройки",
            icon: "gear",
            items: [
                ("Общие настройки", "slider.horizontal.3"),
                ("Качество экспорта", "photo"),
                ("Уведомления", "bell")
            ]
        )
        contentView.addSubview(settingsSection)
        settingsSection.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
        }
        lastView = settingsSection
        
        // Секция "Поддержка"
        let supportSection = createMenuSection(
            title: "Поддержка",
            icon: "questionmark.circle",
            items: [
                ("Помощь", "questionmark.circle"),
                ("Обратная связь", "envelope"),
                ("О приложении", "info.circle")
            ]
        )
        contentView.addSubview(supportSection)
        supportSection.snp.makeConstraints { make in
            make.top.equalTo(lastView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.lessThanOrEqualToSuperview().inset(20)
        }
        
        return vc
    }
    
    private func createMenuSection(title: String, icon: String, items: [(String, String)]) -> UIView {
        let sectionView = UIView()
        sectionView.backgroundColor = .systemGray6
        sectionView.layer.cornerRadius = 12
        
        // Заголовок секции
        let headerView = UIView()
        headerView.backgroundColor = .clear
        sectionView.addSubview(headerView)
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemBlue
        iconImageView.contentMode = .scaleAspectFit
        headerView.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        headerView.addSubview(titleLabel)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        
        // Элементы меню
        var lastItemView: UIView = headerView
        for (index, item) in items.enumerated() {
            let itemView = createMenuItem(title: item.0, icon: item.1, isLast: index == items.count - 1)
            sectionView.addSubview(itemView)
            
            itemView.snp.makeConstraints { make in
                make.top.equalTo(lastItemView.snp.bottom)
                make.leading.trailing.equalToSuperview()
                make.height.equalTo(44)
                if index == items.count - 1 {
                    make.bottom.equalToSuperview()
                }
            }
            lastItemView = itemView
        }
        
        return sectionView
    }
    
    private func createMenuItem(title: String, icon: String, isLast: Bool) -> UIView {
        let itemView = UIView()
        itemView.backgroundColor = .clear
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = .systemGray
        iconImageView.contentMode = .scaleAspectFit
        itemView.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16)
        titleLabel.textColor = .label
        itemView.addSubview(titleLabel)
        
        let chevronImageView = UIImageView()
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        itemView.addSubview(chevronImageView)
        
        // Разделительная линия
        if !isLast {
            let separatorView = UIView()
            separatorView.backgroundColor = .separator
            itemView.addSubview(separatorView)
            
            separatorView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(52)
                make.trailing.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        return itemView
    }
    
    private func createSubscriptionSection() -> UIView {
        let sectionView = UIView()
        sectionView.backgroundColor = .systemGray6
        sectionView.layer.cornerRadius = 12
        
        // Заголовок секции
        let headerView = UIView()
        headerView.backgroundColor = .clear
        sectionView.addSubview(headerView)
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: "crown.fill")
        iconImageView.tintColor = .systemOrange
        iconImageView.contentMode = .scaleAspectFit
        headerView.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = "Текущий план"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 18)
        titleLabel.textColor = .label
        headerView.addSubview(titleLabel)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview()
            make.height.equalTo(50)
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.centerY.equalToSuperview()
            make.trailing.equalToSuperview().inset(16)
        }
        
        // Текущий план
        let currentPlanView = createSubscriptionMenuItem(
            title: "Бесплатный план", 
            subtitle: "Базовая функциональность",
            icon: "person.circle",
            isLast: false,
            isPremium: false
        )
        sectionView.addSubview(currentPlanView)
        
        currentPlanView.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Апгрейд до Pro
        let upgradeView = createSubscriptionMenuItem(
            title: "Перейти на Pro", 
            subtitle: "Разблокировать все функции",
            icon: "star.circle.fill",
            isLast: false,
            isPremium: true
        )
        sectionView.addSubview(upgradeView)
        
        upgradeView.snp.makeConstraints { make in
            make.top.equalTo(currentPlanView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
        }
        
        // Восстановить покупки
        let restoreView = createSubscriptionMenuItem(
            title: "Восстановить покупки", 
            subtitle: "Восстановить предыдущие покупки",
            icon: "arrow.clockwise.circle",
            isLast: true,
            isPremium: false
        )
        sectionView.addSubview(restoreView)
        
        restoreView.snp.makeConstraints { make in
            make.top.equalTo(upgradeView.snp.bottom)
            make.leading.trailing.equalToSuperview()
            make.height.equalTo(60)
            make.bottom.equalToSuperview()
        }
        
        // Добавляем обработчики нажатий
        let currentPlanTap = UITapGestureRecognizer(target: self, action: #selector(currentPlanTapped))
        currentPlanView.addGestureRecognizer(currentPlanTap)
        currentPlanView.isUserInteractionEnabled = true
        
        let upgradeTap = UITapGestureRecognizer(target: self, action: #selector(upgradeTapped))
        upgradeView.addGestureRecognizer(upgradeTap)
        upgradeView.isUserInteractionEnabled = true
        
        let restoreTap = UITapGestureRecognizer(target: self, action: #selector(restoreTapped))
        restoreView.addGestureRecognizer(restoreTap)
        restoreView.isUserInteractionEnabled = true
        
        return sectionView
    }
    
    private func createSubscriptionMenuItem(title: String, subtitle: String, icon: String, isLast: Bool, isPremium: Bool) -> UIView {
        let itemView = UIView()
        itemView.backgroundColor = .clear
        
        let iconImageView = UIImageView()
        iconImageView.image = UIImage(systemName: icon)
        iconImageView.tintColor = isPremium ? .systemOrange : .systemGray
        iconImageView.contentMode = .scaleAspectFit
        itemView.addSubview(iconImageView)
        
        let titleLabel = UILabel()
        titleLabel.text = title
        titleLabel.font = UIFont.systemFont(ofSize: 16, weight: isPremium ? .semibold : .regular)
        titleLabel.textColor = isPremium ? .systemOrange : .label
        itemView.addSubview(titleLabel)
        
        let subtitleLabel = UILabel()
        subtitleLabel.text = subtitle
        subtitleLabel.font = UIFont.systemFont(ofSize: 13)
        subtitleLabel.textColor = .systemGray
        itemView.addSubview(subtitleLabel)
        
        let chevronImageView = UIImageView()
        chevronImageView.image = UIImage(systemName: "chevron.right")
        chevronImageView.tintColor = .systemGray3
        chevronImageView.contentMode = .scaleAspectFit
        itemView.addSubview(chevronImageView)
        
        // Разделительная линия
        if !isLast {
            let separatorView = UIView()
            separatorView.backgroundColor = .separator
            itemView.addSubview(separatorView)
            
            separatorView.snp.makeConstraints { make in
                make.leading.equalToSuperview().offset(52)
                make.trailing.bottom.equalToSuperview()
                make.height.equalTo(0.5)
            }
        }
        
        iconImageView.snp.makeConstraints { make in
            make.leading.equalToSuperview().offset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(24)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.leading.equalTo(iconImageView.snp.trailing).offset(12)
            make.top.equalToSuperview().offset(12)
            make.trailing.equalTo(chevronImageView.snp.leading).offset(-8)
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.leading.equalTo(titleLabel)
            make.top.equalTo(titleLabel.snp.bottom).offset(2)
            make.trailing.equalTo(titleLabel)
            make.bottom.lessThanOrEqualToSuperview().inset(12)
        }
        
        chevronImageView.snp.makeConstraints { make in
            make.trailing.equalToSuperview().inset(16)
            make.centerY.equalToSuperview()
            make.size.equalTo(12)
        }
        
        return itemView
    }
    
    private func updateTabButtonStates() {
        let buttons = [homeButton, templatesButton, projectsButton, moreButton]
        
        for (index, button) in buttons.enumerated() {
            let isSelected = (index == selectedTabIndex)
            button.isSelected = isSelected
            button.tintColor = isSelected ? .systemBlue : .white
        }
        
        // Обновляем состояние центральной кнопки Create
        let isCreateSelected = (selectedTabIndex == 2)
        createButton.backgroundColor = isCreateSelected ? .systemBlue : .systemPurple
    }
    
    // MARK: - Subscription Actions
    
    @objc private func currentPlanTapped() {
        print("👤 [MainTabBarController] Текущий план нажат")
        showCurrentPlanDetails()
    }
    
    @objc private func upgradeTapped() {
        print("⭐ [MainTabBarController] Апгрейд нажат")
        showUpgradeScreen()
    }
    
    @objc private func restoreTapped() {
        print("🔄 [MainTabBarController] Восстановление покупок нажато")
        restorePurchases()
    }
    
    private func showCurrentPlanDetails() {
        let alert = UIAlertController(
            title: "Бесплатный план",
            message: "Вы используете бесплатную версию приложения.\n\nВключает:\n• Базовые шаблоны коллажей\n• Сохранение в галерею\n• Основные фильтры",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Перейти на Pro", style: .default) { [weak self] _ in
            self?.showUpgradeScreen()
        })
        
        alert.addAction(UIAlertAction(title: "OK", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func showUpgradeScreen() {
        let alert = UIAlertController(
            title: "CollageMaker Pro",
            message: "Разблокируйте все возможности приложения!\n\n✨ Премиум шаблоны\n🎨 Расширенные фильтры\n📱 Эксклюзивные стикеры\n🚀 Приоритетная поддержка\n\nВсего 299₽/месяц",
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "Подписаться", style: .default) { _ in
            print("🔥 [MainTabBarController] Начать процесс подписки")
            // Здесь будет интеграция с StoreKit
        })
        
        alert.addAction(UIAlertAction(title: "Позже", style: .cancel))
        
        present(alert, animated: true)
    }
    
    private func restorePurchases() {
        let alert = UIAlertController(
            title: "Восстановление покупок",
            message: "Восстанавливаем ваши предыдущие покупки...",
            preferredStyle: .alert
        )
        
        present(alert, animated: true)
        
        // Имитация процесса восстановления
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            alert.dismiss(animated: true) {
                let resultAlert = UIAlertController(
                    title: "Покупки не найдены",
                    message: "Не найдено предыдущих покупок для восстановления.",
                    preferredStyle: .alert
                )
                
                resultAlert.addAction(UIAlertAction(title: "OK", style: .default))
                
                self.present(resultAlert, animated: true)
            }
        }
    }
}