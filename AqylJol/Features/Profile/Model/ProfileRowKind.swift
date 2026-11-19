import UIKit

enum ProfileRowKind {
    case notifications(isOn: Bool)
    case languages(current: String)
    case darkMode(isOn: Bool)

    var title: String {
        switch self {
        case .notifications: return "settings.notifications".localize()
        case .languages: return "settings.language".localize()
        case .darkMode(let on): return on ? "settings.dark".localize() : "settings.light".localize()
        }
    }

    var iconName: String {
        switch self {
        case .notifications: return "bell.fill"
        case .languages: return "globe"
        case .darkMode(let on): return on ? "moon.fill" : "sun.max.fill"
        }
    }

    var iconTint: UIColor {
        switch self {
        case .notifications: return .systemOrange
        case .languages: return .systemBlue
        case .darkMode(let on): return on ? .systemIndigo : .systemYellow
        }
    }

    var showsSwitch: Bool {
        switch self {
        case .notifications, .darkMode: return true
        default: return false
        }
    }

    var trailingDetail: String? {
        switch self {
        case .languages(let current): return current
        default: return nil
        }
    }

    var initialSwitchOn: Bool {
        switch self {
        case .notifications(let on), .darkMode(let on): return on
        default: return false
        }
    }
}
