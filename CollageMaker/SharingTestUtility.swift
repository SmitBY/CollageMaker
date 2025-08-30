import UIKit

/// Утилита для тестирования и устранения проблем с sharing
class SharingTestUtility {
    
    /// Показывает диалог выбора метода sharing
    static func showSharingOptions(
        for image: UIImage,
        templateName: String?,
        sourceView: UIView,
        from viewController: UIViewController
    ) {
        let alert = UIAlertController(
            title: "Выберите способ поделиться",
            message: "Если возникают проблемы с расширениями (например, Telegram), используйте безопасный режим",
            preferredStyle: .actionSheet
        )
        
        // Основной метод sharing
        alert.addAction(UIAlertAction(title: "Обычный способ", style: .default) { _ in
            SharingManager.shared.shareCollage(
                image,
                templateName: templateName,
                sourceView: sourceView,
                sourceRect: sourceView.bounds,
                from: viewController
            )
        })
        
        // Упрощенный метод sharing
        alert.addAction(UIAlertAction(title: "Упрощенный способ", style: .default) { _ in
            SharingManager.shared.simpleShareImage(
                image,
                sourceView: sourceView,
                sourceRect: sourceView.bounds,
                from: viewController
            )
        })
        
        // Безопасный режим (только системные опции)
        alert.addAction(UIAlertAction(title: "Безопасный режим", style: .default) { _ in
            SharingManager.shared.safeModeShareImage(
                image,
                sourceView: sourceView,
                sourceRect: sourceView.bounds,
                from: viewController
            )
        })
        
        // Сохранить в фотоальбом как альтернатива
        alert.addAction(UIAlertAction(title: "Сохранить в фотоальбом", style: .default) { _ in
            UIImageWriteToSavedPhotosAlbum(image, nil, nil, nil)
            
            let successAlert = UIAlertController(
                title: "Сохранено!",
                message: "Коллаж сохранен в фотоальбом. Теперь вы можете поделиться им из приложения Фото.",
                preferredStyle: .alert
            )
            successAlert.addAction(UIAlertAction(title: "OK", style: .default))
            viewController.present(successAlert, animated: true)
        })
        
        // Тестовая кнопка для проверки диалога успеха Telegram
        alert.addAction(UIAlertAction(title: "🧪 Тест: Диалог успеха Telegram", style: .default) { _ in
            SharingManager.shared.testShowTelegramSuccessDialog(from: viewController)
        })
        
        // Тестовая кнопка для проверки диалога зависания
        alert.addAction(UIAlertAction(title: "⏰ Тест: Диалог зависания Telegram", style: .default) { _ in
            SharingManager.shared.testShowTelegramHangDialog(from: viewController)
        })
        
        // Тестовая кнопка для диагностики системы
        alert.addAction(UIAlertAction(title: "🔍 Тест: Диагностика системы", style: .default) { _ in
            SharingTestUtility.testSystemDiagnostics()
        })
        
        // Тестовая кнопка для расширенных инструкций
        alert.addAction(UIAlertAction(title: "🚨 Тест: Расширенные инструкции", style: .default) { _ in
            SharingTestUtility.testAdvancedHangInstructions(from: viewController)
        })
        
        // Комплексный тест всех новых функций
        alert.addAction(UIAlertAction(title: "🧪 Комплексный тест диагностики", style: .default) { _ in
            SharingTestUtility.runComprehensiveTest(from: viewController)
        })
        
        // Новая панель расширенных тестов
        alert.addAction(UIAlertAction(title: "🛠️ Расширенные тесты (новые)", style: .default) { _ in
            SharingTestUtility.showAdvancedTestPanel(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "Отмена", style: .cancel))
        
        // Настройка для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = sourceView
            popover.sourceRect = sourceView.bounds
        }
        
        viewController.present(alert, animated: true)
    }
    
    /// Проверяет доступность sharing сервисов
    static func checkSharingAvailability() {
        print("🔍 SharingTestUtility: Проверка доступности sharing сервисов...")
        
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        let _ = UIActivityViewController(activityItems: [testImage], applicationActivities: nil)
        
        print("✅ SharingTestUtility: UIActivityViewController создан успешно")
        print("   Доступные типы активности будут определены при показе")
    }
    
