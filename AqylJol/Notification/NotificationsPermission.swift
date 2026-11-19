import UIKit
import UserNotifications

enum NotificationsPermission {
    static func requestIfNeeded(completion: @escaping () -> Void) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { settings in
            switch settings.authorizationStatus {
            case .notDetermined:
                center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                    DispatchQueue.main.async {
                        if granted { UIApplication.shared.registerForRemoteNotifications() }
                        completion()
                    }
                }
            case .authorized, .provisional, .ephemeral:
                DispatchQueue.main.async {
                    UIApplication.shared.registerForRemoteNotifications()
                    completion()
                }
            case .denied:
                DispatchQueue.main.async { completion() }
            @unknown default:
                DispatchQueue.main.async { completion() }
            }
        }
    }
}

extension Notification.Name {
    static let appLanguageDidChange = Notification.Name("app.languageDidChange")
}
