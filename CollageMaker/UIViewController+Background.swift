//
//  UIViewController+Background.swift
//  CollageMaker
//
//  Created by AI Assistant on 11.08.2025.
//

import UIKit

private let kBackgroundImageViewTag = 987654

extension UIViewController {
    /// Устанавливает фоновое изображение на весь экран контроллера (за всеми сабвью).
    /// Если фоновое изображение уже добавлено, просто обновляет картинку.
    func setBackgroundImage(named imageName: String, contentMode: UIView.ContentMode = .scaleAspectFill) {
        var backgroundImageView = view.viewWithTag(kBackgroundImageViewTag) as? UIImageView
        if backgroundImageView == nil {
            let imageView = UIImageView()
            imageView.translatesAutoresizingMaskIntoConstraints = false
            imageView.tag = kBackgroundImageViewTag
            imageView.contentMode = contentMode
            imageView.clipsToBounds = true
            view.insertSubview(imageView, at: 0)
            NSLayoutConstraint.activate([
                imageView.topAnchor.constraint(equalTo: view.topAnchor),
                imageView.bottomAnchor.constraint(equalTo: view.bottomAnchor),
                imageView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
                imageView.trailingAnchor.constraint(equalTo: view.trailingAnchor)
            ])
            backgroundImageView = imageView
        }
        backgroundImageView?.image = UIImage(named: imageName)
    }

    /// Удаляет все градиентные слои из корневого view контроллера.
    func removeBackgroundGradientLayers() {
        guard let sublayers = view.layer.sublayers else { return }
        for layer in sublayers where layer is CAGradientLayer {
            layer.removeFromSuperlayer()
        }
    }
}


