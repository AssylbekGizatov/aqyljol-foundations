import Foundation

public final class ChatLocalStore {
    public static let shared = ChatLocalStore()
    private init() {}

    private let fm = FileManager.default
    private let queue = DispatchQueue(label: "chat.local", qos: .utility)

    private func url() -> URL {
        let base = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let dir = base.appendingPathComponent("ChatCache", isDirectory: true)
        try? fm.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("messages.json")
    }

    func load(completion: @escaping ([ChatMessage]) -> Void) {
        queue.async {
            let u = self.url()
            guard let data = try? Data(contentsOf: u), !data.isEmpty,
                  let msgs = try? JSONDecoder().decode([ChatMessage].self, from: data) else {
                return DispatchQueue.main.async { completion([]) }
            }
            DispatchQueue.main.async { completion(msgs) }
        }
    }
    func save(_ messages: [ChatMessage], limit: Int = 200) {
        let trimmed = Array(messages.suffix(limit))
        queue.async {
            guard let data = try? JSONEncoder().encode(trimmed) else { return }
            try? data.write(to: self.url(), options: .atomic)
        }
    }
    func clear() {
        queue.async { try? FileManager.default.removeItem(at: self.url()) }
    }
}
