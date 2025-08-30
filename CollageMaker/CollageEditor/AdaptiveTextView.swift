//
//  AdaptiveTextView.swift
//  CollageMaker
//
//  Created by Assistant on 02.02.2025.
//

import UIKit
import CoreText

class AdaptiveTextView: ArchTextView {

    // MARK: - Properties

    /// Максимальная ширина текста в точках
    var maxWidth: CGFloat = 200 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Максимальная высота текста в точках
    var maxHeight: CGFloat = 200 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Минимальный размер шрифта
    var minimumFontSize: CGFloat = 12 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Максимальный размер шрифта
    var maximumFontSize: CGFloat = 72 {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Включить автоматическое уменьшение размера шрифта
    var adjustsFontSizeToFitWidth: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Включить перенос строк
    var enablesWordWrapping: Bool = true {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Выравнивание текста (переопределяем свойство базового класса)
    override var textAlignment: NSTextAlignment {
        get { return super.textAlignment }
        set {
            super.textAlignment = newValue
            setNeedsDisplay()
        }
    }

    /// Отступы от границ контейнера
    var textInsets: UIEdgeInsets = UIEdgeInsets(top: 8, left: 8, bottom: 8, right: 8) {
        didSet {
            setNeedsDisplay()
        }
    }

    /// Callback для уведомления о изменении размера
    var onSizeChanged: ((CGSize) -> Void)?

    private var currentAdaptedFontSize: CGFloat = 24
    private var currentAdaptedText: String = ""

    // MARK: - Initialization

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupDefaults()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupDefaults()
    }

    private func setupDefaults() {
        // Устанавливаем базовый размер шрифта
        currentAdaptedFontSize = font.pointSize
        currentAdaptedText = text
    }

    // MARK: - Adaptive Logic

    private func adaptTextToFit() {
        guard !text.isEmpty else { return }

        currentAdaptedText = text
        currentAdaptedFontSize = font.pointSize

        // Сначала пробуем с текущим размером шрифта
        let adaptedSize = calculateOptimalLayout(for: text, with: font)

        // Если текст не помещается и включено уменьшение размера
        if !isTextFitting(size: adaptedSize) && adjustsFontSizeToFitWidth {
            adaptFontSize()
        }

        // Если все еще не помещается, пробуем добавить переносы строк
        if enablesWordWrapping {
            adaptWithWordWrapping()
        }

        // Уведомляем о изменении размера
        let finalSize = calculateTextSize()
        onSizeChanged?(finalSize)
    }

    private func adaptFontSize() {
        let originalFontSize = font.pointSize
        var testFontSize = originalFontSize

        // Бинарный поиск оптимального размера шрифта
        var minSize = minimumFontSize
        var maxSize = min(originalFontSize, maximumFontSize)

        while maxSize - minSize > 1 {
            testFontSize = (minSize + maxSize) / 2
            let testFont = font.withSize(testFontSize)
            let testSize = calculateOptimalLayout(for: text, with: testFont)

            if isTextFitting(size: testSize) {
                minSize = testFontSize
            } else {
                maxSize = testFontSize
            }
        }

        currentAdaptedFontSize = minSize
        updateFont(font.withSize(currentAdaptedFontSize))
    }

    private func adaptWithWordWrapping() {
        // Разбиваем текст на слова
        let words = text.components(separatedBy: .whitespacesAndNewlines)
        guard words.count > 1 else { return }

        var lines: [String] = []
        var currentLine = ""
        let availableWidth = maxWidth - textInsets.left - textInsets.right

        for word in words {
            let testLine = currentLine.isEmpty ? word : currentLine + " " + word

            // Создаем attributed string для точного расчета
            let attributes: [NSAttributedString.Key: Any] = [
                .font: font.withSize(currentAdaptedFontSize),
                .foregroundColor: textColor
            ]
            let attributedString = NSAttributedString(string: testLine, attributes: attributes)

            // Рассчитываем размер без переноса строк (одна строка)
            let lineRect = attributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
                                                        options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                        context: nil)

            if lineRect.width <= availableWidth {
                currentLine = testLine
            } else {
                // Если текущая строка не пустая, сохраняем её
                if !currentLine.isEmpty {
                    lines.append(currentLine)
                }

                // Начинаем новую строку с текущим словом
                currentLine = word

                // Проверяем, помещается ли слово в новую строку
                let wordAttributedString = NSAttributedString(string: word, attributes: attributes)
                let wordRect = wordAttributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
                                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                context: nil)

                // Если слово не помещается даже в пустую строку, уменьшаем шрифт
                if wordRect.width > availableWidth {
                    if adjustsFontSizeToFitWidth && currentAdaptedFontSize > minimumFontSize {
                        currentAdaptedFontSize = max(minimumFontSize, currentAdaptedFontSize * 0.9)
                        updateFont(font.withSize(currentAdaptedFontSize))
                        // Повторяем процесс с новым размером шрифта
                        adaptWithWordWrapping()
                        return
                    }
                }
            }
        }

