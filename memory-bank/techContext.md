# ТЕХНИЧЕСКИЙ КОНТЕКСТ: CollageMaker

## Технологический стек
- **Swift** - основной язык разработки
- **RxSwift/RxCocoa** - реактивное программирование
- **SnapKit** - Auto Layout DSL
- **Photos Framework** - работа с галереей
- **CocoaPods** - управление зависимостями

## Архитектура
**MVVM + Coordinator Pattern**
- `AppCoordinator` - главный координатор приложения
- `HomeTabBarCoordinator` - координатор главного экрана
- ViewModels для бизнес-логики
- Coordinators для навигации

## Ключевые компоненты
- **HomeViewController** - экран выбора фотографий и шаблонов
- **CollageEditorViewController** - редактор коллажей
- **CollageTemplatesManager** - управление шаблонами
- **PhotoLibraryAccessManager** - работа с галереей

## Системные требования
- iOS 16.6+
- Xcode 15.0+
- Swift 5.0+
