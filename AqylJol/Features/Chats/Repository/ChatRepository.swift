// ChatRepository.swift
import Foundation
import FirebaseAuth
import FirebaseFirestore

final class ChatRepository {
    private let db: Firestore
    private let uidProvider: () -> String?
    
    init(db: Firestore = Firestore.firestore(),
         uidProvider: @escaping () -> String? = { Auth.auth().currentUser?.uid }) {
        self.db = db
        self.uidProvider = uidProvider
    }
    
    // MARK: - Paths
    private func userDoc(_ uid: String) -> DocumentReference {
        db.collection("users").document(uid)
    }
    
    // MARK: - Parsing
    private func parseMessages(_ snap: DocumentSnapshot, limit: Int) -> [ChatMessage] {
        guard let dict = snap.data() else { return [] }
        let raw = (dict["chatHistory"] as? [[String: Any]]) ?? []
        var msgs: [ChatMessage] = raw.compactMap { item in
            let id = (item["id"] as? String) ?? UUID().uuidString
            return try? ChatMessage.from(id: id, dict: item)
        }
        msgs.sort { $0.createdAt < $1.createdAt }
        if limit > 0, msgs.count > limit { msgs = Array(msgs.suffix(limit)) }
        return msgs
    }
    
    // MARK: - One-shot fetch
    func fetchAll(limit: Int = 200, completion: @escaping (Result<[ChatMessage], Error>) -> Void) {
        guard let uid = uidProvider() else {
            return completion(.failure(NSError(domain: "ChatRepository", code: 401,
                                               userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
        }
        userDoc(uid).getDocument { [weak self] snap, err in
            if let err = err { return completion(.failure(err)) }
            guard let self, let snap = snap, snap.exists else { return completion(.success([])) }
            completion(.success(self.parseMessages(snap, limit: limit)))
        }
    }
    
    // MARK: - Realtime listen (на сам документ)
    @discardableResult
    func listen(limit: Int = 200,
                onChange: @escaping ([ChatMessage]) -> Void,
                onError: @escaping (Error) -> Void) -> ListenerRegistration {
        guard let uid = uidProvider() else {
            onError(NSError(domain: "ChatRepository", code: 401,
                            userInfo: [NSLocalizedDescriptionKey: "Not authenticated"]))
            return db.collection("_").addSnapshotListener { _, _ in }
        }
        return userDoc(uid).addSnapshotListener { [weak self] snap, err in
            if let err = err { return onError(err) }
            guard let self, let snap = snap, snap.exists else { return onChange([]) }
            onChange(self.parseMessages(snap, limit: limit))
        }
    }
    
    // MARK: - Public send API
    func sendUserMessage(_ text: String,
                         createdAt: Date = Date(),
                         completion: ((Result<Void, Error>) -> Void)? = nil) {
        send(role: .user, text: text, results: nil, rawJSON: nil, createdAt: createdAt, completion: completion)
    }
    
    func sendLlamaMessage(text: String,
                          results: [Place]?,
                          rawJSON: String?,
                          createdAt: Date = Date(),
                          completion: ((Result<Void, Error>) -> Void)? = nil) {
        send(role: .llama, text: text, results: results, rawJSON: rawJSON, createdAt: createdAt, completion: completion)
    }
    
    // MARK: - Transactional append to array
    private func send(role: ChatRole,
                      text: String,
                      results: [Place]?,
                      rawJSON: String?,
                      createdAt: Date,
                      completion: ((Result<Void, Error>) -> Void)?) {
        guard let uid = uidProvider() else {
            completion?(.failure(NSError(domain: "ChatRepository", code: 401,
                                         userInfo: [NSLocalizedDescriptionKey: "Not authenticated"])))
            return
        }
        let doc = userDoc(uid)
        let msg = ChatMessage(role: role, message: text, results: results, createdAt: createdAt, rawJSON: rawJSON)
        
        db.runTransaction({ (txn, errorPtr) -> Any? in
            var arr = (try? txn.getDocument(doc).data()?["chatHistory"] as? [[String: Any]]) ?? []
            arr.append(msg.asDict)
            if arr.count > 500 { arr = Array(arr.suffix(500)) }
            txn.updateData(["chatHistory": arr], forDocument: doc)
            return nil
        }, completion: { _, error in
            if let error = error { completion?(.failure(error)) }
            else { completion?(.success(())) }
        })
    }
}