        // Добавляем последнюю строку
        if !currentLine.isEmpty {
            lines.append(currentLine)
        }

        currentAdaptedText = lines.joined(separator: "\n")
    }

    private func calculateOptimalLayout(for text: String, with font: UIFont) -> CGSize {
        let attributes: [NSAttributedString.Key: Any] = [
            .font: font,
            .foregroundColor: textColor
        ]

        let attributedString = NSAttributedString(string: text, attributes: attributes)

        // Если текст содержит переносы строк, рассчитываем размер для многострочного текста
        if text.contains("\n") {
            let lines = text.components(separatedBy: "\n")
            var totalHeight: CGFloat = 0
            var maxWidth: CGFloat = 0

            for line in lines {
                let lineAttributedString = NSAttributedString(string: line, attributes: attributes)
                let lineRect = lineAttributedString.boundingRect(with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: .greatestFiniteMagnitude),
                                                                options: [.usesLineFragmentOrigin, .usesFontLeading],
                                                                context: nil)
                totalHeight += lineRect.height
                maxWidth = max(maxWidth, lineRect.width)
            }

            return CGSize(width: ceil(maxWidth + textInsets.left + textInsets.right),
                         height: ceil(totalHeight + textInsets.top + textInsets.bottom))
        } else {
            // Для однострочного текста рассчитываем обычным способом
            let maxSize = CGSize(width: maxWidth - textInsets.left - textInsets.right,
                               height: maxHeight - textInsets.top - textInsets.bottom)

            let options: NSStringDrawingOptions = [.usesLineFragmentOrigin, .usesFontLeading]
            let boundingRect = attributedString.boundingRect(with: maxSize, options: options, context: nil)

            return CGSize(width: ceil(boundingRect.width + textInsets.left + textInsets.right),
                         height: ceil(boundingRect.height + textInsets.top + textInsets.bottom))
        }
    }

    private func calculateTextSize() -> CGSize {
        return calculateOptimalLayout(for: currentAdaptedText, with: font.withSize(currentAdaptedFontSize))
    }

    private func isTextFitting(size: CGSize) -> Bool {
        return size.width <= maxWidth && size.height <= maxHeight
    }

    // MARK: - Overrides

    override func updateText(_ newText: String) {
        super.updateText(newText)
        adaptTextToFit()
    }

    override func updateFont(_ newFont: UIFont) {
        super.updateFont(newFont)
        currentAdaptedFontSize = newFont.pointSize
        adaptTextToFit()
    }

    override func draw(_ rect: CGRect) {
        // Используем адаптированный текст вместо оригинального
        let originalText = text
        let originalFont = font

        text = currentAdaptedText
        font = originalFont.withSize(currentAdaptedFontSize)

        super.draw(rect)

        // Восстанавливаем оригинальные значения
        text = originalText
        font = originalFont
    }

    // MARK: - Public Methods

    /// Получить текущий адаптированный размер текста
    func getAdaptedSize() -> CGSize {
        return calculateTextSize()
    }

    /// Получить текущий адаптированный текст
    func getAdaptedText() -> String {
        return currentAdaptedText
    }

    /// Получить текущий размер шрифта после адаптации
    func getAdaptedFontSize() -> CGFloat {
        return currentAdaptedFontSize
    }

    /// Сбросить адаптацию и вернуться к исходным настройкам
    func resetAdaptation() {
        currentAdaptedText = text
        currentAdaptedFontSize = font.pointSize
        setNeedsDisplay()
        let size = calculateTextSize()
        onSizeChanged?(size)
    }

    /// Обновить ограничения для адаптации
    func updateConstraints(maxWidth: CGFloat? = nil, maxHeight: CGFloat? = nil) {
        if let maxWidth = maxWidth {
            self.maxWidth = maxWidth
        }
        if let maxHeight = maxHeight {
            self.maxHeight = maxHeight
        }
        adaptTextToFit()
    }
}
