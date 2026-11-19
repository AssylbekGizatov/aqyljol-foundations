import UIKit

final class TabBarOverlayView: UIView {
    // MARK: - Public types
    enum Mode { case primary, info }
    enum Item: CaseIterable {
        case search, chats, profile
        case route, favorite, share
    }
    
    // MARK: - Public API
    var onSelect: ((Item) -> Void)?
    
    func setSelected(_ item: Item) {
        guard mode == .primary else { return }
        guard selectedItem != item else { return }
        selectedItem = item
        updateSelectionAppearance()
        animateSelectionPulse()
    }
    
    var mode: Mode = .primary { didSet { rebuildForMode() } }
    
    // MARK: - UI
    private let blurView = UIVisualEffectView(effect: UIBlurEffect(style: .systemUltraThinMaterialDark))
    private let topSeparator = UIView()
    private let stack = UIStackView()
    
    // MARK: - State
    private var buttons: [Item: UIButton] = [:]
    private var selectedItem: Item = .search
    private var stackBottomConstraint: NSLayoutConstraint?
    
    // MARK: - Style
    private let inactiveTint = UIColor.white.withAlphaComponent(0.78)
    private let activeTint   = UIColor(displayP3Red: 0.22, green: 0.76, blue: 1.00, alpha: 1.0) // neon
    private let activeTintDeep = UIColor(displayP3Red: 0.12, green: 0.48, blue: 1.00, alpha: 1.0)
    
