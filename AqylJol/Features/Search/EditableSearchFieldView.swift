import UIKit

final class EditableSearchFieldView: UIControl, UITextFieldDelegate {
    let textField = UITextField()
    private let iconImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let micButton = UIButton(type: .system)
    private let clearButton = UIButton(type: .system)
    private let stack = UIStackView()
    
    var onMicTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setup() {
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 14
        
        textField.borderStyle = .none
        textField.clearButtonMode = .never
        textField.returnKeyType = .search
        textField.delegate = self
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        var micCfg = UIButton.Configuration.plain()
        micCfg.image = UIImage(systemName: "mic.fill")
        micCfg.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        micButton.configuration = micCfg
        micButton.tintColor = .label
        micButton.setContentHuggingPriority(.required, for: .horizontal)
        micButton.addAction(UIAction { [weak self] _ in self?.onMicTap?() }, for: .touchUpInside)
        
        var clearCfg = UIButton.Configuration.plain()
        clearCfg.image = UIImage(systemName: "xmark.circle.fill")
        clearCfg.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        clearButton.configuration = clearCfg
        clearButton.tintColor = .secondaryLabel
        clearButton.setContentHuggingPriority(.required, for: .horizontal)
        clearButton.isHidden = true
        clearButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.textField.text = ""
            self.textField.sendActions(for: .editingChanged)
            self.textField.becomeFirstResponder()
        }, for: .touchUpInside)
        
        iconImageView.tintColor = .secondaryLabel
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        stack.axis = .horizontal
        stack.alignment = .center
        stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = .init(top: 6, left: 8, bottom: 6, right: 8)
        
        stack.addArrangedSubview(iconImageView)
        stack.addArrangedSubview(textField)
        stack.addArrangedSubview(clearButton)
        stack.addArrangedSubview(micButton)
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        addTarget(self, action: #selector(focus), for: .touchUpInside)
    }
    
    func updateRightButtons(forText text: String) {
        let empty = text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        micButton.isHidden = !empty
        clearButton.isHidden = empty
    }
    
    @objc private func focus() { textField.becomeFirstResponder() }
}
