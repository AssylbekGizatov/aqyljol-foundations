import UIKit

final class ProfileRowView: UIControl {
    var onToggleChanged: ((Bool) -> Void)?
    
    private let iconCircle = UIView()
    private let iconView   = UIImageView()
    private let titleLabel = UILabel()
    private let detailLabel = UILabel()
    private let toggle = UISwitch()
    private let chevron = UIImageView(image: UIImage(systemName: "chevron.right"))
    private let hStack = UIStackView()
    
    private var kindStored: ProfileRowKind!
    
    private var isDarkRow = false
    
    init(kind: ProfileRowKind) {
        super.init(frame: .zero)
        setup(kind: kind)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    private func setup(kind: ProfileRowKind) {
        self.kindStored = kind
        
        layer.cornerRadius = DesignTokens.cornerPill
        layer.borderWidth = 0
        
        iconCircle.backgroundColor = DesignTokens.neon.withAlphaComponent(0.12)
        iconCircle.layer.cornerRadius = 22
        iconCircle.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.widthAnchor.constraint(equalToConstant: 44).isActive = true
        iconCircle.heightAnchor.constraint(equalToConstant: 44).isActive = true
        
        iconView.image = UIImage(systemName: kind.iconName)
        iconView.tintColor = DesignTokens.neon
        iconView.contentMode = .scaleAspectFit
        iconView.translatesAutoresizingMaskIntoConstraints = false
        iconCircle.addSubview(iconView)
        NSLayoutConstraint.activate([
            iconView.centerXAnchor.constraint(equalTo: iconCircle.centerXAnchor),
            iconView.centerYAnchor.constraint(equalTo: iconCircle.centerYAnchor),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
        
        titleLabel.text = kind.title
        titleLabel.font = .systemFont(ofSize: 16, weight: .semibold)
        titleLabel.setContentHuggingPriority(.defaultLow, for: .horizontal)
        
        detailLabel.text = kind.trailingDetail
        detailLabel.textColor = .secondaryLabel
        detailLabel.font = .systemFont(ofSize: 14)
        detailLabel.textAlignment = .right
        detailLabel.isHidden = (kind.trailingDetail == nil)
        
        toggle.isOn = kind.initialSwitchOn
        toggle.isHidden = !kind.showsSwitch
        toggle.onTintColor = DesignTokens.neon2
        toggle.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onToggleChanged?(self.toggle.isOn)
        }, for: .valueChanged)
        
        chevron.tintColor = .tertiaryLabel
        chevron.isHidden = kind.showsSwitch || (kind.trailingDetail != nil)
        
        hStack.axis = .horizontal
        hStack.alignment = .center
        hStack.spacing = 12
        hStack.isLayoutMarginsRelativeArrangement = true
        hStack.layoutMargins = .init(top: DesignTokens.dockInset,
                                     left: DesignTokens.dockInset,
                                     bottom: DesignTokens.dockInset,
                                     right: DesignTokens.dockInset)
        
        hStack.addArrangedSubview(iconCircle)
        hStack.addArrangedSubview(titleLabel)
        hStack.addArrangedSubview(detailLabel)
        hStack.addArrangedSubview(toggle)
        hStack.addArrangedSubview(chevron)
        
        addSubview(hStack)
        hStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            hStack.topAnchor.constraint(equalTo: topAnchor),
            hStack.leadingAnchor.constraint(equalTo: leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: trailingAnchor),
            hStack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        detailLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        toggle.setContentHuggingPriority(.required, for: .horizontal)
        chevron.setContentHuggingPriority(.required, for: .horizontal)
        if case .darkMode = kind { isDarkRow = true }
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(rowTapped))
        addGestureRecognizer(tap)
        isUserInteractionEnabled = true
    }
    
    @objc private func rowTapped() { sendActions(for: .primaryActionTriggered) }
    
    func setDetailText(_ text: String?) {
        detailLabel.text = text
        detailLabel.isHidden = (text == nil)
        chevron.isHidden = false
    }
    func setTitleText(_ text: String) { titleLabel.text = text }
    
    func setDarkModeState(_ isOn: Bool) {
        guard isDarkRow else { return }
        toggle.setOn(isOn, animated: true)
        titleLabel.text = isOn ? "settings.dark".localize() : "settings.light".localize()
        iconView.image = UIImage(systemName: isOn ? "moon.fill" : "sun.max.fill")
        iconView.tintColor = DesignTokens.neon
        iconCircle.backgroundColor = DesignTokens.neon.withAlphaComponent(0.12)
    }
    
    func refreshLocalization() {
        guard let kind = kindStored else { return }
        switch kind {
        case .darkMode:
            setDarkModeState(toggle.isOn)
        default:
            titleLabel.text = kind.title
            iconView.image = UIImage(systemName: kind.iconName)
            iconView.tintColor = DesignTokens.neon
            iconCircle.backgroundColor = DesignTokens.neon.withAlphaComponent(0.12)
        }
        setNeedsLayout()
        layoutIfNeeded()
    }
    func setSwitchOn(_ isOn: Bool, animated: Bool = true) {
        guard !toggle.isHidden else { return }
        toggle.setOn(isOn, animated: animated)
    }
}
