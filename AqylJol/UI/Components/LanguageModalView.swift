import UIKit

final class LanguageModalView: UIView {
    // MARK: - Callbacks
    var onCancel: (() -> Void)?
    var onSubmit: ((AppLanguage) -> Void)?

    // MARK: - State
    private var selected: AppLanguage = {
        if let code = UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String,
           let lang = AppLanguage(rawValue: code) { return lang }
        return .russian
    }()

    // MARK: - UI
    private let container = UIStackView()
    private let headerH = UIStackView()
    private let titleLabel = UILabel()
    private let rowsStack = UIStackView()
    private let actionsH = UIStackView()

    private var rowViews: [LanguageOptionRow] = []

    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setupView()
        buildHeader()
        buildRows()
        buildActions()
        updateSelectionUI(animated: false)
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}

// MARK: - Setup & Layout
private extension LanguageModalView {
    func setupView() {
        backgroundColor = .systemBackground
        layer.cornerRadius = DesignTokens.cornerXL
        layer.borderColor = UIColor.separator.cgColor
        layer.borderWidth = 1
        layer.masksToBounds = true
        
        container.axis = .vertical
        container.alignment = .fill
        container.spacing = 16
        container.isLayoutMarginsRelativeArrangement = true
        container.layoutMargins = .init(top: 20, left: 20, bottom: 20, right: 20)
        
        addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: topAnchor),
            container.leadingAnchor.constraint(equalTo: leadingAnchor),
            container.trailingAnchor.constraint(equalTo: trailingAnchor),
            container.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
    }
    
    func buildHeader() {
        headerH.axis = .horizontal
        headerH.alignment = .center
        headerH.distribution = .fill
        headerH.spacing = 12
        
        titleLabel.text = "settings.language".localize()
        titleLabel.font = UIFont.preferredFont(forTextStyle: .headline)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        
        let close = UIButton(type: .system)
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "xmark")
        cfg.baseForegroundColor = .label
        cfg.contentInsets = .init(top: 6, leading: 6, bottom: 6, trailing: 6)
        close.configuration = cfg
        close.addAction(UIAction { [weak self] _ in
            self?.onCancel?()
        }, for: .touchUpInside)
        
        headerH.addArrangedSubview(titleLabel)
        headerH.addArrangedSubview(UIView())
        headerH.addArrangedSubview(close)
        
        container.addArrangedSubview(headerH)
    }
    
    func buildRows() {
        rowsStack.axis = .vertical
        rowsStack.spacing = 8
        
        let order: [AppLanguage] = [.russian, .kazakh, .english]
        order.forEach { lang in
            let row = LanguageOptionRow(lang: lang)
            row.addTarget(self, action: #selector(didTapRow(_:)), for: .touchUpInside)
            rowsStack.addArrangedSubview(row)
            rowViews.append(row)
        }
        
        container.addArrangedSubview(rowsStack)
    }
    
    func buildActions() {
        actionsH.axis = .horizontal
        actionsH.spacing = 12
        actionsH.distribution = .fillEqually
        
        let cancel = makeOutlinedButton(title: "cancel".localize())
        cancel.addAction(UIAction { [weak self] _ in
            self?.onCancel?()
        }, for: .touchUpInside)
        
        let submit = makeFilledNeonButton(title: "submit".localize())
        submit.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            UserDefaults.standard.set([self.selected.rawValue], forKey: "AppleLanguages")
            UserDefaults.standard.synchronize()
            self.onSubmit?(self.selected)
        }, for: .touchUpInside)
        
        actionsH.addArrangedSubview(cancel)
        actionsH.addArrangedSubview(submit)
        container.addArrangedSubview(actionsH)
    }
}

// MARK: - Actions
private extension LanguageModalView {
    @objc func didTapRow(_ sender: LanguageOptionRow) {
        guard selected != sender.lang else { return }
        selected = sender.lang
        updateSelectionUI(animated: true)
    }
    
    func updateSelectionUI(animated: Bool) {
        for row in rowViews {
            row.setSelected(row.lang == selected, animated: animated)
        }
    }
    
    func makeOutlinedButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        var cfg = UIButton.Configuration.bordered()
        cfg.title = title
        cfg.baseForegroundColor = UIColor.label
        cfg.background.backgroundColor = .tertiarySystemBackground
        cfg.background.strokeColor = .separator
        cfg.background.strokeWidth = 1
        cfg.cornerStyle = .capsule
        cfg.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        button.configuration = cfg
        button.isEnabled = true
        return button
    }
    
    func makeFilledNeonButton(title: String) -> UIButton {
        let button = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.title = title
        cfg.baseBackgroundColor = DesignTokens.neon2
        cfg.baseForegroundColor = DesignTokens.neon3
        cfg.cornerStyle = .capsule
        cfg.contentInsets = .init(top: 12, leading: 18, bottom: 12, trailing: 18)
        button.configuration = cfg
        button.isEnabled = true
        return button
    }
}

