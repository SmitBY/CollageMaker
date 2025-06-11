//
//  TextEditingPanel.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import SnapKit

protocol TextEditingPanelDelegate: AnyObject {
    func textEditingPanel(_ panel: TextEditingPanel, didUpdateText text: String)
    func textEditingPanel(_ panel: TextEditingPanel, didSelectColor color: UIColor)
    func textEditingPanel(_ panel: TextEditingPanel, didSelectFontSize size: CGFloat)
    func textEditingPanel(_ panel: TextEditingPanel, didSelectFont fontName: String)
    func textEditingPanelDidFinish(_ panel: TextEditingPanel)
}

class TextEditingPanel: UIView {
    
    // MARK: - Properties
    
    weak var delegate: TextEditingPanelDelegate?
    
    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .systemBackground
        view.layer.cornerRadius = 16
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOpacity = 0.2
        view.layer.shadowOffset = CGSize(width: 0, height: -4)
        view.layer.shadowRadius = 12
        
        view.layer.borderWidth = 1
        view.layer.borderColor = UIColor.systemGray4.cgColor
        
        return view
    }()
    
    private let textField: UITextField = {
        let field = UITextField()
        field.placeholder = "Введите текст"
        field.borderStyle = .roundedRect
        field.font = UIFont.systemFont(ofSize: 16)
        return field
    }()
    
    private let colorStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .horizontal
        stack.distribution = .fillEqually
        stack.spacing = 8
        return stack
    }()
    
    private let fontSizeSlider: UISlider = {
        let slider = UISlider()
        slider.minimumValue = 12
        slider.maximumValue = 72
        slider.value = 24
        return slider
    }()
    
    private let fontSizeLabel: UILabel = {
        let label = UILabel()
        label.text = "Размер: 24"
        label.font = UIFont.systemFont(ofSize: 14)
        return label
    }()
    
    private let fontPickerButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Шрифт: Системный", for: .normal)
        button.titleLabel?.font = UIFont.systemFont(ofSize: 14)
        button.backgroundColor = .systemGray6
        button.layer.cornerRadius = 8
        button.contentHorizontalAlignment = .left
        
        // Используем современный UIButton.Configuration вместо deprecated contentEdgeInsets
        var config = UIButton.Configuration.plain()
        config.title = "Шрифт: Системный"
        config.baseBackgroundColor = .systemGray6
        config.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 12, bottom: 8, trailing: 12)
        config.cornerStyle = .medium
        config.titleAlignment = .leading
        button.configuration = config
        
        return button
    }()
    

    
    private let availableFonts = [
        "System": UIFont.systemFont(ofSize: 24).fontName,
        "Helvetica": "Helvetica",
        "Times": "Times-Roman", 
        "Courier": "Courier",
        "Arial": "ArialMT",
        "Georgia": "Georgia",
        "Verdana": "Verdana",
        "Trebuchet": "TrebuchetMS",
        "Impact": "Impact",
        "Comic Sans": "ComicSansMS"
    ]
    
    private var selectedFontName = "System"
    
    private let doneButton: UIButton = {
        let button = UIButton(type: .system)
        button.setTitle("Готово", for: .normal)
        button.titleLabel?.font = UIFont.boldSystemFont(ofSize: 16)
        button.backgroundColor = .systemBlue
        button.setTitleColor(.white, for: .normal)
        button.layer.cornerRadius = 8
        
        // Добавляем тень для лучшей видимости
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowOpacity = 0.3
        button.layer.shadowRadius = 4
        
        return button
    }()
    
    private let colors: [UIColor] = [
        .black, .white, .red, .blue, .green,
        .yellow, .orange, .purple, .systemPink, .brown
    ]
    
    // MARK: - Initialization
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupActions()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    // MARK: - Setup
    
    private func setupUI() {
        backgroundColor = UIColor.black.withAlphaComponent(0.3)
        
        addSubview(containerView)
        containerView.addSubview(textField)
        containerView.addSubview(colorStackView)
        containerView.addSubview(fontSizeLabel)
        containerView.addSubview(fontSizeSlider)
        containerView.addSubview(fontPickerButton)
        containerView.addSubview(doneButton)
        
        // Constraints
        containerView.snp.makeConstraints { make in
            make.leading.trailing.equalToSuperview().inset(20)
            make.bottom.equalTo(safeAreaLayoutGuide).offset(-20)
        }
        
        textField.snp.makeConstraints { make in
            make.top.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        colorStackView.snp.makeConstraints { make in
            make.top.equalTo(textField.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        fontSizeLabel.snp.makeConstraints { make in
            make.top.equalTo(colorStackView.snp.bottom).offset(16)
            make.leading.equalToSuperview().inset(16)
        }
        
        fontSizeSlider.snp.makeConstraints { make in
            make.centerY.equalTo(fontSizeLabel)
            make.leading.equalTo(fontSizeLabel.snp.trailing).offset(16)
            make.trailing.equalToSuperview().inset(16)
        }
        
        fontPickerButton.snp.makeConstraints { make in
            make.top.equalTo(fontSizeSlider.snp.bottom).offset(16)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(40)
        }
        
        doneButton.snp.makeConstraints { make in
            make.top.equalTo(fontPickerButton.snp.bottom).offset(20)
            make.leading.trailing.equalToSuperview().inset(16)
            make.height.equalTo(44)
            make.bottom.equalToSuperview().inset(16)
        }
        
        // Setup color buttons
        setupColorButtons()
    }
    
    private func setupColorButtons() {
        colors.forEach { color in
            let button = UIButton()
            button.backgroundColor = color
            button.layer.cornerRadius = 20
            button.layer.borderWidth = 2
            button.layer.borderColor = UIColor.systemGray3.cgColor
            button.addTarget(self, action: #selector(colorButtonTapped(_:)), for: .touchUpInside)
            colorStackView.addArrangedSubview(button)
            
            button.snp.makeConstraints { make in
                make.size.equalTo(40)
            }
        }
    }
    
    private func setupActions() {
        textField.addTarget(self, action: #selector(textFieldChanged), for: .editingChanged)
        fontSizeSlider.addTarget(self, action: #selector(fontSizeChanged), for: .valueChanged)
        fontPickerButton.addTarget(self, action: #selector(fontPickerTapped), for: .touchUpInside)
        doneButton.addTarget(self, action: #selector(doneButtonTapped), for: .touchUpInside)
        
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(backgroundTapped))
        addGestureRecognizer(tapGesture)
        
        // Добавляем наблюдатели для клавиатуры
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillShow),
            name: UIResponder.keyboardWillShowNotification,
            object: nil
        )
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(keyboardWillHide),
            name: UIResponder.keyboardWillHideNotification,
            object: nil
        )
    }
    
    // MARK: - Actions
    
    @objc private func textFieldChanged() {
        delegate?.textEditingPanel(self, didUpdateText: textField.text ?? "")
    }
    
    @objc private func colorButtonTapped(_ sender: UIButton) {
        guard let color = sender.backgroundColor else { return }
        
        // Обновляем выделение
        colorStackView.arrangedSubviews.forEach { view in
            view.layer.borderColor = UIColor.systemGray3.cgColor
        }
        sender.layer.borderColor = UIColor.systemBlue.cgColor
        
        delegate?.textEditingPanel(self, didSelectColor: color)
    }
    
    @objc private func fontSizeChanged() {
        let size = Int(fontSizeSlider.value)
        fontSizeLabel.text = "Размер: \(size)"
        delegate?.textEditingPanel(self, didSelectFontSize: CGFloat(size))
    }
    
    @objc private func fontPickerTapped() {
        showFontPicker()
    }
    

    
    private func showFontPicker() {
        let alert = UIAlertController(title: "Выберите шрифт", message: nil, preferredStyle: .actionSheet)
        
        for (displayName, fontName) in availableFonts {
            let action = UIAlertAction(title: displayName, style: .default) { [weak self] _ in
                self?.selectedFontName = displayName
                self?.fontPickerButton.setTitle("Шрифт: \(displayName)", for: .normal)
                self?.delegate?.textEditingPanel(self!, didSelectFont: fontName)
            }
            alert.addAction(action)
        }
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        // Находим родительский view controller
        if let parentVC = findViewController() {
            if let popover = alert.popoverPresentationController {
                popover.sourceView = fontPickerButton
                popover.sourceRect = fontPickerButton.bounds
            }
            parentVC.present(alert, animated: true)
        }
    }
    
    @objc private func doneButtonTapped() {
        delegate?.textEditingPanelDidFinish(self)
    }
    
    @objc private func backgroundTapped() {
        endEditing(true)
    }
    
    @objc private func keyboardWillShow(notification: NSNotification) {
        guard let keyboardFrame = notification.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? NSValue else { return }
        let keyboardHeight = keyboardFrame.cgRectValue.height
        
        UIView.animate(withDuration: 0.3) {
            self.containerView.snp.updateConstraints { make in
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-keyboardHeight - 20)
            }
            self.layoutIfNeeded()
        }
    }
    
    @objc private func keyboardWillHide(notification: NSNotification) {
        UIView.animate(withDuration: 0.3) {
            self.containerView.snp.updateConstraints { make in
                make.bottom.equalTo(self.safeAreaLayoutGuide).offset(-20)
            }
            self.layoutIfNeeded()
        }
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    // MARK: - Public Methods
    
    func show(with text: String = "") {
        textField.text = text
        textField.becomeFirstResponder()
        
        alpha = 0
        UIView.animate(withDuration: 0.3) {
            self.alpha = 1
        }
    }
    
    func hide() {
        endEditing(true)
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }) { _ in
            self.removeFromSuperview()
        }
    }
}

extension UIView {
    func findViewController() -> UIViewController? {
        if let nextResponder = self.next as? UIViewController {
            return nextResponder
        } else if let nextResponder = self.next as? UIView {
            return nextResponder.findViewController()
        } else {
            return nil
        }
    }
} 