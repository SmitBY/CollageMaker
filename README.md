# CollageMaker

iOS приложение для создания коллажей из фотографий с интуитивным интерфейсом и мощными возможностями редактирования.

## Особенности

- 📱 Современный интерфейс с архитектурой MVVM + Coordinator
- 🖼️ Выбор фотографий из галереи устройства
- 🎨 Динамические шаблоны коллажей, подстраивающиеся под количество выбранных фото
- ✨ Интерактивное редактирование: перемещение, масштабирование, поворот фотографий
- 💾 Сохранение готовых коллажей в высоком качестве (2400x2400)
- 🎯 Простой workflow: выбор фото → выбор шаблона → редактирование → сохранение

## Технологии

- **Swift** - основной язык разработки
- **RxSwift/RxCocoa** - реактивное программирование
- **SnapKit** - Auto Layout DSL
- **Photos Framework** - работа с галереей
- **CocoaPods** - управление зависимостями

## Архитектура

Проект использует паттерн **MVVM + Coordinator**:

- `AppCoordinator` - главный координатор приложения
- `HomeTabBarCoordinator` - координатор главного экрана
- `HomeViewController` - экран выбора фотографий и шаблонов
- `CollageEditorViewController` - редактор коллажей
- `CollageTemplatesManager` - управление шаблонами

## Установка

1. Клонируйте репозиторий:
```bash
git clone https://github.com/SmitBY/CollageMaker.git
cd CollageMaker
```

2. Установите зависимости:
```bash
pod install
```

3. Откройте проект:
```bash
open CollageMaker.xcworkspace
```

4. Запустите проект в Xcode

## Использование

1. **Выбор фотографий**: На главном экране выберите фотографии из галереи
2. **Выбор шаблона**: Шаблоны автоматически подстраиваются под количество выбранных фото
3. **Редактирование**: В редакторе можете перемещать, масштабировать и поворачивать фотографии
4. **Сохранение**: Нажмите "Сохранить" для экспорта коллажа в галерею

## Системные требования

- iOS 16.6+
- Xcode 15.0+
- Swift 5.0+

## Структура проекта

```
CollageMaker/
├── AppDelegate.swift
├── SceneDelegate.swift
├── AppCoordinator.swift
├── Home/
│   ├── HomeViewController.swift
│   ├── HomeViewModel.swift
│   ├── HomeTabBarController.swift
│   └── HomeTabBarCoordinator.swift
├── CollageEditor/
│   ├── CollageEditorViewController.swift
│   └── CollageEditorViewModel.swift
├── Models/
│   ├── CollageTemplateModel.swift
│   └── CollageTemplatesManager.swift
└── Utils/
    └── PhotoLibraryAccessManager.swift
```

## Лицензия

Этот проект создан в образовательных целях. 