    // MARK: - Init
    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    // MARK: - Setup
    private func setup() {
        backgroundColor = .clear
        layer.cornerRadius = 0
        layer.masksToBounds = true
        
        addSubview(blurView)
        blurView.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            blurView.topAnchor.constraint(equalTo: topAnchor),
            blurView.bottomAnchor.constraint(equalTo: bottomAnchor),
            blurView.leadingAnchor.constraint(equalTo: leadingAnchor),
            blurView.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        topSeparator.backgroundColor = UIColor.white.withAlphaComponent(0.15)
        addSubview(topSeparator)
        topSeparator.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            topSeparator.heightAnchor.constraint(equalToConstant: 0.5),
            topSeparator.topAnchor.constraint(equalTo: topAnchor),
            topSeparator.leadingAnchor.constraint(equalTo: leadingAnchor),
            topSeparator.trailingAnchor.constraint(equalTo: trailingAnchor)
        ])
        
        stack.axis = .horizontal
        stack.alignment = .fill
        stack.distribution = .fillEqually
        stack.spacing = 8
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: topAnchor, constant: 4),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -12)
        ])
        let sb = stack.bottomAnchor.constraint(equalTo: bottomAnchor, constant: -4)
        sb.isActive = true
        stackBottomConstraint = sb
        
        buildButtons()
        updateSelectionAppearance()
    }
    
    // MARK: - Mode/Items
    private func itemsForCurrentMode() -> [(title: String, symbol: String, item: Item)] {
        switch mode {
        case .primary:
            return [
                ("search.placeholder", "magnifyingglass",                   .search),
                ("chat.tabbar",  "bubble.left.and.bubble.right.fill", .chats),
                ("profile.title", "person.crop.circle", .profile)
            ]
        case .info:
            return [
                ("route.sheet.title",   "arrow.turn.up.right", .route),
                ("favorities", "star.fill",           .favorite),
                ("share","square.and.arrow.up", .share)
            ]
        }
    }
    
    private func rebuildForMode() {
        stack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        buttons.removeAll()
        if mode == .primary {
            selectedItem = .search
        }
        buildButtons()
        updateSelectionAppearance()
    }
    
    private func buildButtons() {
        for def in itemsForCurrentMode() {
            let b = makeVerticalIconButton(title: def.title.localize(), systemSymbol: def.symbol)
            if let idx = Item.allCases.firstIndex(of: def.item) { b.tag = idx }
            b.addAction(UIAction { [weak self] _ in
                guard let self else { return }
                let idx = b.tag
                guard Item.allCases.indices.contains(idx) else { return }
                let it = Item.allCases[idx]
                if self.mode == .primary { self.setSelected(it) }
                self.onSelect?(it)
            }, for: .touchUpInside)
            
            stack.addArrangedSubview(b)
            buttons[def.item] = b
        }
    }
    
    // MARK: - Safe area
    override func safeAreaInsetsDidChange() {
        super.safeAreaInsetsDidChange()
        let capped = min(max(0, safeAreaInsets.bottom), 10)
        stackBottomConstraint?.constant = -(4 + capped)
    }
    
    // MARK: - Button factory & styling
    private func makeVerticalIconButton(title: String, systemSymbol: String) -> UIButton {
        let b = UIButton(type: .system)
        
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: systemSymbol)
        cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        cfg.imagePlacement = .top
        cfg.imagePadding = 6
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 8, leading: 10, bottom: 8, trailing: 10)
        
        var titleAttr = AttributedString(title)
        titleAttr.font = .systemFont(ofSize: 12, weight: .semibold)
        cfg.attributedTitle = titleAttr
        
        b.configuration = cfg
        b.tintColor = inactiveTint
        b.backgroundColor = .clear
        b.heightAnchor.constraint(greaterThanOrEqualToConstant: 40).isActive = true
        
        b.layer.shadowColor = activeTintDeep.cgColor
        b.layer.shadowOffset = .zero
        b.layer.shadowRadius = 12
        b.layer.shadowOpacity = 0
        
        b.addTarget(self, action: #selector(touchDown(_:)), for: [.touchDown])
        b.addTarget(self, action: #selector(touchUp(_:)),   for: [.touchUpInside, .touchCancel, .touchDragExit])
        
        return b
    }
    
    private func updateSelectionAppearance() {
        guard mode == .primary else {
            buttons.values.forEach { btn in
                btn.tintColor = inactiveTint
                if var cfg = btn.configuration, var title = cfg.attributedTitle {
                    title.foregroundColor = inactiveTint
                    cfg.attributedTitle = title
                    btn.configuration = cfg
                }
                btn.layer.shadowOpacity = 0
            }
            return
        }
        
        for (it, button) in buttons {
            let active = (it == selectedItem)
            let tint = active ? activeTint : inactiveTint
            
            button.tintColor = tint
            if var cfg = button.configuration, var title = cfg.attributedTitle {
                title.foregroundColor = tint
                cfg.attributedTitle = title
                button.configuration = cfg
            }
            
            button.layer.shadowOpacity = active ? 0.9 : 0.0
        }
    }
    
    private func animateSelectionPulse() {
        guard let btn = buttons[selectedItem] else { return }
        UIView.animate(withDuration: 0.16, animations: {
            btn.alpha = 0.7
        }) { _ in
            UIView.animate(withDuration: 0.25) {
                btn.alpha = 1.0
            }
        }
    }
    
    // MARK: - Subtle highlight
    @objc private func touchDown(_ sender: UIButton) {
        sender.layer.shadowOpacity = 0.9
        sender.tintColor = activeTint
        if var cfg = sender.configuration, var title = cfg.attributedTitle {
            title.foregroundColor = activeTint
            cfg.attributedTitle = title
            sender.configuration = cfg
        }
        UIView.animate(withDuration: 0.10) { sender.alpha = 0.85 }
    }
    
    @objc private func touchUp(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) { sender.alpha = 1.0 }
        
        if mode == .primary {
            let it = Item.allCases[sender.tag]
            let isActive = (it == selectedItem)
            sender.layer.shadowOpacity = isActive ? 0.9 : 0.0
            let tint = isActive ? activeTint : inactiveTint
            sender.tintColor = tint
            if var cfg = sender.configuration, var title = cfg.attributedTitle {
                title.foregroundColor = tint
                cfg.attributedTitle = title
                sender.configuration = cfg
            }
        } else {
            sender.layer.shadowOpacity = 0.0
            sender.tintColor = inactiveTint
            if var cfg = sender.configuration, var title = cfg.attributedTitle {
                title.foregroundColor = inactiveTint
                cfg.attributedTitle = title
                sender.configuration = cfg
            }
        }
    }
}

extension TabBarOverlayView {
    func refreshLocalization() {
        for (item, button) in buttons {
            let key: String
            switch (mode, item) {
            case (.primary, .search):   key = "search.placeholder"
            case (.primary, .chats):    key = "chat.tabbar"
            case (.primary, .profile):  key = "profile.title"
            case (.info,    .route):    key = "route.sheet.title"
            case (.info,    .favorite): key = "favorities"
            case (.info,    .share):    key = "share"
            default: continue
            }
            
            var cfg = button.configuration ?? .plain()
            var title = AttributedString(key.localize())
            title.font = .systemFont(ofSize: 12, weight: .semibold)
            cfg.attributedTitle = title
            button.configuration = cfg
        }
        updateSelectionAppearance()
        setNeedsLayout()
        layoutIfNeeded()
    }
}
