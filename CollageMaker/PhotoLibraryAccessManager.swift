//
//  PhotoLibraryAccessManager.swift
//  CollageMaker
//
//  Created by Vasili krasnoyski on 01.02.2025.
//

import Photos
import UIKit

/// Manages photo library access permissions and guides the user accordingly.
class PhotoLibraryAccessManager {
    static let shared = PhotoLibraryAccessManager()
    private init() {}
    
    /// Checks the current photo library access status and requests access if not determined.
    /// - Parameter completion: A closure that returns true if access is granted, otherwise false.
    func checkPhotoLibraryAccess(completion: @escaping (Bool) -> Void) {
        // Get the current authorization status for reading and writing.
        let status = PHPhotoLibrary.authorizationStatus(for: .readWrite)
        
        print("📸 Текущий статус доступа к Photos: \(status.rawValue)")
        
        switch status {
        case .authorized, .limited:
            // Access already granted.
            print("✅ Доступ к Photos разрешен")
            completion(true)
        case .denied, .restricted:
            // Access has been denied or restricted.
            print("❌ Доступ к Photos запрещен или ограничен")
            completion(false)
        case .notDetermined:
            // Request access.
            print("🔄 Запрашиваем доступ к Photos...")
            PHPhotoLibrary.requestAuthorization(for: .readWrite) { newStatus in
                DispatchQueue.main.async {
                    print("📸 Новый статус доступа к Photos: \(newStatus.rawValue)")
                    if newStatus == .authorized || newStatus == .limited {
                        print("✅ Доступ к Photos предоставлен")
                        completion(true)
                    } else {
                        print("❌ Доступ к Photos отклонен")
                        completion(false)
                    }
                }
            }
        @unknown default:
            print("❓ Неизвестный статус доступа к Photos")
            completion(false)
        }
    }
    
    /// Opens the app settings so the user can manually grant photo library access.
    func openAppSettings() {
        guard let settingsURL = URL(string: UIApplication.openSettingsURLString) else { return }
        if UIApplication.shared.canOpenURL(settingsURL) {
            UIApplication.shared.open(settingsURL, options: [:], completionHandler: nil)
        }
    }
    
    /// Presents an alert on the given view controller that informs the user about the missing permission
    /// and provides an option to open the app settings.
    /// - Parameter viewController: The view controller on which the alert will be presented.
    func showPermissionAlert(on viewController: UIViewController) {
        let alert = UIAlertController(title: "Photo Library Access Needed",
                                      message: "This app requires access to your photo library to select photos for your collage. Please grant access in Settings.",
                                      preferredStyle: .alert)
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel, handler: nil))
        alert.addAction(UIAlertAction(title: "Settings", style: .default, handler: { _ in
            self.openAppSettings()
        }))
        viewController.present(alert, animated: true, completion: nil)
    }
}
