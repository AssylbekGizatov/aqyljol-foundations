import Foundation
import Speech
import AVFoundation

final class SpeechInputManager {
    // MARK: - Public output
    var onPartialText: ((String) -> Void)?
    var onFinalText: ((String) -> Void)?
    var onError: ((Error) -> Void)?
    
    // MARK: - State
    private(set) var isRecording = false
    private let recognizer: SFSpeechRecognizer
    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?
    
    // MARK: - Init
    init(locale: Locale = Locale(identifier: Locale.preferredLanguages.first ?? "ru-RU")) {
        guard let r = SFSpeechRecognizer(locale: locale) else {
            recognizer = SFSpeechRecognizer()!
            return
        }
        recognizer = r
    }
    
    // MARK: - Public control
    func start() {
        guard !isRecording else { return }
        requestPermissions { [weak self] granted in
            guard let self, granted else { return }
            DispatchQueue.main.async { self.beginSession() }
        }
    }
    
    func stop() {
        guard isRecording else { return }
        isRecording = false
        
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        
        request?.endAudio()
        task?.cancel()
        task = nil
        request = nil
        
        try? AVAudioSession.sharedInstance()
            .setActive(false, options: [.notifyOthersOnDeactivation])
    }
    
    // MARK: - Permissions
    private func requestPermissions(completion: @escaping (Bool) -> Void) {
        SFSpeechRecognizer.requestAuthorization { speechStatus in
            guard speechStatus == .authorized else {
                completion(false); return
            }
            AVAudioSession.sharedInstance().requestRecordPermission { micOK in
                completion(micOK)
            }
        }
    }
    
    // MARK: - Session
    private func beginSession() {
        do {
            let session = AVAudioSession.sharedInstance()
            try session.setCategory(.record, mode: .measurement, options: [.duckOthers])
            try session.setActive(true, options: [.notifyOthersOnDeactivation])
        } catch {
            onError?(error); return
        }
        
        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        request = req
        
        let input = audioEngine.inputNode
        let format = input.outputFormat(forBus: 0)
        input.removeTap(onBus: 0)
        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.request?.append(buffer)
        }
        
        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            onError?(error); cleanupAudio(); return
        }
        
        isRecording = true
        
        task = recognizer.recognitionTask(with: req) { [weak self] result, error in
            guard let self else { return }
            if let r = result {
                let text = r.bestTranscription.formattedString
                if r.isFinal { self.onFinalText?(text) }
                else { self.onPartialText?(text) }
            }
            if let error = error {
                self.onError?(error)
                self.stop()
            } else if result?.isFinal == true {
                self.stop()
            }
        }
    }
    
    private func cleanupAudio() {
        audioEngine.inputNode.removeTap(onBus: 0)
        audioEngine.stop()
        request = nil
        task = nil
        isRecording = false
    }
}
