import UIKit

final class VoiceListeningViewController: UIViewController {
    private let titleLabel = UILabel()
    private let dot = UIView()
    private let blur = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    
    private let speech = SpeechInputManager(locale: Locale(identifier: "ru-RU"))
    private var pauseWork: DispatchWorkItem?
    private let pauseTimeout: TimeInterval = 1.0
    private var heardSomething = false
    private var lastText: String = ""
    
    var onFinish: ((String) -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        view.addSubview(blur)
        blur.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blur.topAnchor.constraint(equalTo: view.topAnchor),
            blur.bottomAnchor.constraint(equalTo: view.bottomAnchor),
            blur.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            blur.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        let card = UIView()
        card.backgroundColor = UIColor.black.withAlphaComponent(0.45)
        card.layer.cornerRadius = 16
        card.layer.masksToBounds = true
        view.addSubview(card)
        card.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            card.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            card.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            card.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            card.heightAnchor.constraint(greaterThanOrEqualToConstant: 56)
        ])
        
        dot.backgroundColor = .systemRed
        dot.layer.cornerRadius = 6
        dot.translatesAutoresizingMaskIntoConstraints = false
        dot.widthAnchor.constraint(equalToConstant: 12).isActive = true
        dot.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        titleLabel.text = "voice.listening".localize()
        titleLabel.textColor = .white
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        
        let stack = UIStackView(arrangedSubviews: [dot, titleLabel, UIView()])
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 10
        card.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: card.topAnchor, constant: 10),
            stack.bottomAnchor.constraint(equalTo: card.bottomAnchor, constant: -10),
            stack.leadingAnchor.constraint(equalTo: card.leadingAnchor, constant: 14),
            stack.trailingAnchor.constraint(equalTo: card.trailingAnchor, constant: -14)
        ])
        
        animateDot()
        
        speech.onPartialText = { [weak self] text in
            guard let self else { return }
            self.heardSomething = self.heardSomething || !text.trimmingCharacters(in: .whitespaces).isEmpty
            self.lastText = text
            self.resetPauseTimer()
        }
        speech.onFinalText = { [weak self] text in
            guard let self else { return }
            self.lastText = text
            self.finishNow()
        }
        speech.onError = { [weak self] _ in
            self?.finishNow()
        }
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        speech.start()
        resetPauseTimer()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        speech.stop()
        pauseWork?.cancel()
    }
    
    private func animateDot() {
        dot.alpha = 1
        UIView.animate(withDuration: 0.9, delay: 0, options: [.autoreverse, .repeat, .allowUserInteraction]) {
            self.dot.alpha = 0.35
        }
    }
    
    private func resetPauseTimer() {
        pauseWork?.cancel()
        let work = DispatchWorkItem { [weak self] in self?.finishNow() }
        pauseWork = work
        let initial = heardSomething ? pauseTimeout : 3.0
        DispatchQueue.main.asyncAfter(deadline: .now() + initial, execute: work)
    }
    
    private func finishNow() {
        speech.stop()
        pauseWork?.cancel()
        onFinish?(heardSomething ? lastText : "")
    }
}
