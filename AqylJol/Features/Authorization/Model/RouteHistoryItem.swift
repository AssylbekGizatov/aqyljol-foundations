import Foundation
import FirebaseCore
import UIKit

struct RouteHistoryItem: Codable, Equatable {
    var title: String
    var address: String
    var createdAt: Date

    init(title: String, address: String, createdAt: Date = Date()) {
        self.title = title
        self.address = address
        self.createdAt = createdAt
    }

    var asDict: [String: Any] {
        [
            "title": title,
            "address": address,
            "createdAt": Timestamp(date: createdAt)
        ]
    }
}
