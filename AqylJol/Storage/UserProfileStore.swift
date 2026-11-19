import Foundation

final class UserProfileStore {
    public static let shared = UserProfileStore()
    private init() {}
    
    private let defaults = UserDefaults.standard
    private let key = "user_record"
    
    // MARK: - Save full record
    func save(_ record: UserRecord) {
        do {
            let data = try JSONEncoder().encode(record)
            defaults.set(data, forKey: key)
        } catch {
            print("[UserProfileStore] save error:", error)
        }
    }
    
    // MARK: - Load full record
    func load() -> UserRecord? {
        guard let data = defaults.data(forKey: key) else { return nil }
        do {
            return try JSONDecoder().decode(UserRecord.self, from: data)
        } catch {
            print("[UserProfileStore] load error:", error)
            return nil
        }
    }
    
    // MARK: - Clear
    func clear() {
        defaults.removeObject(forKey: key)
    }
}
