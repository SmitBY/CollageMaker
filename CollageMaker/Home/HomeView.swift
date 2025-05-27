//
//  HomeView.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 31.01.2025.
//

import UIKit
import SnapKit

/// View layer for the Home screen. It contains a UICollectionView used to display collage templates.
class HomeView: UIView {
    /// Public collection view to display templates.
    let collectionView: UICollectionView = {
        let layout = UICollectionViewFlowLayout()
        layout.minimumLineSpacing = 10
        layout.minimumInteritemSpacing = 10
        layout.sectionInset = UIEdgeInsets(top: 10, left: 10, bottom: 10, right: 10)
        let cv = UICollectionView(frame: .zero, collectionViewLayout: layout)
        cv.backgroundColor = .white
        return cv
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    /// Sets up UI elements and their constraints.
    private func setupUI() {
        addSubview(collectionView)
        collectionView.register(CollageTemplateCell.self, forCellWithReuseIdentifier: "CollageTemplateCell")
        collectionView.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
}

extension HomeView: UICollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: UICollectionView,
                        layout collectionViewLayout: UICollectionViewLayout,
                        sizeForItemAt indexPath: IndexPath) -> CGSize {
        let leftRightInset: CGFloat = 10
        let width = collectionView.frame.width - 2 * leftRightInset
        let height = width * 3 / 4
        return CGSize(width: width, height: height)
    }
}