    // MARK: - 🔍 ТЕСТИРОВАНИЕ РАСШИРЕННОЙ ДИАГНОСТИКИ
    
    /// Тест диагностики системы
    static func testSystemDiagnostics() {
        print("🧪 === ТЕСТИРОВАНИЕ ДИАГНОСТИКИ СИСТЕМЫ ===")
        SharingManager.diagnoseSystemState()
    }
    
    /// Тест принудительной очистки состояния
    static func testForceCleanup() {
        print("🧪 === ТЕСТИРОВАНИЕ ПРИНУДИТЕЛЬНОЙ ОЧИСТКИ ===")
        SharingManager.forceCleanupSharing()
    }
    
    /// Тест показа детального лога ошибок
    static func testErrorLog() {
        print("🧪 === ТЕСТИРОВАНИЕ ДЕТАЛЬНОГО ЛОГА ОШИБОК ===")
        SharingManager.showDetailedErrorLog()
    }
    
    /// Тест alert о текущем шаринге
    static func testCurrentSharingAlert(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ ALERT О ТЕКУЩЕМ ШАРИНГЕ ===")
        SharingManager.showCurrentSharingAlert(from: viewController)
    }
    
    /// Тест расширенных инструкций при зависании
    static func testAdvancedHangInstructions(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ РАСШИРЕННЫХ ИНСТРУКЦИЙ ПРИ ЗАВИСАНИИ ===")
        SharingManager.showAdvancedHangInstructions()
    }
    
    /// Тест детектирования известных проблем
    static func testKnownIssuesDetection() {
        print("🧪 === ТЕСТИРОВАНИЕ ДЕТЕКТИРОВАНИЯ ИЗВЕСТНЫХ ПРОБЛЕМ ===")
        
        // Создаем тестовую ошибку 4099
        let testError = NSError(domain: "NSCocoaErrorDomain", code: 4099, userInfo: [
            NSLocalizedDescriptionKey: "The connection to service named com.apple.mobile.usermanagerd.xpc was invalidated"
        ])
        
        SharingManager.detectKnownIssues(error: testError, activityType: nil)
        
        // Создаем тестовую ошибку для Telegram
        let telegramActivityType = UIActivity.ActivityType("ph.telegra.Telegraph.Share")
        SharingManager.detectKnownIssues(error: testError, activityType: telegramActivityType)
    }
    
    /// Комплексный тест всех новых функций
    static func runComprehensiveTest(from viewController: UIViewController) {
        print("🧪 === КОМПЛЕКСНЫЙ ТЕСТ РАСШИРЕННОЙ ДИАГНОСТИКИ ===")
        
        // 1. Тест диагностики системы
        testSystemDiagnostics()
        
        // 2. Тест детектирования известных проблем
        testKnownIssuesDetection()
        
        // 3. Тест лога ошибок
        testErrorLog()
        
        // 4. Тест alert через 2 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
            testCurrentSharingAlert(from: viewController)
        }
        
        // 5. Тест расширенных инструкций через 4 секунды
        DispatchQueue.main.asyncAfter(deadline: .now() + 4.0) {
            testAdvancedHangInstructions(from: viewController)
        }
        