// MARK: - Row View
private final class LanguageOptionRow: UIControl {
    let lang: AppLanguage
    
    private let bg = UIView()
    private let check = UIImageView()
    private let codePill = PaddingLabel(insets: .init(top: 4, left: 8, bottom: 4, right: 8))
    private let titleLabel = UILabel()
    
    init(lang: AppLanguage) {
        self.lang = lang
        super.init(frame: .zero)
        isAccessibilityElement = true
        accessibilityTraits = [.button]
        build()
        setSelected(false, animated: false)
    }
    
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func build() {
        addSubview(bg)
        bg.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            bg.topAnchor.constraint(equalTo: topAnchor),
            bg.leadingAnchor.constraint(equalTo: leadingAnchor),
            bg.trailingAnchor.constraint(equalTo: trailingAnchor),
            bg.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        bg.backgroundColor = .secondarySystemBackground
        bg.layer.cornerRadius = 14
        bg.layer.borderColor = UIColor.separator.cgColor
        bg.layer.borderWidth = 1
        bg.isUserInteractionEnabled = false
        
        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        h.isLayoutMarginsRelativeArrangement = true
        h.layoutMargins = .init(top: 14, left: 14, bottom: 14, right: 14)
        h.isUserInteractionEnabled = false
        
        addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: topAnchor),
            h.leadingAnchor.constraint(equalTo: leadingAnchor),
            h.trailingAnchor.constraint(equalTo: trailingAnchor),
            h.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        check.contentMode = .scaleAspectFit
        check.setContentHuggingPriority(.required, for: .horizontal)
        check.setContentCompressionResistancePriority(.required, for: .horizontal)
        check.isUserInteractionEnabled = false
        
        codePill.text = lang.codePill
        codePill.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        codePill.textColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .black : .white
        }
        codePill.backgroundColor = UIColor { trait in
            trait.userInterfaceStyle == .dark ? .systemGray5 : .label
        }
        codePill.layer.cornerRadius = 9
        codePill.layer.masksToBounds = true
        codePill.setContentHuggingPriority(.required, for: .horizontal)
        codePill.isUserInteractionEnabled = false
        
        titleLabel.text = lang.displayName
        titleLabel.font = UIFont.preferredFont(forTextStyle: .body)
        titleLabel.adjustsFontForContentSizeCategory = true
        titleLabel.textColor = .label
        titleLabel.isUserInteractionEnabled = false
        
        h.addArrangedSubview(check)
        h.addArrangedSubview(codePill)
        h.addArrangedSubview(titleLabel)
        h.addArrangedSubview(UIView())
        
        addInteraction(UIPointerInteraction(delegate: self))
        
        heightAnchor.constraint(greaterThanOrEqualToConstant: 52).isActive = true
        
        addTarget(self, action: #selector(primaryAction), for: .primaryActionTriggered)
    }
    
    @objc private func primaryAction() {
        sendActions(for: .touchUpInside)
    }
    
    func setSelected(_ selected: Bool, animated: Bool) {
        let updates = {
            self.check.image = UIImage(systemName: selected ? "checkmark.circle.fill" : "circle")
            self.check.tintColor = selected ? DesignTokens.neon : DesignTokens.labelFaint
            self.bg.layer.borderColor = (selected ? DesignTokens.neon.cgColor : UIColor.separator.cgColor)
            self.bg.backgroundColor = selected ? UIColor.tertiarySystemBackground : UIColor.secondarySystemBackground
        }
        if animated { UIView.animate(withDuration: 0.18, animations: updates) } else { updates() }
        accessibilityValue = selected ? "selected" : "not selected"
    }
}

// MARK: - Pointer
extension LanguageOptionRow: UIPointerInteractionDelegate {
    func pointerInteraction(_ interaction: UIPointerInteraction, styleFor region: UIPointerRegion) -> UIPointerStyle? {
        UIPointerStyle(effect: .highlight(UITargetedPreview(view: self)))
    }
}

// MARK: - Helpers
private extension AppLanguage {
    var codePill: String { switch self { case .russian: return "RU"; case .kazakh: return "KK"; case .english: return "EN" } }
}
