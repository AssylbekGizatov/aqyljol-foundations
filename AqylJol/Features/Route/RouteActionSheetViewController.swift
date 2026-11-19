import UIKit
import DGis

// MARK: - Small UI helpers (pure styling)
private enum Neon {
    static let active  = UIColor(displayP3Red: 0.22, green: 0.76, blue: 1.00, alpha: 1.0) // #38C2FF
    static let activeDeep = UIColor(displayP3Red: 0.12, green: 0.48, blue: 1.00, alpha: 1.0)
    static let glass  = UIColor.white.withAlphaComponent(0.10)
    static let stroke = UIColor.white.withAlphaComponent(0.18)
    static let label  = UIColor.white.withAlphaComponent(0.90)
    static let faint  = UIColor.white.withAlphaComponent(0.65)
}

private final class PaddedField: UITextField {
    var inset = UIEdgeInsets(top: 10, left: 42, bottom: 10, right: 12)
    override func textRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
    override func editingRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
    override func placeholderRect(forBounds bounds: CGRect) -> CGRect { bounds.inset(by: inset) }
}

final class RouteActionSheetViewController: UIViewController, UITextFieldDelegate {
    
    enum Mode: CaseIterable { case car, truck, pedestrian }
    
    // MARK: — Callbacks (unchanged)
    var onClose: (() -> Void)?
    var onReverseTap: (() -> Void)?
    var onModeChanged: ((Mode) -> Void)?
    var onBuild: ((String?, String?, Mode) -> Void)?
    
    var initialFrom: String?
    var initialTo: String?
    
    var onStartTap: (() -> Void)?
    var onFinishTap: (() -> Void)?
    
    private(set) var startObject: DirectoryObject?
    private(set) var finishObject: DirectoryObject?
    var currentToText: String { toField.text ?? "" }
    var currentFromText: String { fromField.text ?? "" }
    
    // MARK: UI (same structure)
    private let closeButton   = UIButton(type: .system)
    private let reverseButton = UIButton(type: .system)
    private let fromField     = PaddedField()
    private let toField       = PaddedField()
    private let modesRow      = UIStackView()
    private let buildButton   = UIButton(type: .system)
    
    private var modeButtons: [Mode: UIButton] = [:]
    private var selectedMode: Mode = .car
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        setupHeader()
        setupFields()
        setupModes()
        setupBuildButton()
        layoutAll()
        