        print("🧪 Комплексный тест запущен. Проверьте логи и UI через несколько секунд.")
    }
    
    // MARK: - 🧪 НОВЫЕ ТЕСТЫ ДЛЯ ИСПРАВЛЕНИЯ КОНФЛИКТОВ
    
    /// Тест конфликта Alert'ов - показывает Alert поверх Activity ViewController
    static func testAlertConflict(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ КОНФЛИКТА ALERT'ОВ ===")
        
        // Создаем и показываем Activity ViewController
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        let activityVC = UIActivityViewController(activityItems: [testImage], applicationActivities: nil)
        
        viewController.present(activityVC, animated: true) {
            // Через секунду пытаемся показать alert поверх Activity VC
            DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                print("🧪 Пытаемся показать alert поверх Activity ViewController...")
                SharingManager.showAdvancedHangInstructions()
            }
        }
    }
    
    /// Тест повторного шаринга при активном шаринге
    static func testDoubleSharing(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ ПОВТОРНОГО ШАРИНГА ===")
        
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        
        // Первый шаринг
        SharingManager.shared.shareImage(
            testImage,
            withText: "Тест #1",
            sourceView: viewController.view,
            sourceRect: CGRect(x: 0, y: 0, width: 50, height: 50),
            from: viewController
        )
        
        // Второй шаринг через секунду
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            print("🧪 Запускаем второй шаринг...")
            SharingManager.shared.shareImage(
                testImage,
                withText: "Тест #2",
                sourceView: viewController.view,
                sourceRect: CGRect(x: 100, y: 100, width: 50, height: 50),
                from: viewController
            )
        }
    }
    
    /// Тест автоматической очистки зависшего состояния
    static func testAutoCleanup(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ АВТОМАТИЧЕСКОЙ ОЧИСТКИ ===")
        
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        
        // Запускаем шаринг
        SharingManager.shared.shareImage(
            testImage,
            withText: "Тест автоочистки",
            sourceView: viewController.view,
            sourceRect: CGRect(x: 0, y: 0, width: 50, height: 50),
            from: viewController
        )
        
        // Через 5 секунд пытаемся запустить новый шаринг (должен сработать автоматический cleanup)
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            print("🧪 Пытаемся запустить новый шаринг (тест автоочистки)...")
            SharingManager.shared.shareImage(
                testImage,
                withText: "Тест после автоочистки",
                sourceView: viewController.view,
                sourceRect: CGRect(x: 100, y: 100, width: 50, height: 50),
                from: viewController
            )
        }
    }
    
    /// Тест восстановления после зависания
    static func testHangRecovery(from viewController: UIViewController) {
        print("🧪 === ТЕСТИРОВАНИЕ ВОССТАНОВЛЕНИЯ ПОСЛЕ ЗАВИСАНИЯ ===")
        
        // Симулируем зависшее состояние
        print("🔧 Симулируем зависшее состояние...")
        
        // Создаем "зависший" Activity ViewController
        let testImage = UIImage(systemName: "photo") ?? UIImage()
        let hangingActivityVC = UIActivityViewController(activityItems: [testImage], applicationActivities: nil)
        
        viewController.present(hangingActivityVC, animated: true) {
            // Через 2 секунды запускаем принудительную очистку
            DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
                print("🧪 Запускаем принудительную очистку...")
                SharingManager.forceCleanupSharing()
                
                // Через секунду после очистки пытаемся запустить новый шаринг
                DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
                    print("🧪 Пытаемся запустить новый шаринг после восстановления...")
                    SharingManager.shared.shareImage(
                        testImage,
                        withText: "Тест после восстановления",
                        sourceView: viewController.view,
                        sourceRect: CGRect(x: 200, y: 200, width: 50, height: 50),
                        from: viewController
                    )
                }
            }
        }
    }
    
    /// Показывает панель с новыми тестами
    static func showAdvancedTestPanel(from viewController: UIViewController) {
        let alert = UIAlertController(
            title: "🧪 Расширенные тесты шаринга",
            message: "Тесты для проверки исправлений конфликтов Alert'ов и автоматической очистки",
            preferredStyle: .actionSheet
        )
        
        alert.addAction(UIAlertAction(title: "🧪 Тест конфликта Alert'ов", style: .default) { _ in
            testAlertConflict(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "🔄 Тест повторного шаринга", style: .default) { _ in
            testDoubleSharing(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "🧹 Тест автоматической очистки", style: .default) { _ in
            testAutoCleanup(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "🔧 Тест восстановления после зависания", style: .default) { _ in
            testHangRecovery(from: viewController)
        })
        
        alert.addAction(UIAlertAction(title: "📊 Показать статистику ошибок", style: .default) { _ in
            SharingManager.showDetailedErrorLog()
        })
        
        alert.addAction(UIAlertAction(title: "🔧 Принудительная очистка", style: .destructive) { _ in
            SharingManager.forceCleanupSharing()
        })
        
        alert.addAction(UIAlertAction(title: "❌ Отмена", style: .cancel))
        
        // Настройка для iPad
        if let popover = alert.popoverPresentationController {
            popover.sourceView = viewController.view
            popover.sourceRect = CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0)
        }
        
        viewController.present(alert, animated: true)
    }
} 