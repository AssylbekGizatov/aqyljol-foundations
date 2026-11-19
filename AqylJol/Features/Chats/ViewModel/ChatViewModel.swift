import Foundation
import FirebaseFirestore

final class ChatViewModel {
    
    public var onMessages: (([ChatMessage]) -> Void)?
    public var isBusy: ((Bool) -> Void)?
    public var errorText: ((String?) -> Void)?
    
    private let repo: ChatRepository
    private let service: ChatServicing
    private let cache: ChatLocalStore
    private var listener: ListenerRegistration?
    private(set) var messages: [ChatMessage] = [] {
        didSet { onMessages?(messages); cache.save(messages) }
    }
    
    public init(repo: ChatRepository,
                service: ChatServicing,
                cache: ChatLocalStore = .shared) {
        self.repo = repo
        self.service = service
        self.cache = cache
    }
    
    public func bootstrapAfterLogin(limit: Int = 200) {
        cache.load { [weak self] cached in
            guard let self else { return }
            if !cached.isEmpty { self.onMessages?(cached) }
        }
        repo.fetchAll(limit: limit) { [weak self] res in
            guard let self else { return }
            switch res {
            case .success(let msgs): self.messages = msgs
            case .failure(let e):    self.errorText?(e.localizedDescription)
            }
        }
    }
    
    func startListening(limit: Int = 200) {
        stopListening()
        listener = repo.listen(limit: limit, onChange: { [weak self] msgs in
            self?.messages = msgs
        }, onError: { [weak self] err in
            self?.errorText?(err.localizedDescription)
        })
    }
    func stopListening() { listener?.remove(); listener = nil }
    
    func send(text: String, latitude: Double?, longitude: Double?) {
        let t = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        isBusy?(true); errorText?(nil)
        
        repo.sendUserMessage(t) { [weak self] r in
            guard let self else { return }
            if case .failure(let e) = r {
                self.isBusy?(false); self.errorText?(e.localizedDescription); return
            }
            self.service.sendQuery(latitude: latitude, longitude: longitude, userText: t) { [weak self] s in
                guard let self else { return }
                switch s {
                case .success(let payload):
                    self.repo.sendLlamaMessage(text: payload.message,
                                               results: payload.results,
                                               rawJSON: payload.rawJSON) { res in   // <— НОВОЕ
                        DispatchQueue.main.async {
                            self.isBusy?(false)
                            if case .failure(let e) = res { self.errorText?(e.localizedDescription) }
                        }
                    }
                case .failure(let e):
                    DispatchQueue.main.async {
                        self.isBusy?(false)
                        if let urlErr = e as? URLError {
                            switch urlErr.code {
                            case .cannotConnectToHost:
                                self.errorText?("Сервер недоступен. Проверьте, что он запущен и порт 8000 открыт. (HTTP, без https)")
                            case .notConnectedToInternet:
                                self.errorText?("Нет подключения к интернету.")
                            case .timedOut:
                                self.errorText?("Таймаут запроса. Сервер отвечает слишком долго.")
                            default:
                                self.errorText?("Ошибка сети (\(urlErr.code.rawValue)): \(urlErr.localizedDescription)")
                            }
                        } else if let ns = e as NSError?, ns.domain == "ChatServiceHTTP" {
                            self.errorText?("Сервер ответил HTTP \(ns.code). \(ns.localizedDescription)")
                        } else {
                            self.errorText?(e.localizedDescription)
                        }
                    }
                }
            }
        }
    }
    
    public func clearOnLogout() {
        stopListening()
        cache.clear()
        messages = []
    }
}
