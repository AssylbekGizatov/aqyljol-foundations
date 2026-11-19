import UIKit

final class ChatInputBar: UIView, UITextViewDelegate {

    // MARK: Output
    var onSend: ((String) -> Void)?

    // MARK: UI
    private let bgView = UIView()
    private let topSeparator = UIView()
    private let textView = UITextView()
    private let placeholderLabel = UILabel()
    private let sendBtn = UIButton(type: .system)

    // MARK: State
    private var isBusy = false
    private var textHeightC: NSLayoutConstraint!
    
    private let minTextHeight: CGFloat = 36
    private lazy var maxTextHeight: CGFloat = {
        let lh = textView.font?.lineHeight ?? 17
        return ceil(lh * 4 + textView.textContainerInset.top + textView.textContainerInset.bottom)
    }()

    // MARK: Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    override var intrinsicContentSize: CGSize {
        CGSize(width: UIView.noIntrinsicMetric, height: minTextHeight + 16)
    }

    // MARK: Public
    func setBusy(_ busy: Bool) {
        isBusy = busy
        setSendEnabled(!busy && hasText)
        if var cfg = sendBtn.configuration {
            cfg.image = UIImage(systemName: busy ? "hourglass" : "paperplane.fill")
            sendBtn.configuration = cfg
        } else {
            sendBtn.setImage(UIImage(systemName: busy ? "hourglass" : "paperplane.fill"), for: .normal)
        }
    }

    func refreshLocalization() {
        placeholderLabel.text = "chat.input.placeholder".localize()
    }

    // MARK: Build UI
    private func build() {
        backgroundColor = .clear
        
        bgView.backgroundColor = .tertiarySystemBackground
        addSubview(bgView)
        bgView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bgView.topAnchor.constraint(equalTo: topAnchor),
            bgView.leadingAnchor.constraint(equalTo: leadingAnchor),
            bgView.trailingAnchor.constraint(equalTo: trailingAnchor),
            bgView.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])

        topSeparator.backgroundColor = UIColor.separator.withAlphaComponent(0.6)
        addSubview(topSeparator)
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor),
            topSeparator.heightAnchor.constraint(equalToConstant: 0.5)
        ])
        
        textView.backgroundColor = .secondarySystemBackground
        textView.layer.cornerRadius = 18
        textView.textContainerInset = .init(top: 8, left: 12, bottom: 8, right: 12)
        textView.font = .systemFont(ofSize: 16)
        textView.delegate = self
        textView.isScrollEnabled = false
        textView.returnKeyType = .default
        textView.textAlignment = .natural
        textView.tintColor = .label
        
        textView.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textView.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        sendBtn.setContentHuggingPriority(.required, for: .horizontal)
        sendBtn.setContentCompressionResistancePriority(.required, for: .horizontal)

        placeholderLabel.textColor = .placeholderText
        placeholderLabel.font = textView.font
        placeholderLabel.numberOfLines = 1

        addSubview(textView)
        textView.addSubview(placeholderLabel)
        textView.translatesAutoresizingMaskIntoConstraints = false
        placeholderLabel.translatesAutoresizingMaskIntoConstraints = false
        
        var cfg = UIButton.Configuration.filled()
        cfg.image = UIImage(systemName: "paperplane.fill")
        cfg.cornerStyle = .capsule
        cfg.contentInsets = .init(top: 8, leading: 10, bottom: 8, trailing: 10)
        sendBtn.configuration = cfg
        sendBtn.tintColor = .white
        sendBtn.addTarget(self, action: #selector(sendTapped), for: .touchUpInside)
        setSendEnabled(false)
        addSubview(sendBtn)
        sendBtn.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            
            sendBtn.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -10),
            sendBtn.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            textView.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 10),
            textView.trailingAnchor.constraint(equalTo: sendBtn.leadingAnchor, constant: -8),
            textView.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -8),
            
            textView.topAnchor.constraint(greaterThanOrEqualTo: topSeparator.bottomAnchor, constant: 8),
        ])

        textHeightC = textView.heightAnchor.constraint(equalToConstant: minTextHeight)
        textHeightC.isActive = true

        // placeholder по инсетам текствью
        NSLayoutConstraint.activate([
            placeholderLabel.leadingAnchor.constraint(equalTo: textView.leadingAnchor, constant: textView.textContainerInset.left + 2),
            placeholderLabel.trailingAnchor.constraint(lessThanOrEqualTo: textView.trailingAnchor, constant: -(textView.textContainerInset.right)),
            placeholderLabel.topAnchor.constraint(equalTo: textView.topAnchor, constant: textView.textContainerInset.top)
        ])

        refreshLocalization()
    }

    // MARK: Helpers
    private var hasText: Bool {
        !(textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }
    private func setSendEnabled(_ on: Bool) {
        sendBtn.isEnabled = on
        sendBtn.alpha = on ? 1 : 0.5
    }

    @objc private func sendTapped() {
        let text = (textView.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty else { return }
        onSend?(text)
        textView.text = nil
        textViewDidChange(textView)
    }

    // MARK: UITextViewDelegate
    func textViewDidChange(_ tv: UITextView) {
        placeholderLabel.isHidden = !tv.text.isEmpty
        if !isBusy { setSendEnabled(hasText) }
        updateTextHeight()
    }
    func textViewDidBeginEditing(_ tv: UITextView) { updateTextHeight() }

    private func updateTextHeight() {
        let w = max(0, textView.bounds.width)
        let needed = textView.sizeThatFits(CGSize(width: w, height: .greatestFiniteMagnitude)).height
        let clamped = min(max(minTextHeight, needed), maxTextHeight)

        if abs(textHeightC.constant - clamped) > 0.5 {
            textHeightC.constant = clamped
            textView.isScrollEnabled = needed > maxTextHeight + 1
            invalidateIntrinsicContentSize()
            setNeedsLayout()
            layoutIfNeeded()
        } else {
            textView.isScrollEnabled = needed > maxTextHeight + 1
        }
    }
}
