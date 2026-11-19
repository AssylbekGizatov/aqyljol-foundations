import Foundation

enum AppLanguage: String {
    case russian = "ru"
    case english = "en"
    case kazakh  = "kk"

    var displayName: String {
        switch self {
        case .russian: return "Русский"
        case .english: return "English"
        case .kazakh:  return "Қазақша"
        }
    }
}
