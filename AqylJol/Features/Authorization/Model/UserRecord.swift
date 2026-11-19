import Foundation

struct UserRecord: Codable, Equatable {
    var uid: String
    var email: String
    var firstName: String
    var lastName: String
    var role: String?
    var createdAt: Date?
    var chatHistory: [ChatMessage]
}
