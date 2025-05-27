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
        view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "Onboarding Screen"
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 24)
        view.addSubview(label)
        
        label.snp.makeConstraints { make in
            make.center.equalToSuperview()
        }
        
        setupBindings()
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
