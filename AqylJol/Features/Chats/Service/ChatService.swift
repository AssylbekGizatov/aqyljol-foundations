import Foundation

protocol ChatServicing {
    func sendQuery(latitude: Double?, longitude: Double?, userText: String,
                   completion: @escaping (Result<(message: String, results: [Place]?, rawJSON: String?), Error>) -> Void)
}

final class ChatServiceHTTP: ChatServicing {
    private let baseURL: URL
    private let session: URLSession

    init(baseURL: URL, session: URLSession = .shared) {
        self.baseURL = baseURL
        if session === URLSession.shared {
            let cfg = URLSessionConfiguration.default
            cfg.timeoutIntervalForRequest = 12
            cfg.waitsForConnectivity = true
            self.session = URLSession(configuration: cfg)
        } else {
            self.session = session
        }
    }

    private struct Req: Encodable {
        let longitude: Double?
        let latitude: Double?
        let user_text: String
    }
    
    private struct Resp: Decodable {
        let message: String?
        let results: [Place]?

        init(from decoder: Decoder) throws {
            let c = try decoder.container(keyedBy: AnyCodingKey.self)
            
            self.results =
                (try? c.decode([Place].self, forKey: AnyCodingKey("results"))) ??
                (try? c.decode([Place].self, forKey: AnyCodingKey("places")))
            let candidates = ["message","reply","text","answer","output"]
            var m: String? = nil
            for key in candidates {
                if let v = try? c.decode(String.self, forKey: AnyCodingKey(key)),
                   !v.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                    m = v
                    break
                }
            }
            if m == nil,
               let choices = try? c.decode([Choice].self, forKey: AnyCodingKey("choices")),
               let content = choices.first?.message.content,
               !content.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                m = content
            }
            self.message = m
        }

        private struct Choice: Decodable { let message: ChoiceMessage }
        private struct ChoiceMessage: Decodable { let content: String }

        private struct AnyCodingKey: CodingKey {
            var stringValue: String
            var intValue: Int?

            init(_ s: String) { self.stringValue = s; self.intValue = nil }
            init(stringValue: String) { self.init(stringValue) }
            init?(intValue: Int) {
                self.intValue = intValue
                self.stringValue = String(intValue)
            }
        }
    }

    // MARK: - Helpers
    private func decodePlaces(from data: Data) -> [Place]? {
        if let arr = try? JSONDecoder().decode([Place].self, from: data) { return arr }
        if let one = try? JSONDecoder().decode(Place.self, from: data) { return [one] }
        return nil
    }

    private func decodePlaces(fromJSONString s: String) -> [Place]? {
        guard let d = s.data(using: .utf8) else { return nil }
        return decodePlaces(from: d)
    }

    // MARK: - Public
    func sendQuery(latitude: Double?, longitude: Double?, userText: String,
                   completion: @escaping (Result<(message: String, results: [Place]?, rawJSON: String?), Error>) -> Void) {
        var req = URLRequest(url: baseURL.appendingPathComponent("/chat"))
        req.httpMethod = "POST"
        req.setValue("application/json", forHTTPHeaderField: "Content-Type")

        do {
            let payload = Req(longitude: longitude, latitude: latitude, user_text: userText)
            req.httpBody = try JSONEncoder().encode(payload)
            print("[Chat] POST \(req.url!.absoluteString)")
            print("[Chat] BODY:", String(data: req.httpBody!, encoding: .utf8) ?? "<?>")
        } catch {
            return completion(.failure(error))
        }

        session.dataTask(with: req) { data, response, error in
            if let error = error { return completion(.failure(error)) }
            
            if let http = response as? HTTPURLResponse, !(200...299).contains(http.statusCode) {
                let snippet: String = {
                    guard let data, let s = String(data: data, encoding: .utf8) else { return "" }
                    let pref = s.prefix(200)
                    return String(pref) + (s.count > 200 ? "…" : "")
                }()
                let err = NSError(domain: "ChatServiceHTTP", code: http.statusCode,
                                  userInfo: [NSLocalizedDescriptionKey: "HTTP \(http.statusCode). Ответ: \(snippet)"])
                return completion(.failure(err))
            }
            
            guard let data = data else {
                return completion(.failure(NSError(domain: "ChatServiceHTTP", code: -1,
                                                   userInfo: [NSLocalizedDescriptionKey: "Empty response"])) )
            }

            let raw = String(data: data, encoding: .utf8)
            
            if let resp = try? JSONDecoder().decode(Resp.self, from: data) {
                var results = resp.results
                var message = resp.message
                
                if (results == nil || results!.isEmpty),
                   let m = message,
                   let placesFromMessage = self.decodePlaces(fromJSONString: m) {
                    results = placesFromMessage
                    message = placesFromMessage.count == 1
                        ? placesFromMessage[0].name
                        : "Нашёл \(placesFromMessage.count) мест рядом"
                }
                
                if (results == nil || results!.isEmpty),
                   let places = self.decodePlaces(from: data) {
                    results = places
                    message = places.count == 1 ? places[0].name : "Нашёл \(places.count) мест рядом"
                }
                
                let finalMessage: String = {
                    if let m = message, !m.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty { return m }
                    if let r = results, !r.isEmpty {
                        return r.count == 1 ? r[0].name : "Нашёл \(r.count) мест рядом"
                    }
                    return "Готово"
                }()

                return completion(.success((finalMessage, results, raw)))
            }
            
            if let places = self.decodePlaces(from: data) {
                let title = places.count == 1 ? places[0].name : "Нашёл \(places.count) мест рядом"
                return completion(.success((title, places, raw)))
            }
            
            if let text = raw, !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty {
                return completion(.success((text, nil, raw)))
            }
            
            completion(.success(("Готово", nil, raw)))
        }.resume()
    }
}
