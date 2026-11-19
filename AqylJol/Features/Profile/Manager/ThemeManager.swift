import UIKit

final class ThemeManager {
    static let shared = ThemeManager()

    private let key = "app.theme"
    private(set) var current: AppTheme

    private init() {
        if let raw = UserDefaults.standard.string(forKey: key),
           let t = AppTheme(rawValue: raw) {
            current = t
        } else {
            current = .light
        }
    }

    func set(_ theme: AppTheme) {
        guard theme != current else { return }
        current = theme
        UserDefaults.standard.set(theme.rawValue, forKey: key)
        applyToAllWindows()
    }

    func apply(to window: UIWindow) {
        switch current {
        case .light:
            window.overrideUserInterfaceStyle = .light
        case .dark:
            window.overrideUserInterfaceStyle = .dark
        }
    }

    func applyToAllWindows() {
        for scene in UIApplication.shared.connectedScenes {
            guard let ws = scene as? UIWindowScene else { continue }
            for window in ws.windows {
                apply(to: window)
            }
        }
    }
}
