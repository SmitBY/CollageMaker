import UIKit
import Darwin.Mach

    /// Менеджер для управления функциональностью sharing в приложении
    class SharingManager {
        
        // MARK: - 🔍 РАСШИРЕННАЯ ДИАГНОСТИКА
        static private var sharingAttempts: Int = 0
        static private var currentActivityViewController: UIActivityViewController?
        static private var currentPresentingViewController: UIViewController?
        static private var sharingTimer: Timer?
        static private var isCurrentlySharing: Bool = false
        
        // MARK: - 📊 СТАТИСТИКА ОШИБОК
        static private var errorStats: [String: Int] = [:]
        static private var shareSuccessCount: Int = 0
        static private var shareFailureCount: Int = 0
        
        // MARK: - 🚨 ДЕТЕКТИРОВАНИЕ СИСТЕМНЫХ ПРОБЛЕМ
        static private var systemIssuesDetected: [String] = []
        static let shared = SharingManager()
        
        private init() {}
        
        /// Делится изображением с дополнительным текстом
        /// - Parameters:
        ///   - image: Изображение для sharing
        ///   - text: Дополнительный текст для sharing (опционально)
        ///   - sourceView: View для позиционирования popover на iPad
        ///   - sourceRect: Rect для позиционирования popover на iPad
        ///   - presentingViewController: View controller для презентации
        func shareImage(
            _ image: UIImage,
            withText text: String? = nil,
            sourceView: UIView,
            sourceRect: CGRect,
            from presentingViewController: UIViewController,
            completion: (() -> Void)? = nil
        ) {
            print("🔗 SharingManager: Начинаем sharing изображения")
            
            // 🔍 РАСШИРЕННАЯ ДИАГНОСТИКА СИСТЕМЫ
            Self.diagnoseSystemState()
            
            // 🚨 ПРОВЕРКА НА ПОВТОРНЫЕ ПОПЫТКИ
            if Self.isCurrentlySharing {
                print("⚠️ ВНИМАНИЕ: Шаринг уже в процессе! Отменяем повторную попытку")
                Self.showCurrentSharingAlert(from: presentingViewController)
                return
            }
            
            // 🔍 ПРОВЕРКА СОСТОЯНИЯ PRESENTING VIEW CONTROLLER
            if presentingViewController.presentedViewController != nil {
                print("⚠️ ВНИМАНИЕ: Presenting VC уже что-то показывает!")
                print("🔍 Представлено: \(presentingViewController.presentedViewController?.description ?? "unknown")")
                
                // Если это старый Activity VC - принудительно закрываем
                if let presented = presentingViewController.presentedViewController as? UIActivityViewController {
                    print("🔧 Обнаружен старый Activity VC - принудительно закрываем")
                    presented.dismiss(animated: false) {
                        // Повторно запускаем sharing после закрытия
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                            SharingManager.shared.shareImage(
                                image,
                                withText: text,
                                sourceView: sourceView,
                                sourceRect: sourceRect,
                                from: presentingViewController,
                                completion: completion
                            )
                        }
                    }
                    return
                }
                
                // Для других типов - показываем ошибку
                showSharingError(from: presentingViewController, message: "Не удается открыть шаринг - другое окно уже открыто")
                return
            }
            
            // Подготовим временный JPEG-файл (даунскейл + сжатие), передаем URL
            func downscale(_ img: UIImage, maxDimension: CGFloat) -> UIImage {
                let size = img.size
                let maxSide = max(size.width, size.height)
                guard maxSide > maxDimension else { return img }
                let scale = maxDimension / maxSide
                let newSize = CGSize(width: size.width * scale, height: size.height * scale)
                UIGraphicsBeginImageContextWithOptions(newSize, false, 1.0)
                img.draw(in: CGRect(origin: .zero, size: newSize))
                let resized = UIGraphicsGetImageFromCurrentImageContext()
                UIGraphicsEndImageContext()
                return resized ?? img
            }

            let resized = downscale(image, maxDimension: 2048)
            let jpegQuality: CGFloat = 0.85
            guard let jpegData = resized.jpegData(compressionQuality: jpegQuality) else {
                print("❌ SharingManager: Не удалось создать JPEG данные")
                showSharingError(from: presentingViewController, message: "Не удалось подготовить изображение для sharing")
                Self.shareFailureCount += 1
                return
            }

            let tempDir = URL(fileURLWithPath: NSTemporaryDirectory(), isDirectory: true)
            let fileURL = tempDir.appendingPathComponent("collage_\(UUID().uuidString).jpg")
            do {
                try jpegData.write(to: fileURL, options: .atomic)
                print("✅ SharingManager: Подготовлен временный файл: \(fileURL)")
            } catch {
                print("❌ SharingManager: Ошибка записи временного файла: \(error)")
                showSharingError(from: presentingViewController, message: "Не удалось сохранить временный файл для sharing")
                Self.shareFailureCount += 1
                return
            }

            // Создаем массив элементов для sharing (URL + текст)
            var activityItems: [Any] = [fileURL]
            
            // Добавляем текст если он предоставлен
            if let text = text, !text.isEmpty {
                activityItems.append(text)
                print("✅ SharingManager: Добавлен текст: \(text)")
            }
            
            // Создаем Activity View Controller
            let activityVC = UIActivityViewController(
                activityItems: activityItems,
                applicationActivities: nil
            )
            
            // 💾 СОХРАНЕНИЕ ССЫЛОК ДЛЯ ДИАГНОСТИКИ
            Self.currentActivityViewController = activityVC
            Self.currentPresentingViewController = presentingViewController
            
            // Исключаем проблемные типы активности для стабильности
            var excludedTypes: [UIActivity.ActivityType] = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .markupAsPDF,
                .print,
                .copyToPasteboard  // Может вызывать проблемы с большими изображениями
            ]
            
            // Добавляем новые типы активности для iOS 13+ которые могут быть нестабильными
            if #available(iOS 13.0, *) {
                excludedTypes.append(.collaborationInviteWithLink)
                excludedTypes.append(.collaborationCopyLink)
            }
            
            if #available(iOS 15.0, *) {
                excludedTypes.append(.sharePlay)
            }
            
            activityVC.excludedActivityTypes = excludedTypes
            
            // Настройка для iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect
                    popover.permittedArrowDirections = [.up, .down]
                    print("✅ SharingManager: Настроен popover для iPad")
                }
            }
            
            // Сохраняем ссылку на изображение для fallback options
            let originalImage = image
            
            // Callback при завершении с улучшенной обработкой ошибок
            activityVC.completionWithItemsHandler = { [weak self] activityType, completed, returnedItems, error in
                print("🔗 SharingManager: Завершение sharing")
                print("   - activityType: \(activityType?.rawValue ?? "nil")")
                print("   - completed: \(completed)")
                print("   - error: \(error?.localizedDescription ?? "nil")")
                
                // 🔓 РАЗБЛОКИРОВКА И ОЧИСТКА ТАЙМЕРА
                Self.isCurrentlySharing = false
                Self.sharingTimer?.invalidate()
                Self.sharingTimer = nil
                Self.currentActivityViewController = nil
                Self.currentPresentingViewController = nil
                
                // 🔍 ДЕТЕКТИРОВАНИЕ ИЗВЕСТНЫХ ПРОБЛЕМ
                if let error = error {
                    Self.detectKnownIssues(error: error, activityType: activityType)
                } else if completed {
                    Self.shareSuccessCount += 1
                }
                
                // Проверяем, если это Telegram
                if let activityType = activityType, activityType.rawValue.contains("telegra") {
                    print("📱 SharingManager: Обнаружен Telegram sharing")
                    if completed {
                        print("✅ SharingManager: Telegram успешно получил данные")
                    } else if error != nil {
                        print("❌ SharingManager: Telegram сообщил об ошибке")
                    } else {
                        print("❌ SharingManager: Telegram sharing был отменен")
                    }
                }
                
                if let error = error {
                    let errorMessage = error.localizedDescription
                    let errorCode = (error as NSError).code
                    print("❌ SharingManager: Ошибка при sharing: \(errorMessage) (код: \(errorCode))")
                    
                    // Проверяем различные типы ошибок расширений
                    let isExtensionError = errorMessage.contains("plugin") ||
                                         errorMessage.contains("extension") ||
                                         errorMessage.contains("interrupted") ||
                                         errorMessage.contains("invalidated") ||
                                         errorMessage.contains("Connection") ||
                                         errorCode == -1 || // Generic connection error
                                         errorCode == 4097 || // Connection interrupted
                                         errorCode == 4099 // Connection invalidated
                    
                    if isExtensionError {
                        print("🔧 SharingManager: Проблема с расширением обнаружена")
                        print("🔧 SharingManager: Расширение могло прерваться, но содержимое могло быть отправлено")
                        
                        // Предлагаем попробовать альтернативный способ
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            self?.showExtensionErrorAlert(from: presentingViewController, originalImage: originalImage, completion: completion)
                        }
                        return
                    }
                    
                    DispatchQueue.main.async {
                        self?.showSharingError(from: presentingViewController, message: "Ошибка при отправке: \(errorMessage)")
                    }
                } else if completed {
                    print("✅ SharingManager: Sharing успешно завершен")
                    // Ничего дополнительно не показываем, сразу выходим
                } else {
                    print("ℹ️ SharingManager: Sharing отменен пользователем")
                }
                
                // Чистим временный файл
                try? FileManager.default.removeItem(at: fileURL)
                completion?()
            }
            
            print("🔗 SharingManager: Показываем ActivityViewController")
            
            // Отключаем детекцию зависаний/таймеры и напрямую отмечаем состояние
            Self.isCurrentlySharing = true
            Self.currentPresentingViewController = presentingViewController
            
            // Добавляем небольшую задержку для стабильности
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
                presentingViewController.present(activityVC, animated: true) {
                    print("✅ SharingManager: ActivityViewController показан")
                    
                    // Ничего не показываем сверху, никаких подсказок/оверлеев
                }
            }
        }
        
        /// Показывает ошибку sharing
        private func showSharingError(from viewController: UIViewController, message: String) {
            let alert = UIAlertController(
                title: "Ошибка при sharing",
                message: message,
                preferredStyle: .alert
            )
            
            alert.addAction(UIAlertAction(title: "OK", style: .default))
            
            viewController.present(alert, animated: true)
        }
        
        /// Отключено: не показывать алерты успеха Telegram
        private func showTelegramSuccessAlert(from viewController: UIViewController) { }
        
        /// Отключено: не показывать инструкции зависания Telegram
        private func showTelegramHangInstructions(from viewController: UIViewController) { }
        
        /// Находит доступный view controller для презентации alert
        private func findAvailableViewControllerAndPresent(alert: UIAlertController, fallbackVC: UIViewController) {
            print("🔍 SharingManager: Finding available view controller for alert presentation")
            
            // Пытаемся найти root view controller
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
               let window = windowScene.windows.first,
               let rootVC = window.rootViewController {
                
                // Находим самый верхний доступный view controller
                var topVC = rootVC
                
                // Идем по цепочке presented view controllers
                while let presented = topVC.presentedViewController {
                    // Если это UIActivityViewController с SLComposeViewController - не можем показать alert
                    if presented is UIActivityViewController {
                        print("🔍 SharingManager: Found UIActivityViewController, cannot present alert on top")
                        break
                    }
                    topVC = presented
                }
                
                // Если сверху уже есть presentedViewController (например, UIActivityViewController), не пытаемся презентовать поверх
                if topVC.presentedViewController == nil && !(topVC is UIActivityViewController) {
                    print("✅ SharingManager: Presenting alert via \(topVC)")
                    topVC.present(alert, animated: true) {
                        print("✅ SharingManager: Telegram hang instructions presented successfully")
                    }
                    return
                }
            }
            
            // Fallback: создаем overlay прямо в window
            print("⚠️ SharingManager: Creating window overlay for alert")
            self.createWindowOverlayAlert(alert: alert)
        }
        
        /// Создает overlay alert прямо в window для случаев когда нельзя использовать present
        private func createWindowOverlayAlert(alert: UIAlertController) {
            print("📱 SharingManager: Creating window overlay alert")
            
            // Создаем новый window для alert
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                let overlayWindow = UIWindow(windowScene: windowScene)
                overlayWindow.windowLevel = UIWindow.Level.alert + 1
                overlayWindow.backgroundColor = UIColor.clear
                
                // Создаем прозрачный root view controller
                let overlayVC = UIViewController()
                overlayWindow.rootViewController = overlayVC
                overlayWindow.makeKeyAndVisible()
                
                // Показываем alert через overlay view controller
                overlayVC.present(alert, animated: true) {
                    print("✅ SharingManager: Window overlay alert presented successfully")
                }
                
                // Автоматически закрываем overlay window через разумное время
                DispatchQueue.main.asyncAfter(deadline: .now() + 30.0) {
                    overlayWindow.isHidden = true
                    print("✅ SharingManager: Window overlay alert auto-dismissed")
                }
            } else {
                print("❌ SharingManager: Cannot create window overlay - no window scene")
            }
        }
        
        /// Ждет полного закрытия модального окна и показывает диалог успеха
        private func waitForDismissalAndShowSuccess(from viewController: UIViewController) {
            print("🎉 SharingManager: waitForDismissalAndShowSuccess called")
            
            func checkAndShow() {
                print("🎉 SharingManager: Checking if we can show success dialog...")
                print("🎉 SharingManager: presentedViewController = \(String(describing: viewController.presentedViewController))")
                
                if viewController.presentedViewController == nil {
                    print("🎉 SharingManager: No modal present, showing success dialog")
                    self.showTelegramSuccessAlert(from: viewController)
                } else {
                    print("🎉 SharingManager: Modal still present, waiting 0.5s more...")
                    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                        checkAndShow()
                    }
                }
            }
            
            // Начальная задержка чтобы дать время UIActivityViewController закрыться
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                checkAndShow()
            }
        }
        
        /// Показывает алерт с информацией о проблеме с расширением и предлагает альтернативы
        private func showExtensionErrorAlert(
            from viewController: UIViewController, 
            originalImage: UIImage,
            completion: (() -> Void)? = nil
        ) {
            let alert = UIAlertController(
                title: "Проблема с расширением",
                message: "Расширение (например, Telegram) прервалось во время отправки. Это известная проблема iOS 18 с некоторыми приложениями.\n\n📱 Изображение могло быть передано успешно!\n\nПроверьте Telegram или попробуйте альтернативные способы:",
                preferredStyle: .alert
            )
            
            // Проверить Telegram
            alert.addAction(UIAlertAction(title: "📱 Проверить Telegram", style: .default) { _ in
                print("🔧 SharingManager: Пользователь выбрал проверку Telegram")
                if let telegramURL = URL(string: "tg://"),
                   UIApplication.shared.canOpenURL(telegramURL) {
                    UIApplication.shared.open(telegramURL)
                }
            })
            
            // Сохранить в Фото
            alert.addAction(UIAlertAction(title: "💾 Сохранить в Фото", style: .default) { _ in
                print("🔧 SharingManager: Пользователь выбрал сохранение в фотоальбом")
                UIImageWriteToSavedPhotosAlbum(originalImage, nil, nil, nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                    let successAlert = UIAlertController(
                        title: "✅ Сохранено",
                        message: "Коллаж сохранен в фотоальбом. Теперь вы можете поделиться им из галереи.",
                        preferredStyle: .alert
                    )
                    successAlert.addAction(UIAlertAction(title: "OK", style: .default))
                    viewController.present(successAlert, animated: true)
                }
                
                completion?()
            })
            
            // Попробовать снова с ограниченными опциями
            alert.addAction(UIAlertAction(title: "🔒 Безопасный режим", style: .default) { [weak self] _ in
                print("🔧 SharingManager: Пользователь выбрал безопасный режим sharing")
                guard let self = self else { return }
                
                self.safeModeShareImage(
                    originalImage,
                    sourceView: viewController.view,
                    sourceRect: CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0),
                    from: viewController,
                    completion: completion
                )
            })
            
            // Попробовать еще раз
            alert.addAction(UIAlertAction(title: "🔄 Попробовать снова", style: .default) { [weak self] _ in
                print("🔧 SharingManager: Пользователь выбрал повторную попытку")
                guard let self = self else { return }
                
                // Добавляем небольшую задержку перед повторной попыткой
                DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
                    self.simpleShareImage(
                        originalImage,
                        sourceView: viewController.view,
                        sourceRect: CGRect(x: viewController.view.bounds.midX, y: viewController.view.bounds.midY, width: 0, height: 0),
                        from: viewController,
                        completion: completion
                    )
                }
            })
            
            // Отмена
            alert.addAction(UIAlertAction(title: "Отмена", style: .cancel) { _ in
                print("ℹ️ SharingManager: Пользователь отменил sharing после ошибки расширения")
                completion?()
            })
            
            viewController.present(alert, animated: true)
        }
        
        /// Делится изображением с настроенным текстом для коллажа
        /// - Parameters:
        ///   - image: Изображение коллажа
        ///   - templateName: Название шаблона коллажа
        ///   - sourceView: View для позиционирования popover на iPad
        ///   - sourceRect: Rect для позиционирования popover на iPad
        ///   - presentingViewController: View controller для презентации
        func shareCollage(
            _ image: UIImage,
            templateName: String? = nil,
            sourceView: UIView,
            sourceRect: CGRect,
            from presentingViewController: UIViewController,
            completion: (() -> Void)? = nil
        ) {
            var shareText = "Посмотрите на мой коллаж, созданный в CollageMaker! 📸✨"
            
            if let templateName = templateName {
                shareText += "\nШаблон: \(templateName)"
            }
            
            shareImage(
                image,
                withText: shareText,
                sourceView: sourceView,
                sourceRect: sourceRect,
                from: presentingViewController,
                completion: completion
            )
        }
        
        /// Создает UIActivityViewController с настроенными параметрами
        /// - Parameters:
        ///   - items: Элементы для sharing
        ///   - sourceView: View для позиционирования popover на iPad
        ///   - sourceRect: Rect для позиционирования popover на iPad
        /// - Returns: Настроенный UIActivityViewController
        func createActivityViewController(
            with items: [Any],
            sourceView: UIView,
            sourceRect: CGRect
        ) -> UIActivityViewController {
            let activityVC = UIActivityViewController(
                activityItems: items,
                applicationActivities: nil
            )
            
            // Исключаем проблемные типы активности
            activityVC.excludedActivityTypes = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .markupAsPDF
            ]
            
            // Настройка для iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect
                    popover.permittedArrowDirections = [.up, .down]
                }
            }
            
            return activityVC
        }
        
        /// Проверяет доступность sharing на устройстве
        /// - Returns: true если sharing доступен
        func isSharingAvailable() -> Bool {
            // Проверяем базовую доступность UIActivityViewController
            return true // UIActivityViewController всегда доступен в iOS
        }
        
        /// Тестовый метод для показа диалога успеха Telegram (для отладки)
        func testShowTelegramSuccessDialog(from viewController: UIViewController) {
            print("🧪 SharingManager: Test method called - showing Telegram success dialog")
            showTelegramSuccessAlert(from: viewController)
        }
        
        /// Тестовый метод для показа диалога зависания Telegram (для отладки)
        func testShowTelegramHangDialog(from viewController: UIViewController) {
            print("🧪 SharingManager: Test method called - showing Telegram hang dialog")
            showTelegramHangInstructions(from: viewController)
        }
        
        /// Создает оптимизированные данные изображения для sharing
        /// - Parameter image: Исходное изображение
        /// - Returns: Оптимизированные данные изображения в формате JPEG
        func optimizeImageForSharing(_ image: UIImage) -> Data? {
            return autoreleasepool {
                print("🔧 SharingManager: Оптимизация изображения для sharing")
                
                // Максимальный размер для sharing
                let maxSize: CGFloat = 2048
                
                let optimizedImage: UIImage
                
                // Если изображение уже достаточно маленькое, используем как есть
                if image.size.width <= maxSize && image.size.height <= maxSize {
                    optimizedImage = image
                    print("🔧 SharingManager: Изображение не требует изменения размера")
                } else {
                    // Вычисляем новый размер с сохранением пропорций
                    let aspectRatio = image.size.width / image.size.height
                    let newSize: CGSize
                    
                    if aspectRatio > 1 {
                        // Ширина больше высоты
                        newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
                    } else {
                        // Высота больше ширины
                        newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
                    }
                    
                    print("🔧 SharingManager: Изменение размера с \(image.size) на \(newSize)")
                    
                    // Создаем новое изображение
                    UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
                    image.draw(in: CGRect(origin: .zero, size: newSize))
                    optimizedImage = UIGraphicsGetImageFromCurrentImageContext() ?? image
                    UIGraphicsEndImageContext()
                }
                
                // Конвертируем в JPEG Data для лучшей совместимости с sharing extensions
                // Используем качество 0.9 для баланса между качеством и размером
                guard let imageData = optimizedImage.jpegData(compressionQuality: 0.9) else {
                    print("❌ SharingManager: Не удалось создать JPEG данные")
                    return nil
                }
                
                let sizeInMB = Double(imageData.count) / 1_048_576
                print("🔧 SharingManager: Размер оптимизированного изображения: \(String(format: "%.2f", sizeInMB)) MB")
                
                return imageData
            }
        }
        
        /// Простой sharing без проблемных расширений
        /// - Parameters:
        ///   - image: Изображение для sharing
        ///   - sourceView: View для позиционирования popover на iPad
        ///   - sourceRect: Rect для позиционирования popover на iPad
        ///   - presentingViewController: View controller для презентации
        func simpleShareImage(
            _ image: UIImage,
            sourceView: UIView,
            sourceRect: CGRect,
            from presentingViewController: UIViewController,
            completion: (() -> Void)? = nil
        ) {
            print("🔗 SharingManager: Простой sharing изображения")
            
            // Оптимизируем изображение для sharing
            guard let optimizedImageData = optimizeImageForSharing(image) else {
                print("❌ SharingManager: Не удалось оптимизировать изображение для простого sharing")
                return
            }
            
            let activityVC = UIActivityViewController(
                activityItems: [optimizedImageData],
                applicationActivities: nil
            )
            
            // Агрессивно исключаем все потенциально проблемные типы
            var excludedTypes: [UIActivity.ActivityType] = [
                .assignToContact,
                .addToReadingList,
                .openInIBooks,
                .markupAsPDF,
                .copyToPasteboard,
                .print,

            ]
            
            // Добавляем новые типы активности для iOS 13+
            if #available(iOS 13.0, *) {
                excludedTypes.append(.collaborationInviteWithLink)
                excludedTypes.append(.collaborationCopyLink)
            }
            
            activityVC.excludedActivityTypes = excludedTypes
            
            // Настройка для iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect
                    popover.permittedArrowDirections = [.up, .down]
                }
            }
            
            activityVC.completionWithItemsHandler = { _, completed, _, error in
                if let error = error {
                    print("❌ SharingManager (Simple): \(error.localizedDescription)")
                } else if completed {
                    print("✅ SharingManager (Simple): Sharing завершен")
                }
                completion?()
            }
            
            presentingViewController.present(activityVC, animated: true) {
                print("✅ SharingManager (Simple): ActivityViewController показан")
            }
        }
        
        /// Ультра-безопасный sharing только с системными опциями
        /// - Parameters:
        ///   - image: Изображение для sharing
        ///   - sourceView: View для позиционирования popover на iPad
        ///   - sourceRect: Rect для позиционирования popover на iPad
        ///   - presentingViewController: View controller для презентации
        func safeModeShareImage(
            _ image: UIImage,
            sourceView: UIView,
            sourceRect: CGRect,
            from presentingViewController: UIViewController,
            completion: (() -> Void)? = nil
        ) {
            print("🔒 SharingManager: Безопасный режим sharing (только системные опции)")
            
            // Оптимизируем изображение для sharing
            guard let optimizedImageData = optimizeImageForSharing(image) else {
                print("❌ SharingManager: Не удалось оптимизировать изображение для безопасного sharing")
                return
            }
            
            // Создаем свой кастомный UIActivity для "Сохранить в фотоальбом"
            let saveToPhotosActivity = SaveToPhotosActivity()
            
            let activityVC = UIActivityViewController(
                activityItems: [optimizedImageData, image], // Передаем и Data и UIImage для совместимости с кастомной активностью
                applicationActivities: [saveToPhotosActivity]
            )
            
            // Исключаем ВСЕ стандартные активности, оставляем только наши кастомные
            activityVC.excludedActivityTypes = [
                .postToFacebook,
                .postToTwitter,
                .postToWeibo,
                .message,
                .mail,
                .print,
                .copyToPasteboard,
                .assignToContact,
                .saveToCameraRoll,
                .addToReadingList,
                .postToFlickr,
                .postToVimeo,
                .postToTencentWeibo,
                .airDrop,
                .openInIBooks,
                .markupAsPDF
            ]
            
            // Добавляем новые типы для iOS 13+
            if #available(iOS 13.0, *) {
                activityVC.excludedActivityTypes?.append(.collaborationInviteWithLink)
                activityVC.excludedActivityTypes?.append(.collaborationCopyLink)
                activityVC.excludedActivityTypes?.append(.sharePlay)
            }
            
            // Настройка для iPad
            if UIDevice.current.userInterfaceIdiom == .pad {
                if let popover = activityVC.popoverPresentationController {
                    popover.sourceView = sourceView
                    popover.sourceRect = sourceRect
                    popover.permittedArrowDirections = [.up, .down]
                }
            }
            
            activityVC.completionWithItemsHandler = { _, completed, _, error in
                if let error = error {
                    print("❌ SharingManager (Safe): \(error.localizedDescription)")
                } else if completed {
                    print("✅ SharingManager (Safe): Sharing завершен")
                } else {
                    print("ℹ️ SharingManager (Safe): Sharing отменен")
                }
                completion?()
            }
            
            presentingViewController.present(activityVC, animated: true) {
                print("✅ SharingManager (Safe): ActivityViewController показан")
            }
        }
        
        // MARK: - 🔍 РАСШИРЕННАЯ ДИАГНОСТИКА СИСТЕМЫ
        
        /// Диагностика состояния системы перед шарингом
        static func diagnoseSystemState() {
            print("🔍 === ДИАГНОСТИКА СОСТОЯНИЯ СИСТЕМЫ ===")
            
            // 📱 ИНФОРМАЦИЯ О СИСТЕМЕ
            let systemVersion = UIDevice.current.systemVersion
            let deviceModel = UIDevice.current.model
            print("📱 Устройство: \(deviceModel), iOS: \(systemVersion)")
            
            // 💾 ПАМЯТЬ
            let memoryUsage = getMemoryUsage()
            print("💾 Использование памяти: \(memoryUsage)MB")
            
            // 🔗 ПРОВЕРКА BACKGROUND APP REFRESH
            let backgroundRefreshStatus = UIApplication.shared.backgroundRefreshStatus
            print("🔗 Background Refresh: \(backgroundRefreshStatus.rawValue)")
            
            // 📊 СТАТИСТИКА ПРЕДЫДУЩИХ ПОПЫТОК
            sharingAttempts += 1
            print("📊 Попытка шаринга #\(sharingAttempts)")
            print("📊 Статистика: Успешных: \(shareSuccessCount), Неудачных: \(shareFailureCount)")
            
            if !errorStats.isEmpty {
                print("📊 Предыдущие ошибки:")
                for (errorKey, count) in errorStats {
                    print("   - \(errorKey): \(count) раз")
                }
            }
            
            // 🚨 СИСТЕМНЫЕ ПРОБЛЕМЫ
            if !systemIssuesDetected.isEmpty {
                print("🚨 Обнаруженные системные проблемы:")
                for issue in systemIssuesDetected {
                    print("   - \(issue)")
                }
            }
            
            // 🔍 ПРОВЕРКА ТЕКУЩЕГО СОСТОЯНИЯ
            if isCurrentlySharing {
                print("⚠️ ВНИМАНИЕ: Шаринг уже в процессе!")
            }
            
            // 🔍 ПРОВЕРКА ENTITLEMENTS
            checkEntitlements()
        }
        
        /// Получение использования памяти
        static func getMemoryUsage() -> Int {
            var taskInfo = mach_task_basic_info()
            var count = mach_msg_type_number_t(MemoryLayout<mach_task_basic_info>.size)/4
            
            let kerr: kern_return_t = withUnsafeMutablePointer(to: &taskInfo) {
                $0.withMemoryRebound(to: integer_t.self, capacity: 1) {
                    task_info(mach_task_self_, task_flavor_t(MACH_TASK_BASIC_INFO), $0, &count)
                }
            }
            
            if kerr == KERN_SUCCESS {
                return Int(taskInfo.resident_size) / 1024 / 1024
            }
            
            return 0
        }
        
        /// Проверка entitlements
        static func checkEntitlements() {
            print("🔍 === ПРОВЕРКА ENTITLEMENTS ===")
            
            // 📋 ПРОВЕРКА ОСНОВНЫХ ENTITLEMENTS
            let entitlements = [
                "com.apple.security.application-groups",
                "com.apple.developer.associated-domains",
                "com.apple.runningboard.process-state"
            ]
            
            for entitlement in entitlements {
                print("📋 Entitlement \(entitlement): нужно проверить в Info.plist")
            }
        }
        
        /// Запуск таймера обнаружения зависания
        static func startHangDetectionTimer(from viewController: UIViewController) {
            // Отключено по требованию: не запускаем таймер, просто отмечаем состояние
            isCurrentlySharing = true
            currentPresentingViewController = viewController
        }
        
        /// Диагностика зависания
        static func diagnoseHangState() {
            print("🔍 === ДИАГНОСТИКА ЗАВИСАНИЯ ===")
            
            // 📱 СТАТУС ACTIVITY VIEW CONTROLLER
            if let activityVC = currentActivityViewController {
                print("📱 Activity VC существует: \(activityVC)")
                print("📱 Presented: \(activityVC.isBeingPresented)")
                print("📱 Presenting VC: \(activityVC.presentingViewController?.description ?? "nil")")
                
                // 🔍 ПРОВЕРКА POPOVER
                if let popover = activityVC.popoverPresentationController {
                    print("📱 Popover: \(popover)")
                    print("📱 Popover sourceView: \(popover.sourceView?.description ?? "nil")")
                }
            }
            
            // 🔍 ПРОВЕРКА ОСНОВНОГО ПОТОКА
            if Thread.isMainThread {
                print("🔍 Находимся в главном потоке")
            } else {
                print("⚠️ НЕ в главном потоке!")
            }
            
            // 📊 ПРОВЕРКА СИСТЕМНЫХ РЕСУРСОВ
            let memoryUsage = getMemoryUsage()
            print("💾 Текущее использование памяти: \(memoryUsage)MB")
            
            // 🔍 ПРОВЕРКА RUNLOOP
            print("🔄 RunLoop: \(RunLoop.current)")
        }
        
            /// Показ расширенных инструкций при зависании
    static func showAdvancedHangInstructions() { }
    
    /// Показ alert'а о зависании
    private static func showHangAlert(from presentingVC: UIViewController) { }
        
            /// Принудительная очистка состояния шаринга
    static func forceCleanupSharing() {
        print("🔧 === ПРИНУДИТЕЛЬНАЯ ОЧИСТКА ШАРИНГА ===")
        
        // 🔓 РАЗБЛОКИРОВКА
        isCurrentlySharing = false
        
        // ⏰ ОСТАНОВКА ТАЙМЕРА
        sharingTimer?.invalidate()
        sharingTimer = nil
        
        // 🗑️ ОЧИСТКА ССЫЛОК
        if let activityVC = currentActivityViewController {
            print("🗑️ Принудительное закрытие Activity View Controller")
            DispatchQueue.main.async {
                activityVC.dismiss(animated: false) {
                    print("✅ Activity ViewController закрыт")
                }
            }
        }
        
        // 🧹 ОЧИСТКА ВСЕХ ССЫЛОК
        currentActivityViewController = nil
        currentPresentingViewController = nil
        
        // 📊 ОБНОВЛЕНИЕ СТАТИСТИКИ
        shareFailureCount += 1
        systemIssuesDetected.append("Forced cleanup after hang - iOS 18 sharing issue")
        
        // 🔄 НЕБОЛЬШАЯ ЗАДЕРЖКА ДЛЯ СТАБИЛИЗАЦИИ UI
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            print("✅ Принудительная очистка завершена - готово к новому шарингу")
        }
    }
        
        /// Детектирование известных проблем
        static func detectKnownIssues(error: Error, activityType: UIActivity.ActivityType?) {
            print("🔍 === ДЕТЕКТИРОВАНИЕ ИЗВЕСТНЫХ ПРОБЛЕМ ===")
            
            let errorCode = error._code
            let errorDomain = error._domain
            
            // 🔍 ИЗВЕСТНЫЕ КОДЫ ОШИБОК iOS 18
            switch errorCode {
            case 4099:
                print("🚨 Обнаружена ошибка 4099 (connection invalidated)")
                systemIssuesDetected.append("Error 4099: Connection invalidated - iOS 18 bug")
                
            case 4097:
                print("🚨 Обнаружена ошибка 4097 (XPC connection interrupted)")
                systemIssuesDetected.append("Error 4097: XPC connection interrupted")
                
            case 1:
                if errorDomain.contains("RBSService") {
                    print("🚨 Обнаружена ошибка RBSService (RunningBoard)")
                    systemIssuesDetected.append("RBSService error: RunningBoard service issue")
                }
                
            case 509:
                print("🚨 Обнаружена ошибка 509 (bug type из crash report)")
                systemIssuesDetected.append("Error 509: Known crash bug type")
                
            default:
                print("❓ Неизвестная ошибка: \(errorCode)")
            }
            
            // 🔍 ПРОВЕРКА ДОМЕНА ОШИБКИ
            if errorDomain.contains("NSCocoaErrorDomain") {
                print("🚨 NSCocoaErrorDomain - проблема с системными сервисами")
                systemIssuesDetected.append("NSCocoaErrorDomain error")
            }
            
            // 🔍 ПРОВЕРКА КОНКРЕТНОГО ПРИЛОЖЕНИЯ
            if let activityType = activityType {
                if activityType.rawValue.contains("Telegraph") {
                    print("🚨 Telegram-специфичная проблема")
                    systemIssuesDetected.append("Telegram-specific issue")
                }
            }
            
            // 📊 ОБНОВЛЕНИЕ СТАТИСТИКИ ОШИБОК
            let errorKey = "\(errorDomain)_\(errorCode)"
            errorStats[errorKey] = (errorStats[errorKey] ?? 0) + 1
            shareFailureCount += 1
        }
        
        /// Показ детального лога ошибок
        static func showDetailedErrorLog() {
            print("📊 === ДЕТАЛЬНЫЙ ЛОГ ОШИБОК ===")
            print("📊 Общая статистика:")
            print("   - Всего попыток: \(sharingAttempts)")
            print("   - Успешных: \(shareSuccessCount)")
            print("   - Неудачных: \(shareFailureCount)")
            print("   - Коэффициент успеха: \(shareSuccessCount > 0 ? Double(shareSuccessCount) / Double(sharingAttempts) * 100 : 0)%")
            
            if !errorStats.isEmpty {
                print("📊 Детали ошибок:")
                for (errorKey, count) in errorStats.sorted(by: { $0.value > $1.value }) {
                    print("   - \(errorKey): \(count) раз")
                }
            }
            
            if !systemIssuesDetected.isEmpty {
                print("🚨 Системные проблемы:")
                for issue in systemIssuesDetected {
                    print("   - \(issue)")
                }
            }
        }
        
            /// Показ alert о текущем шаринге
    static func showCurrentSharingAlert(from viewController: UIViewController) {
        // 🔍 ПРОВЕРЯЕМ, МОЖНО ЛИ ПОКАЗАТЬ ALERT
        if viewController.presentedViewController != nil {
            print("⚠️ Нельзя показать alert о повторном шаринге - уже что-то представлено")
            print("🔄 ПОВТОРНЫЙ ШАРИНГ: попытка #\(sharingAttempts)")
            return
        }
        
        let alert = UIAlertController(
            title: "🔄 Шаринг уже в процессе",
            message: """
            Обнаружена попытка повторного шаринга!
            
            📱 Что делать:
            • Подождите завершения текущего шаринга
            • Или принудительно очистите состояние
            
            ⏰ Попытка #\(sharingAttempts)
            """,
            preferredStyle: .alert
        )
        
        alert.addAction(UIAlertAction(title: "🔧 Принудительная очистка", style: .default) { _ in
            forceCleanupSharing()
        })
        
        alert.addAction(UIAlertAction(title: "⏰ Подождать", style: .cancel))
        
        DispatchQueue.main.async {
            viewController.present(alert, animated: true)
        }
    }
        
        /// Проверка статуса Activity View Controller
        static func checkActivityViewControllerStatus() {
            print("🔍 === ПРОВЕРКА СТАТУСА ACTIVITY VIEW CONTROLLER ===")
            
            guard let activityVC = currentActivityViewController else {
                print("❌ Activity View Controller не найден")
                return
            }
            
            print("📱 Activity VC статус:")
            print("   - isBeingPresented: \(activityVC.isBeingPresented)")
            print("   - presentingViewController: \(activityVC.presentingViewController?.description ?? "nil")")
            print("   - view.window: \(activityVC.view.window?.description ?? "nil")")
            
            // 🔍 ПРОВЕРКА POPOVER
            if let popover = activityVC.popoverPresentationController {
                print("📱 Popover статус:")
                print("   - sourceView: \(popover.sourceView?.description ?? "nil")")
                print("   - presentedViewController: \(popover.presentedViewController.description)")
            }
            
            // 🔍 ПРОВЕРКА ДОЧЕРНИХ VIEW CONTROLLERS
            if !activityVC.children.isEmpty {
                print("👶 Дочерние VCs: \(activityVC.children.count)")
                for (index, child) in activityVC.children.enumerated() {
                    print("   - Child \(index): \(child.description)")
                }
            }
            
            // 🔍 ПРОВЕРКА VIEW HIERARCHY
            print("🏗️ View hierarchy:")
            print("   - view.superview: \(activityVC.view.superview?.description ?? "nil")")
            print("   - view.bounds: \(activityVC.view.bounds)")
            print("   - view.frame: \(activityVC.view.frame)")
            
            // 🚨 ДЕТЕКТИРОВАНИЕ ПРОБЛЕМ
            if !activityVC.isBeingPresented && activityVC.presentingViewController == nil {
                print("🚨 ПРОБЛЕМА: Activity VC не отображается корректно!")
                systemIssuesDetected.append("Activity VC not displaying correctly")
            }
        }
    }
    
    /// Кастомная активность для сохранения в фотоальбом
    class SaveToPhotosActivity: UIActivity {
        
        private var savedImage: UIImage?
        
        override var activityType: UIActivity.ActivityType? {
            return UIActivity.ActivityType("com.collageMaker.saveToPhotos")
        }
        
        override var activityTitle: String? {
            return "Сохранить в Фото"
        }
        
        override var activityImage: UIImage? {
            return UIImage(systemName: "photo.badge.plus") ?? UIImage(systemName: "photo")
        }
        
        override func canPerform(withActivityItems activityItems: [Any]) -> Bool {
            return activityItems.contains { $0 is UIImage }
        }
        
        override func prepare(withActivityItems activityItems: [Any]) {
            savedImage = activityItems.first { $0 is UIImage } as? UIImage
        }
        
        override func perform() {
            guard let image = savedImage else {
                activityDidFinish(false)
                return
            }
            
            UIImageWriteToSavedPhotosAlbum(image, self, #selector(image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        
        @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
            DispatchQueue.main.async {
                if error != nil {
                    print("❌ SaveToPhotosActivity: Ошибка сохранения в фотоальбом")
                    self.activityDidFinish(false)
                } else {
                    print("✅ SaveToPhotosActivity: Изображение сохранено в фотоальбом")
                    self.activityDidFinish(true)
                }
            }
        }
    }
    
    // MARK: - 🎭 DELEGATE ДЛЯ PRESENTATION
    class SharingPresentationDelegate: NSObject, UIAdaptivePresentationControllerDelegate {
        
        func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
            print("🎭 Presentation controller will dismiss")
        }
        
        func presentationControllerDidDismiss(_ presentationController: UIPresentationController) {
            print("🎭 Presentation controller did dismiss")
            
            // 🔓 РАЗБЛОКИРОВКА ПРИ ЗАКРЫТИИ
            SharingManager.forceCleanupSharing()
        }
        
        func presentationControllerDidAttemptToDismiss(_ presentationController: UIPresentationController) {
            print("🎭 Presentation controller did attempt to dismiss")
        }
    }