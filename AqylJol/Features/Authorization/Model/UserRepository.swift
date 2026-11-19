import Foundation
import FirebaseFirestore

final class UserRepository {
    private let db: Firestore
    init(db: Firestore = Firestore.firestore()) { self.db = db }
    
    private var users: CollectionReference { db.collection("users") }
    
    func create(uid: String, email: String, firstName: String, lastName: String, role: String?, completion: @escaping (Result<UserRecord, Error>) -> Void) {
        var data: [String: Any] = [
            "email": email,
            "firstName": firstName,
            "lastName": lastName,
            "createdAt": FieldValue.serverTimestamp(),
            "chatHistory": []
        ]
        if let role, !role.isEmpty { data["role"] = role }
        
        users.document(uid).setData(data, merge: false) { [weak self] error in
            if let error = error { return completion(.failure(error)) }
            self?.fetch(uid: uid, completion: completion)
        }
    }
    
    func fetch(uid: String, completion: @escaping (Result<UserRecord, Error>) -> Void) {
        users.document(uid).getDocument { snap, err in
            if let err = err { return completion(.failure(err)) }
            guard let snap = snap, snap.exists, let dict = snap.data() else {
                return completion(.failure(NSError(domain: "Firestore", code: 404, userInfo: [NSLocalizedDescriptionKey: "User not found"])) )
            }
            do {
                let record = try Self.record(from: dict, uid: snap.documentID)
                completion(.success(record))
            } catch { completion(.failure(error)) }
        }
    }
    
    func addHistory(uid: String, item: RouteHistoryItem, completion: ((Error?) -> Void)? = nil) {
        users.document(uid).updateData([
            "history": FieldValue.arrayUnion([item.asDict])
        ]) { error in completion?(error) }
    }
    
    private static func record(from dict: [String: Any], uid: String) throws -> UserRecord {
        let email = dict["email"] as? String ?? ""
        let first = dict["firstName"] as? String ?? ""
        let last = dict["lastName"] as? String ?? ""
        let role = dict["role"] as? String
        let created: Date? = (dict["createdAt"] as? Timestamp)?.dateValue()

        return UserRecord(uid: uid, email: email, firstName: first, lastName: last, role: role, createdAt: created, chatHistory: [])
    }
    
    func updateProfile(uid: String,
                           firstName: String,
                           lastName: String,
                           role: String?,
                       completion: @escaping (Error?) -> Void) {
        var data: [String: Any] = [
            "firstName": firstName,
            "lastName": lastName,
            "updatedAt": FieldValue.serverTimestamp()
        ]
        if let role, !role.isEmpty {
            data["role"] = role
        } else {
            data["role"] = FieldValue.delete()
        }
        users.document(uid).setData(data, merge: true, completion: completion)
    }
}
