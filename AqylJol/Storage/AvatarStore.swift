import UIKit

final class AvatarStore {
    static let shared = AvatarStore()
    private init() {}

    private let fm = FileManager.default
    private let queue = DispatchQueue(label: "avatar.store", qos: .utility)
    private var cache: UIImage?

    private func fileURL() -> URL {
        let dir = fm.urls(for: .applicationSupportDirectory, in: .userDomainMask).first!
        let folder = dir.appendingPathComponent("UserProfile", isDirectory: true)
        try? fm.createDirectory(at: folder, withIntermediateDirectories: true)
        return folder.appendingPathComponent("avatar.png", isDirectory: false)
    }

    func load() -> UIImage? {
        if let cache { return cache }
        let url = fileURL()
        guard fm.fileExists(atPath: url.path) else { return nil }
        let img = UIImage(contentsOfFile: url.path)
        if let img { cache = img }
        return img
    }
    
    func save(_ image: UIImage, completion: (() -> Void)? = nil) {
        cache = image
        guard let data = image.pngData() ?? image.jpegData(compressionQuality: 0.92) else {
            completion?(); return
        }
        queue.async {
            do { try data.write(to: self.fileURL(), options: .atomic) }
            catch { print("[AvatarStore] save error:", error) }
            DispatchQueue.main.async { completion?() }
        }
    }

    func clear() {
        cache = nil
        try? fm.removeItem(at: fileURL())
    }
}
