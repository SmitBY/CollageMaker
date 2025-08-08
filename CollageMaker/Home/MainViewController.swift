//
//  MainViewController.swift
//  CollageMaker
//
//  Created by AI Assistant on 02.02.2025.
//

import UIKit
import SnapKit

/// Главный экран приложения с приветствием и кнопкой создания проекта
class MainViewController: UIViewController {
    
    // MARK: - UI Elements
    
    private let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let templatesLabel: UILabel = {
        let label = UILabel()
        label.text = "Templates"
        label.font = UIFont.boldSystemFont(ofSize: 28)
        label.textColor = .white
        label.textAlignment = .left
        return label
    }()
    
    private let premiumButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("TRY PREMIUM", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 12)
        button.backgroundColor = UIColor.systemPurple.withAlphaComponent(0.8)
        button.layer.cornerRadius = 12
        button.contentEdgeInsets = UIEdgeInsets(top: 6, left: 12, bottom: 6, right: 12)
        return button
    }()
    
    private let gradientLayer: CAGradientLayer = {
        let gradient = CAGradientLayer()
        gradient.colors = [
            UIColor.systemOrange.cgColor,
            UIColor.systemPurple.cgColor,
            UIColor.systemBlue.cgColor
        ]
        gradient.locations = [0.0, 0.5, 1.0]
        gradient.startPoint = CGPoint(x: 0, y: 0)
        gradient.endPoint = CGPoint(x: 1, y: 1)
        return gradient
    }()
    
    private let contentView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    private let folderImageView: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "folder.fill")
        imageView.tintColor = .white
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "No Projects Yet"
        label.font = UIFont.boldSystemFont(ofSize: 24)
        label.textColor = .white
        label.textAlignment = .center
        return label
    }()
    
    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.text = "Start a new project and bring your\nideas to life."
        label.font = UIFont.systemFont(ofSize: 16)
        label.textColor = .white.withAlphaComponent(0.8)
        label.textAlignment = .center
        label.numberOfLines = 2
        return label
    }()
    
    private let createProjectButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Create New Project", for: .normal)
        button.setTitleColor(.white, for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = UIColor.systemPurple
        button.layer.cornerRadius = 25
        return button
    }()
    
    // MARK: - Properties
    
    weak var coordinator: MainTabBarCoordinator?
    
    // MARK: - Lifecycle
    
    override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupActions()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        gradientLayer.frame = view.bounds
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        // Добавляем градиентный фон
        view.layer.insertSublayer(gradientLayer, at: 0)
        
        // Добавляем все элементы
        view.addSubview(headerView)
        headerView.addSubview(templatesLabel)
        headerView.addSubview(premiumButton)
        
        view.addSubview(contentView)
        contentView.addSubview(folderImageView)
        contentView.addSubview(titleLabel)
        contentView.addSubview(subtitleLabel)
        contentView.addSubview(createProjectButton)
        
        // Настраиваем constraints
        headerView.snp.makeConstraints { make in
            make.top.equalTo(view.safeAreaLayoutGuide).offset(20)
            make.leading.trailing.equalToSuperview().inset(20)
            make.height.equalTo(40)
        }
        
        templatesLabel.snp.makeConstraints { make in
            make.leading.centerY.equalToSuperview()
        }
        
        premiumButton.snp.makeConstraints { make in
            make.trailing.centerY.equalToSuperview()
            make.height.equalTo(24)
        }
        
        contentView.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.width.equalToSuperview().inset(40)
        }
        
        folderImageView.snp.makeConstraints { make in
            make.top.equalToSuperview()
            make.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(folderImageView.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview()
        }
        
        subtitleLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(12)
            make.leading.trailing.equalToSuperview()
        }
        
        createProjectButton.snp.makeConstraints { make in
            make.top.equalTo(subtitleLabel.snp.bottom).offset(30)
            make.centerX.equalToSuperview()
            make.height.equalTo(50)
            make.width.equalTo(200)
            make.bottom.equalToSuperview()
        }
    }
    
    private func setupActions() {
        createProjectButton.addTarget(self, action: #selector(createProjectTapped), for: .touchUpInside)
        premiumButton.addTarget(self, action: #selector(premiumTapped), for: .touchUpInside)
    }
    
    // MARK: - Actions
    
    @objc private func createProjectTapped() {
        // Переключаемся на вкладку создания коллажа
        if let parent = self.parent as? MainTabBarController {
            parent.selectTab(index: 2)
        }
    }
    
    @objc private func premiumTapped() {
        // Показать информацию о премиуме
        let alert = UIAlertController(title: "Premium", message: "Функция Premium будет доступна в следующих обновлениях!", preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "OK", style: .default))
        present(alert, animated: true)
    }
}