        fromField.text = initialFrom ?? "my_location".localize()
        toField.text   = initialTo
    }

    // MARK: - Public (unchanged logic)
    func setFrom(object: DirectoryObject) { startObject = object; fromField.text = object.title }
    public func setTo(object: DirectoryObject) { finishObject = object; toField.text = object.title }
    func setFromText(_ text: String) { startObject = nil; fromField.text = text }
    func setToText(_ text: String)   { finishObject = nil; toField.text   = text }

    func textFieldShouldBeginEditing(_ textField: UITextField) -> Bool {
        if textField === fromField { onStartTap?() }
        else if textField === toField { onFinishTap?() }
        return false
    }
    
    // MARK: - Header (kept layout, restyled buttons)
    private func setupHeader() {
        // Close (same as InfoViewController)
        var xcfg = UIButton.Configuration.plain()
        xcfg.image = UIImage(
            systemName: "xmark",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        xcfg.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        closeButton.configuration = xcfg
        closeButton.tintColor = .label
        closeButton.backgroundColor = .secondarySystemBackground
        closeButton.layer.cornerRadius = 8
        closeButton.layer.masksToBounds = true
        closeButton.addAction(UIAction { [weak self] _ in self?.onClose?() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])

        // Reverse (same chip style as close)
        var revCfg = UIButton.Configuration.plain()
        revCfg.image = UIImage(
            systemName: "arrow.up.arrow.down",
            withConfiguration: UIImage.SymbolConfiguration(pointSize: 12, weight: .semibold)
        )
        revCfg.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        reverseButton.configuration = revCfg
        reverseButton.tintColor = .label
        reverseButton.backgroundColor = .secondarySystemBackground
        reverseButton.layer.cornerRadius = 8
        reverseButton.layer.masksToBounds = true
        reverseButton.addAction(UIAction { [weak self] _ in self?.onReverseTap?() }, for: .touchUpInside)
        NSLayoutConstraint.activate([
            reverseButton.widthAnchor.constraint(equalToConstant: 32),
            reverseButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        let title = UILabel()
        title.font = .systemFont(ofSize: 20, weight: .semibold)
        title.textColor = .label
        title.text = "route.sheet.title".localize()
        
        let rightGroup = UIStackView(arrangedSubviews: [reverseButton, closeButton])
        rightGroup.axis = .horizontal
        rightGroup.spacing = 8
        rightGroup.alignment = .center
        
        let header = UIStackView(arrangedSubviews: [title, UIView(), rightGroup])
        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12)
        ])
    }
    
    // MARK: - Text Fields (design only)
    private func setupFields() {
        func styleField(_ tf: PaddedField, icon: String, placeholder: String) {
            tf.delegate = self
            let isLight = traitCollection.userInterfaceStyle != .dark

            tf.backgroundColor = isLight ? .secondarySystemBackground : Neon.glass
            tf.layer.cornerRadius = 12
            tf.layer.borderWidth  = 1
            tf.layer.borderColor  = (isLight ? UIColor.systemGray4 : Neon.stroke).cgColor
            tf.textColor = .label
            tf.tintColor = Neon.active
            tf.font = .systemFont(ofSize: 16, weight: .semibold)

            tf.attributedPlaceholder = NSAttributedString(
                string: placeholder,
                attributes: [.foregroundColor: isLight ? UIColor.secondaryLabel : Neon.faint]
            )

            let iv = UIImageView(image: UIImage(systemName: icon))
            iv.contentMode = .scaleAspectFit
            iv.tintColor = isLight ? UIColor.secondaryLabel : Neon.faint
            iv.frame = CGRect(x: 0, y: 0, width: 32, height: 20)
            let container = UIView(frame: CGRect(x: 0, y: 0, width: 38, height: 44))
            iv.center = CGPoint(x: 19, y: 22)
            container.addSubview(iv)
            tf.leftView = container
            tf.leftViewMode = .always

            tf.addTarget(self, action: #selector(fieldEditingBegan(_:)), for: .editingDidBegin)
            tf.addTarget(self, action: #selector(fieldEditingEnded(_:)), for: .editingDidEnd)
        }

        styleField(fromField, icon: "location.fill",      placeholder: "from".localize())
        styleField(toField,   icon: "mappin.and.ellipse", placeholder: "to".localize())
        fromField.text = "my_location".localize()
    }

    @objc private func fieldEditingBegan(_ tf: UITextField) {
        tf.layer.shadowColor = Neon.activeDeep.cgColor
        tf.layer.shadowRadius = 10
        tf.layer.shadowOpacity = 0.7
        tf.layer.shadowOffset = .zero
    }
    @objc private func fieldEditingEnded(_ tf: UITextField) {
        tf.layer.shadowOpacity = 0
    }
    
    override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
        super.traitCollectionDidChange(previousTraitCollection)
        setupFields()
    }
    // MARK: - Modes
    private func setupModes() {
        modesRow.axis = .horizontal
        modesRow.alignment = .fill
        modesRow.distribution = .fillEqually
        modesRow.spacing = 8

        func makeModeButton(_ mode: Mode, _ symbol: String) -> UIButton {
            let b = UIButton(type: .system)
            var cfg = UIButton.Configuration.plain()
            cfg.image = UIImage(systemName: symbol)
            cfg.preferredSymbolConfigurationForImage = .init(pointSize: 18, weight: .semibold)
            cfg.contentInsets = .init(top: 10, leading: 10, bottom: 10, trailing: 10)
            b.configuration = cfg

            let isLight = traitCollection.userInterfaceStyle != .dark
            b.tintColor = isLight ? .label : Neon.label
            b.backgroundColor = isLight ? .secondarySystemBackground : Neon.glass
            b.layer.cornerRadius = 12
            b.layer.borderWidth  = 1
            b.layer.borderColor  = (isLight ? UIColor.systemGray4 : Neon.stroke).cgColor

            b.layer.shadowColor = Neon.activeDeep.cgColor
            b.layer.shadowOffset = .zero
            b.layer.shadowRadius = 12
            b.layer.shadowOpacity = 0

            b.addTarget(self, action: #selector(modePressIn(_:)), for: .touchDown)
            b.addTarget(self, action: #selector(modePressOut(_:)), for: [.touchUpInside, .touchCancel, .touchDragExit])

            b.addAction(UIAction { [weak self] _ in self?.selectMode(mode) }, for: .touchUpInside)
            b.heightAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
            return b
        }
        
        [(Mode.car,"car.fill"), (Mode.truck,"box.truck.fill"), (Mode.pedestrian,"figure.walk")].forEach { m, s in
            let btn = makeModeButton(m, s)
            modesRow.addArrangedSubview(btn)
            modeButtons[m] = btn
        }
        
        selectMode(.car)
    }
    @objc private func modePressIn(_ sender: UIButton) {
        sender.layer.shadowOpacity = 0.9
        UIView.animate(withDuration: 0.10) { sender.alpha = 0.85 }
    }
    @objc private func modePressOut(_ sender: UIButton) {
        UIView.animate(withDuration: 0.12) { sender.alpha = 1.0 }
        sender.layer.shadowOpacity = 0.0
    }
    
    // MARK: - CTA
    private func setupBuildButton() {
        var cfg = UIButton.Configuration.filled()
        cfg.title = "route.go".localize()
        cfg.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        cfg.baseForegroundColor = .white
        
        buildButton.configuration = cfg
        buildButton.backgroundColor = .clear
        buildButton.layer.cornerRadius = 12
        buildButton.layer.masksToBounds = true
        
        buildButton.layer.shadowColor = Neon.activeDeep.cgColor
        buildButton.layer.shadowOpacity = 0.35
        buildButton.layer.shadowRadius = 12
        buildButton.layer.shadowOffset = CGSize(width: 0, height: 6)
        
        buildButton.setContentHuggingPriority(.required, for: .horizontal)
        buildButton.addAction(UIAction { [weak self] _ in
            guard let self else { return }
            self.onBuild?(self.fromField.text, self.toField.text, self.selectedMode)
        }, for: .touchUpInside)
    }
    
    // MARK: - Layout
    private func layoutAll() {
        let fieldsStack = UIStackView(arrangedSubviews: [fromField, toField])
        fieldsStack.axis = .vertical
        fieldsStack.spacing = 10
        fieldsStack.alignment = .fill
        
        let fieldsContainer = UIView()
        fieldsContainer.addSubview(fieldsStack)
        fieldsStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            fieldsStack.topAnchor.constraint(equalTo: fieldsContainer.topAnchor),
            fieldsStack.bottomAnchor.constraint(equalTo: fieldsContainer.bottomAnchor),
            fieldsStack.leadingAnchor.constraint(equalTo: fieldsContainer.leadingAnchor),
            fieldsStack.trailingAnchor.constraint(equalTo: fieldsContainer.trailingAnchor),
            
            fromField.heightAnchor.constraint(equalToConstant: 44),
            toField.heightAnchor.constraint(equalToConstant: 44)
        ])
        
        let root = UIStackView(arrangedSubviews: [fieldsContainer, modesRow, buildButton])
        root.axis = .vertical
        root.alignment = .center
        root.spacing = 12
        
        view.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 56),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            root.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -12),
            
            fieldsContainer.widthAnchor.constraint(equalTo: view.widthAnchor, multiplier: 0.85),
            buildButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 140),
            buildButton.widthAnchor.constraint(lessThanOrEqualTo: view.widthAnchor, multiplier: 0.5)
        ])
    }
    
    // MARK: - Mode selection
    private func selectMode(_ mode: Mode) {
        selectedMode = mode
        let isLight = traitCollection.userInterfaceStyle != .dark
        for (m, b) in modeButtons {
            if m == mode {
                b.tintColor = .white
                b.backgroundColor = Neon.active
                b.layer.borderColor = Neon.activeDeep.withAlphaComponent(0.4).cgColor
                b.layer.shadowOpacity = 0.6
            } else {
                b.tintColor = isLight ? .label : Neon.label
                b.backgroundColor = isLight ? .secondarySystemBackground : Neon.glass
                b.layer.borderColor = (isLight ? UIColor.systemGray4 : Neon.stroke).cgColor
                b.layer.shadowOpacity = 0.0
            }
        }
        onModeChanged?(mode)
    }
    
    func setFrom(text: String) { startObject = nil; fromField.text = text }
    func setTo(text: String) { finishObject = nil; toField.text   = text }
    
    func swapTextFields() {
        let from = currentFromText
        let to   = currentToText
        setFrom(text: to)
        setTo(text: from)
        swap(&self.startObject, &self.finishObject)
    }
    
    // MARK: - Gradient image
    private func makeGradientImage(size: CGSize, cornerRadius: CGFloat) -> UIImage? {
        guard size.width > 0, size.height > 0 else { return nil }
        let renderer = UIGraphicsImageRenderer(size: size)
        return renderer.image { ctx in
            let path = UIBezierPath(roundedRect: CGRect(origin: .zero, size: size),
                                    cornerRadius: cornerRadius)
            path.addClip()
            let gradient = CGGradient(colorsSpace: CGColorSpaceCreateDeviceRGB(),
                                      colors: [Neon.active.cgColor, Neon.activeDeep.cgColor] as CFArray,
                                      locations: [0, 1])!
            ctx.cgContext.drawLinearGradient(
                gradient,
                start: CGPoint(x: 0, y: size.height/2),
                end: CGPoint(x: size.width, y: size.height/2),
                options: []
            )
        }.resizableImage(withCapInsets: UIEdgeInsets(top: cornerRadius, left: cornerRadius,
                                                     bottom: cornerRadius, right: cornerRadius))
    }
    
    private var lastBuildButtonSize: CGSize = .zero
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let s = buildButton.bounds.size
        guard s != .zero, s != lastBuildButtonSize else { return }
        lastBuildButtonSize = s
        let img = makeGradientImage(size: s, cornerRadius: 12)
        buildButton.setBackgroundImage(img, for: .normal)
        buildButton.setBackgroundImage(img, for: .highlighted)
    }
}
