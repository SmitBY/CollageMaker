//
//  ResizableSlider.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import SnapKit

protocol ResizableSliderDelegate: AnyObject {
    func resizableSlider(_ slider: ResizableSlider, didChangeRatio ratio: CGFloat)
}

class ResizableSlider: UIView {
    
    // MARK: - Properties
    
    weak var delegate: ResizableSliderDelegate?
    
    private let track: UIView = {
        let view = UIView()
        view.backgroundColor = .systemGray4
        view.layer.cornerRadius = 2
        return view
    }()
    
    private let thumb: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBlue
        view.layer.cornerRadius = 12
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: 2)
        view.layer.shadowRadius = 4
        return view
    }()
    
    private let leftIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    private let rightIcon: UIImageView = {
        let imageView = UIImageView()
        imageView.image = UIImage(systemName: "photo")
        imageView.tintColor = .systemGray
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()
    
    var ratio: CGFloat = 0.5 {
        didSet {
            updateThumbPosition()
            delegate?.resizableSlider(self, didChangeRatio: ratio)
        }
    }
    
    var isVertical: Bool = false {
        didSet {
            setupConstraints()
        }
    }
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupGestures()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        addSubview(track)
        addSubview(leftIcon)
        addSubview(rightIcon)
        addSubview(thumb)
        
        setupConstraints()
    }
    
    private func setupConstraints() {
        if isVertical {
            // Вертикальный слайдер
            track.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.bottom.equalToSuperview().inset(20)
                make.width.equalTo(4)
            }
            
            leftIcon.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.top.equalToSuperview()
                make.size.equalTo(16)
            }
            
            rightIcon.snp.remakeConstraints { make in
                make.centerX.equalToSuperview()
                make.bottom.equalToSuperview()
                make.size.equalTo(16)
            }
            
            thumb.snp.remakeConstraints { make in
                make.centerX.equalTo(track)
                make.centerY.equalTo(track).offset((ratio - 0.5) * (bounds.height - 40))
                make.size.equalTo(24)
            }
        } else {
            // Горизонтальный слайдер
            track.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.trailing.equalToSuperview().inset(20)
                make.height.equalTo(4)
            }
            
            leftIcon.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.leading.equalToSuperview()
                make.size.equalTo(16)
            }
            
            rightIcon.snp.remakeConstraints { make in
                make.centerY.equalToSuperview()
                make.trailing.equalToSuperview()
                make.size.equalTo(16)
            }
            
            thumb.snp.remakeConstraints { make in
                make.centerY.equalTo(track)
                make.centerX.equalTo(track).offset((ratio - 0.5) * (bounds.width - 40))
                make.size.equalTo(24)
            }
        }
    }
    
    private func setupGestures() {
        let panGesture = UIPanGestureRecognizer(target: self, action: #selector(handlePan(_:)))
        thumb.addGestureRecognizer(panGesture)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        track.addGestureRecognizer(tapGesture)
    }
    
    // MARK: - Layout
    
    override func layoutSubviews() {
        super.layoutSubviews()
        updateThumbPosition()
    }
    
    private func updateThumbPosition() {
        if isVertical {
            let trackHeight = bounds.height - 40
            let offset = (ratio - 0.5) * trackHeight
            thumb.snp.updateConstraints { make in
                make.centerY.equalTo(track).offset(offset)
            }
        } else {
            let trackWidth = bounds.width - 40
            let offset = (ratio - 0.5) * trackWidth
            thumb.snp.updateConstraints { make in
                make.centerX.equalTo(track).offset(offset)
            }
        }
    }
    
    // MARK: - Gesture Handlers
    
    @objc private func handlePan(_ gesture: UIPanGestureRecognizer) {
        let translation = gesture.translation(in: self)
        
        if isVertical {
            let trackHeight = bounds.height - 40
            let newRatio = ratio + translation.y / trackHeight
            ratio = max(0, min(1, newRatio))
        } else {
            let trackWidth = bounds.width - 40
            let newRatio = ratio + translation.x / trackWidth
            ratio = max(0, min(1, newRatio))
        }
        
        gesture.setTranslation(.zero, in: self)
    }
    
    @objc private func handleTap(_ gesture: UITapGestureRecognizer) {
        let location = gesture.location(in: track)
        
        if isVertical {
            let trackHeight = track.bounds.height
            ratio = location.y / trackHeight
        } else {
            let trackWidth = track.bounds.width
            ratio = location.x / trackWidth
        }
    }
    
    // MARK: - Public Methods
    
    func setImages(_ leftImage: UIImage?, _ rightImage: UIImage?) {
        if let left = leftImage {
            leftIcon.image = left
        }
        if let right = rightImage {
            rightIcon.image = right
        }
    }
} 