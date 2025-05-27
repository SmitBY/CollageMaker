//
//  CollageTemplateCell.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 29.01.2025.
//

import UIKit
import SnapKit
import RxSwift
import RxCocoa

/// Custom UICollectionViewCell to display a collage template preview with visible white borders and placeholder images.
/// The preview is centered in the cell. Special templates are handled by stretching a specific tile.
class CollageTemplateCell: UICollectionViewCell {
    
    // MARK: - UI Elements
    
    /// Header view displaying the template name.
    let headerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray5
        return view
    }()
    
    /// Title label for the template.
    let titleLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.font = UIFont.boldSystemFont(ofSize: 14)
        label.textColor = .black
        return label
    }()
    
    /// Container view for the collage preview.
    let previewContainer: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        return view
    }()
    
    // MARK: - Initializers
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - UI Setup
    
    private func setupUI() {
        contentView.addSubview(headerView)
        headerView.addSubview(titleLabel)
        contentView.addSubview(previewContainer)
        
        headerView.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(5)
            make.height.equalTo(20)
        }
        
        titleLabel.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
        
        previewContainer.snp.makeConstraints { make in
            make.top.equalTo(headerView.snp.bottom).offset(5)
            make.leading.trailing.bottom.equalToSuperview().inset(5)
        }
    }
    
    // MARK: - Configuration
    
    /// Configures the cell with a given collage template.
    /// The preview displays a grid of square tiles with white borders and placeholder images, centered in the cell.
    /// For special templates, one tile is stretched:
    /// - "Left Tall, Right Two": tile at (0,0) is tall (height spans 2 rows)
    /// - "Right Tall, Left Two": tile at (1,0) is tall
    /// - "Top Long, Bottom Two": tile at (0,0) is wide (width spans 2 columns)
    /// - "Bottom Long, Top Two": tile at (0,1) is wide
    func configure(with template: CollageTemplate) {
        titleLabel.text = template.name
        
        // Remove any previous preview subviews.
        previewContainer.subviews.forEach { $0.removeFromSuperview() }
        previewContainer.layoutIfNeeded()
        
        // Special template names list.
        let specialTemplates = ["Left Tall, Right Two", "Right Tall, Left Two", "Top Long, Bottom Two", "Bottom Long, Top Two"]
        
        // Определяем количество столбцов и строк.
        var columns: Int
        var rows: Int
        if specialTemplates.contains(template.name) {
            // Для специальных шаблонов будем считать, что всегда 2 колонки и 2 ряда.
            columns = 2
            rows = 2
        } else {
            columns = (template.positions.map { $0.0 }.max() ?? 0) + 1
            rows = (template.positions.map { $0.1 }.max() ?? 0) + 1
        }
        
        // Define margins.
        let outerMargin: CGFloat = 4
        let innerMargin: CGFloat = 2
        
        // Получаем размер previewContainer.
        let containerWidth = previewContainer.bounds.width > 0 ? previewContainer.bounds.width : 200
        let containerHeight = previewContainer.bounds.height > 0 ? previewContainer.bounds.height : 200
        
        // Calculate total spacing.
        let totalHorizontalSpacing = outerMargin * 2 + innerMargin * CGFloat(columns - 1)
        let totalVerticalSpacing = outerMargin * 2 + innerMargin * CGFloat(rows - 1)
        
        // Calculate side of each square tile (for standard case).
        let tileSide = min((containerWidth - totalHorizontalSpacing) / CGFloat(columns),
                           (containerHeight - totalVerticalSpacing) / CGFloat(rows))
        let standardTileSize = CGSize(width: tileSide, height: tileSide)
        
        // Calculate overall grid size.
        let gridWidth = outerMargin * 2 + CGFloat(columns) * tileSide + innerMargin * CGFloat(columns - 1)
        let gridHeight = outerMargin * 2 + CGFloat(rows) * tileSide + innerMargin * CGFloat(rows - 1)
        let gridSize = CGSize(width: gridWidth, height: gridHeight)
        
        // Create gridContainer and center it in previewContainer.
        let gridContainer = UIView()
        gridContainer.backgroundColor = .clear
        previewContainer.addSubview(gridContainer)
        gridContainer.snp.makeConstraints { make in
            make.center.equalToSuperview()
            make.size.equalTo(gridSize)
        }
        
        // For each position, add a tile view.
        // Здесь предполагается, что template.positions содержит (Int, Int) для каждой плитки.
        for (index, position) in template.positions.enumerated() {
            let col = CGFloat(position.0)
            let row = CGFloat(position.1)
            // Начальное значение для плитки – стандартный квадрат.
            var tileFrame = CGRect(x: outerMargin + col * (tileSide + innerMargin),
                                   y: outerMargin + row * (tileSide + innerMargin),
                                   width: tileSide,
                                   height: tileSide)
            
            // Специальная обработка в зависимости от имени шаблона.
            if template.name == "Left Tall, Right Two" && position == (0, 0) {
                // Stretch tile at (0,0) vertically.
                tileFrame.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Right Tall, Left Two" && position == (1, 0) {
                tileFrame.size.height = tileSide * 2 + innerMargin
            } else if template.name == "Top Long, Bottom Two" && position == (0, 0) {
                // Stretch tile at (0,0) horizontally.
                tileFrame.size.width = tileSide * 2 + innerMargin
            } else if template.name == "Bottom Long, Top Two" && position == (0, 1) {
                tileFrame.size.width = tileSide * 2 + innerMargin
            }
            
            let tileView = UIView(frame: tileFrame)
            tileView.backgroundColor = .clear
            tileView.layer.borderColor = UIColor.white.cgColor
            tileView.layer.borderWidth = 1.0  // Тонкая белая рамка.
            
            // Create image view for placeholder.
            let imageView = UIImageView(frame: tileView.bounds)
            imageView.contentMode = .scaleAspectFit
            imageView.backgroundColor = .clear
            if let placeholder = UIImage(named: "placeholder") {
                imageView.image = placeholder.resized(to: tileView.bounds.size)
            }
            tileView.addSubview(imageView)
            imageView.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            
            gridContainer.addSubview(tileView)
        }
    }
}

extension UIImage {
    // Resize the image to a specified size
    func resized(to size: CGSize) -> UIImage {
        return UIGraphicsImageRenderer(size: size).image { _ in
            self.draw(in: CGRect(origin: .zero, size: size))
        }
    }
}
