# РУКОВОДСТВО ПО ИНТЕГРАЦИИ СИСТЕМЫ ФИГУРНЫХ РАМОК

## ВАЖНО: Рамки теперь применяются к ИЗОБРАЖЕНИЯМ КОЛЛАЖА, а не к стикерам!

## ШАГИ ИНТЕГРАЦИИ:

### 1. Добавить новые файлы в проект Xcode:
- FrameableImageExtension.swift
- ImageFrameIntegration.swift  
- CollageEditorViewController_ImageFrames.swift

### 2. Обновить CollageEditorViewController.swift:

#### В начале файла добавить import:
```swift
import UIKit
// Добавить после существующих imports:
// Файлы будут автоматически подключены через экстеншены
```

#### В методе gestureHandler(_:didTapImageView:) заменить существующую логику:
```swift
func gestureHandler(_ handler: AdvancedImageGestureHandler, didTapImageView imageView: UIImageView) {
    // ЗАМЕНИТЬ СУЩЕСТВУЮЩИЙ КОД НА:
    
    // Снимаем выделение со всех других элементов
    gestureHandlers.forEach { gestureHandler in
        if gestureHandler !== handler {
            gestureHandler.setSelected(false)
        }
    }
    textLayers.forEach { $0.setSelected(false) }
    stickerViews.forEach { $0.setSelected(false) }
    currentTextLayer = nil
    currentStickerView = nil
    hideTextEditingPanel()

    selectedImageView = imageView

    // НОВОЕ: ПОКАЗЫВАЕМ ELEMENTCONTROLPANEL ДЛЯ ИЗОБРАЖЕНИЯ КОЛЛАЖА
    showElementControlPanelForImage(imageView, gestureHandler: handler)

    // Убеждаемся, что кнопки остаются доступными
    ensureButtonsOnTop()

    // Остальная логика остается без изменений...
    if imageView.image == UIImage(named: "placeholder") {
        // ... логика для placeholder
    } else {
        // ... логика для PhotoEditor
        handler.updateDeleteButtonVisibility()
    }
}
```

#### В методе collageViewTapped добавить скрытие ElementControlPanel:
```swift
@objc private func collageViewTapped(_ gesture: UITapGestureRecognizer) {
    // ... существующий код ...
    
    // Если не попали ни в текст, ни в стикер, ни в изображение
    if !hitTextLayer && !hitSticker && !hitImage {
        deselectAllTextLayers()
        deselectAllStickers()
        gestureHandlers.forEach { $0.setSelected(false) }
        selectedImageView = nil
        
        // ДОБАВИТЬ ЭТИ СТРОКИ:
        hideElementControlPanelForImage()
        hideFramePicker()
    }
}
```

#### Обновить ElementControlPanelDelegate методы:
```swift
func controlPanel(_ panel: ElementControlPanel, didRequestFramePicker: Void) {
    // ЗАМЕНИТЬ СУЩЕСТВУЮЩИЙ КОД НА:
    if currentImageGestureHandler != nil {
        showFramePickerForImage()
    }
    // Убрать логику для стикеров
}

func controlPanel(_ panel: ElementControlPanel, didSelectFrameShape frameShape: FrameShape) {
    // ЗАМЕНИТЬ СУЩЕСТВУЮЩИЙ КОД НА:
    if currentImageGestureHandler != nil {
        applyFrameShapeToImage(frameShape)
    }
    // Убрать логику для стикеров
}
```

#### Обновить FramePickerViewDelegate методы:
```swift
func framePickerView(_ pickerView: FramePickerView, didSelectFrameShape frameShape: FrameShape) {
    // ЗАМЕНИТЬ СУЩЕСТВУЮЩИЙ КОД НА:
    if currentImageGestureHandler != nil {
        applyFrameShapeToImage(frameShape)
    }
    // Убрать логику для стикеров
}
```

### 3. Убрать из CollageEditorViewController.swift старую логику стикеров:
- Убрать методы showElementControlPanel(for stickerView:)
- Убрать логику frameShape из selectStickerView()
- Убрать интеграцию ElementControlPanel со стикерами

## КАК БУДЕТ РАБОТАТЬ:

### ДЛЯ ПОЛЬЗОВАТЕЛЯ:
1. **Выбрать изображение в коллаже** (тапнуть по любой ячейке с изображением)
2. **Снизу появится ElementControlPanel** с 4 кнопками:
   - 🔄 Поворот (синяя)  
   - 🔍 Масштаб (зеленая)
   - ↺ Сброс (красная)
   - **❤️ РАМКИ (фиолетовая)** ← НОВАЯ ФУНКЦИЯ
3. **Тапнуть по фиолетовой кнопке** → появится горизонтальная прокрутка
4. **Выбрать любую форму** → рамка применится к изображению коллажа!

### ДОСТУПНЫЕ ФОРМЫ:
✅ Без рамки, ⭕ Круг, ❤️ Сердце, ⭐ Звезда, ♦️ Ромб, ▲ Треугольник, ⬜ Квадрат, 🌸 Цветок, ⬡ Шестиугольник

## ОСОБЕННОСТИ:
- ✅ Рамки применяются к **изображениям коллажа**, НЕ к стикерам
- ✅ Полная совместимость с жестами (move, scale, rotate)
- ✅ Кэширование для производительности
- ✅ Haptic feedback для UX
- ✅ Автообновление масок при трансформациях

## ПРОВЕРКА:
После интеграции:
1. Откройте редактор коллажа
2. Добавьте изображение в любую ячейку коллажа
3. Тапните по изображению
4. Снизу должна появиться панель с фиолетовой кнопкой рамок
5. Тапните по фиолетовой кнопке → появится селектор форм
6. Выберите сердечко → изображение получит форму сердца!
