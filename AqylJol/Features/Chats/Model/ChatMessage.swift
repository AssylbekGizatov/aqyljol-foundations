import Foundation
import FirebaseFirestore

struct ChatMessage: Codable, Equatable, Identifiable {
    var id: String
    var role: ChatRole
    var message: String
    var results: [Place]?
    var createdAt: Date
    var rawJSON: String?
    
    init(
        id: String = UUID().uuidString,
        role: ChatRole,
        message: String,
        results: [Place]? = nil,
        createdAt: Date = Date(),
        rawJSON: String? = nil
    ) {
        self.id = id
        self.role = role
        self.message = message
        self.results = results
        self.createdAt = createdAt
        self.rawJSON = rawJSON
    }
    
    var asDict: [String: Any] {
        var d: [String: Any] = [
            "id": id,
            "role": role.rawValue,
            "message": message,
            "createdAt": Timestamp(date: createdAt)
        ]
        if let results {
            d["results"] = results.map { p in
                [
                    "name": p.name,
                    "type": p.type,
                    "latitude": p.latitude,
                    "longitude": p.longitude,
                    "distance_km": p.distance_km,
                    "rating": p.rating,
                    "description": p.description
                ]
            }
        }
        if let rawJSON { d["raw"] = rawJSON }
        return d
    }
    
    public static func from(document: DocumentSnapshot) throws -> ChatMessage {
        guard let dict = document.data() else {
            throw ChatDecodeError.emptyDocument
        }
        return try from(id: document.documentID, dict: dict)
    }
    
    public static func from(id: String, dict: [String: Any]) throws -> ChatMessage {
        guard let roleRaw = dict["role"] as? String else {
            throw ChatDecodeError.missing("role")
        }
        guard let role = ChatRole(rawValue: roleRaw) else {
            throw ChatDecodeError.invalidRole(roleRaw)
        }
        
        guard let message = dict["message"] as? String else {
            throw ChatDecodeError.missing("message")
        }
        
        let createdAt: Date
        if let ts = dict["createdAt"] as? Timestamp {
            createdAt = ts.dateValue()
        } else if let date = dict["createdAt"] as? Date {
            createdAt = date
        } else {
            createdAt = Date()
        }
        
        var results: [Place]? = nil
        if let arr = dict["results"] as? [[String: Any]] {
            results = try arr.map { try Place.from(dict: $0) }
        }
        
        let raw = dict["raw"] as? String
        
        return ChatMessage(id: id, role: role, message: message, results: results, createdAt: createdAt, rawJSON: raw)
    }
}

public enum ChatDecodeError: Error, LocalizedError {
    case emptyDocument
    case missing(String)
    case invalidRole(String)
    case typeMismatch(field: String, expected: String)

    public var errorDescription: String? {
        switch self {
        case .emptyDocument: return "Empty Firestore document"
        case .missing(let f): return "Missing field: \(f)"
        case .invalidRole(let r): return "Invalid role: \(r)"
        case .typeMismatch(let field, let expected): return "Type mismatch for \(field), expected \(expected)"
        }
    }
}

private extension Place {
    static func from(dict: [String: Any]) throws -> Place {
        guard let name = dict["name"] as? String else { throw ChatDecodeError.missing("results[].name") }
        guard let type = dict["type"] as? String else { throw ChatDecodeError.missing("results[].type") }
        func num(_ key: String) throws -> Double {
            if let d = dict[key] as? Double { return d }
            if let i = dict[key] as? Int { return Double(i) }
            if let n = dict[key] as? NSNumber { return n.doubleValue }
            throw ChatDecodeError.typeMismatch(field: "results[].\(key)", expected: "Number")
        }

        let lat = try num("latitude")
        let lon = try num("longitude")
        let dist = try num("distance_km")
        let rating = try num("rating")
        let desc = dict["description"] as? String ?? ""

        return Place(name: name,
                     type: type,
                     latitude: lat,
                     longitude: lon,
                     distance_km: dist,
                     rating: rating,
                     description: desc)
    }
}
