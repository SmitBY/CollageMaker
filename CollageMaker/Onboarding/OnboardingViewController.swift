//
//  OnboardingViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa

class OnboardingViewController: UIViewController {
    var viewModel: OnboardingViewModel!
    let disposeBag = DisposeBag()
    
    override init(nibName nibNameOrNil: String?, bundle nibBundleOrNil: Bundle?) {
        super.init(nibName: nibNameOrNil, bundle: nibBundleOrNil)
    }
    
    convenience init(viewModel: OnboardingViewModel) {
        self.init(nibName: nil, bundle: nil)
        self.viewModel = viewModel
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        setupUI()
        setupBindings()
    }
    
    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }
    
    private func setupUI() {
        // Фоновое изображение вместо градиента
        removeBackgroundGradientLayers()
        setBackgroundImage(named: "loadback")
        
        // Контейнер для контента
        let contentView = UIView()
        contentView.backgroundColor = UIColor(white: 1.0, alpha: 0.08)
        contentView.layer.cornerRadius = 20
        contentView.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        view.addSubview(contentView)
        
        // Логотип/иконка приложения
        let logoImageView = UIImageView()
        logoImageView.image = UIImage(systemName: "photo.on.rectangle.angled")
        logoImageView.tintColor = .systemBlue
        logoImageView.contentMode = .scaleAspectFit
        contentView.addSubview(logoImageView)
        
        // Заголовок
        let titleLabel = UILabel()
        titleLabel.text = "Добро пожаловать в CollageMaker"
        titleLabel.font = UIFont.boldSystemFont(ofSize: 28)
        titleLabel.textAlignment = .center
        titleLabel.numberOfLines = 0
        titleLabel.textColor = .label
        contentView.addSubview(titleLabel)
        
        // Описание
        let descriptionLabel = UILabel()
        descriptionLabel.text = "Создавайте потрясающие коллажи из ваших фотографий с помощью готовых шаблонов и инструментов редактирования"
        descriptionLabel.font = UIFont.systemFont(ofSize: 17)
        descriptionLabel.textAlignment = .center
        descriptionLabel.numberOfLines = 0
        descriptionLabel.textColor = .systemGray
        contentView.addSubview(descriptionLabel)
        
        // Кнопка "Начать"
        let startButton = UIButton(type: .system)
        startButton.setTitle("Начать создание коллажей", for: .normal)
        startButton.titleLabel?.font = UIFont.boldSystemFont(ofSize: 18)
        startButton.setTitleColor(.white, for: .normal)
        startButton.backgroundColor = .systemBlue
        startButton.layer.cornerRadius = 25
        contentView.addSubview(startButton)
        
        // Constraints
        contentView.snp.makeConstraints { make in
            make.leading.trailing.bottom.equalToSuperview()
            make.top.equalTo(view.safeAreaLayoutGuide).offset(100)
        }
        
        logoImageView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(40)
            make.centerX.equalToSuperview()
            make.size.equalTo(80)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.top.equalTo(logoImageView.snp.bottom).offset(30)
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        descriptionLabel.snp.makeConstraints { make in
            make.top.equalTo(titleLabel.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(30)
        }
        
        startButton.snp.makeConstraints { make in
            make.top.equalTo(descriptionLabel.snp.bottom).offset(40)
            make.leading.trailing.equalToSuperview().inset(30)
            make.height.equalTo(50)
        }
        
        // Ничего не требуется, фон тянется Auto Layout'ом
    }
    
    private func setupBindings() {
        viewModel.title.bind(to: self.rx.title).disposed(by: disposeBag)
    }
}

extension Reactive where Base: OnboardingViewController {
    var title: Binder<String> {
        return Binder(base) { viewController, title in
            viewController.title = title
        }
    }
}
