import UIKit

final class FormFieldView: UIView, UITextFieldDelegate {
    enum Kind { case text, secure }

    var onEditingChanged: ((String) -> Void)?

    private let titleLabel = UILabel()
    private let fieldBG = UIView()
    private let textField = UITextField()
    private let toggleSecure = UIButton(type: .system)

    private var kind: Kind = .text

    init(kind: Kind) {
        self.kind = kind
        super.init(frame: .zero)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    func setStyle(title: String, placeholder: String) {
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            .foregroundColor: UIColor.tertiaryLabel
        ])
    }

    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }

    private func build() {
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = DesignTokens.labelDim
        
        fieldBG.backgroundColor = .secondarySystemBackground
        fieldBG.layer.cornerRadius = DesignTokens.cornerPill
        fieldBG.layer.borderWidth = 0
        
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = .label
        textField.autocapitalizationType = .none
        textField.autocorrectionType = .no
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        textField.setContentHuggingPriority(.defaultLow, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        if kind == .secure {
            textField.isSecureTextEntry = true
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: "eye")
            cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 14, weight: .semibold)
            cfg.baseForegroundColor = .secondaryLabel
            cfg.baseForegroundColor = .secondaryLabel
            toggleSecure.configuration = cfg
            toggleSecure.addAction(UIAction { [weak self] _ in self?.togglePassword() }, for: .touchUpInside)
        } else {
            toggleSecure.isHidden = true
        }

        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        h.isLayoutMarginsRelativeArrangement = true
        h.layoutMargins = .init(top: 12, left: 14, bottom: 12, right: 14)
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .horizontal)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        textField.setContentHuggingPriority(.defaultHigh, for: .horizontal)
        textField.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        
        toggleSecure.setContentHuggingPriority(.required, for: .horizontal)
        toggleSecure.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggleSecure.widthAnchor.constraint(equalToConstant: 28).isActive = true
        toggleSecure.heightAnchor.constraint(equalToConstant: 28).isActive = true


        h.addArrangedSubview(textField)
        h.addArrangedSubview(spacer)
        h.addArrangedSubview(toggleSecure)

        addSubview(titleLabel)
        addSubview(fieldBG)
        addSubview(h)

        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldBG.translatesAutoresizingMaskIntoConstraints = false
        h.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),

            fieldBG.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            fieldBG.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldBG.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldBG.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),

            h.topAnchor.constraint(equalTo: fieldBG.topAnchor),
            h.leadingAnchor.constraint(equalTo: fieldBG.leadingAnchor),
            h.trailingAnchor.constraint(equalTo: fieldBG.trailingAnchor),
            h.bottomAnchor.constraint(equalTo: fieldBG.bottomAnchor),

            bottomAnchor.constraint(equalTo: fieldBG.bottomAnchor)
        ])
    }

    private func togglePassword() {
        textField.isSecureTextEntry.toggle()
        if var cfg = toggleSecure.configuration {
            cfg.image = UIImage(systemName: textField.isSecureTextEntry ? "eye" : "eye.slash")
            toggleSecure.configuration = cfg
        }
    }

    @objc private func editingChanged() { onEditingChanged?(textField.text ?? "") }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool { textField.resignFirstResponder(); return true }
}
