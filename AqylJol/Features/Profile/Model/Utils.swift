import Foundation

extension String {
    func localize(comment: String = "") -> String {
        let defaultLanguage = "en"
        let preferredCode =
            (UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String)
            ?? Locale.preferredLanguages.first
            ?? defaultLanguage
        
        if let path = Bundle.main.path(forResource: preferredCode, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            let value = NSLocalizedString(self, tableName: nil, bundle: bundle, value: self, comment: comment)
            if value != self { return value }
        }
        
        if let path = Bundle.main.path(forResource: defaultLanguage, ofType: "lproj"),
           let bundle = Bundle(path: path) {
            return NSLocalizedString(self, tableName: nil, bundle: bundle, value: self, comment: comment)
        }
        
        return self
    }
}
