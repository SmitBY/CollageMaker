//
//  GalleryViewController.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import RxSwift
import RxCocoa

class GalleryViewController: UIViewController {
    var viewModel: GalleryViewModel!
    let disposeBag = DisposeBag()
    
    init(viewModel: GalleryViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .white
        
        let label = UILabel()
        label.text = "Gallery Screen"
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

extension Reactive where Base: GalleryViewController {
    var title: Binder<String> {
        return Binder(base) { viewController, title in
            viewController.title = title
        }
    }
}
