# СИСТЕМНЫЕ ПАТТЕРНЫ: CollageMaker

## Архитектурные паттерны

### MVVM + Coordinator
- **Model** - данные и бизнес-логика (CollageTemplateModel)
- **View** - UI компоненты (ViewControllers)
- **ViewModel** - связующее звено между Model и View
- **Coordinator** - управление навигацией и жизненным циклом

### Основные координаторы
- `AppCoordinator` - главный координатор приложения
- `HomeTabBarCoordinator` - координатор главного экрана
- `HomeViewCoordinator` - координатор для домашнего экрана

### Паттерны в коде
- **Dependency Injection** через координаторы
- **Reactive Programming** с RxSwift
- **Delegate Pattern** для коммуникации между компонентами
- **Strategy Pattern** для различных фильтров и эффектов

## Структура данных
- **CollageTemplateModel** - модель шаблона коллажа
- **CollageTemplatesManager** - менеджер шаблонов
- **PhotoLibraryAccessManager** - управление доступом к галерее

## Принципы организации
- Разделение ответственности
- Слабая связанность
- Высокая когезия
- Тестируемость кода
