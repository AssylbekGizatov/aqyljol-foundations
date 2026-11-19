import UIKit

final class SearchBarView: UIControl {
    private let iconImageView = UIImageView(image: UIImage(systemName: "magnifyingglass"))
    private let placeholderLabel = UILabel()
    private let micButton = UIButton(type: .system)
    private let stack = UIStackView()
    
    var onBarTap: (() -> Void)?
    var onMicTap: (() -> Void)?
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .secondarySystemBackground
        layer.cornerRadius = 12; layer.masksToBounds = true
        
        iconImageView.tintColor = .secondaryLabel
        iconImageView.setContentHuggingPriority(.required, for: .horizontal)
        
        placeholderLabel.text = NSLocalizedString("search.placeholder", comment: "")
        placeholderLabel.textColor = .secondaryLabel
        placeholderLabel.font = .systemFont(ofSize: 16)
        
        var micCfg = UIButton.Configuration.plain()
        micCfg.image = UIImage(systemName: "mic.fill")
        micCfg.contentInsets = NSDirectionalEdgeInsets(top: 6, leading: 6, bottom: 6, trailing: 6)
        micButton.configuration = micCfg
        micButton.tintColor = .label
        micButton.setContentHuggingPriority(.required, for: .horizontal)
        micButton.addAction(UIAction { [weak self] _ in self?.onMicTap?() }, for: .touchUpInside)
        
        stack.axis = .horizontal; stack.alignment = .center; stack.spacing = 6
        stack.isLayoutMarginsRelativeArrangement = true
        stack.layoutMargins = UIEdgeInsets(top: 4, left: 8, bottom: 4, right: 8)
        stack.addArrangedSubview(iconImageView)
        stack.addArrangedSubview(placeholderLabel)
        stack.addArrangedSubview(micButton)
        
        addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 44),
            stack.topAnchor.constraint(equalTo: topAnchor),
            stack.leadingAnchor.constraint(equalTo: leadingAnchor),
            stack.trailingAnchor.constraint(equalTo: trailingAnchor),
            stack.bottomAnchor.constraint(equalTo: bottomAnchor)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
        addGestureRecognizer(tap)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    @objc private func handleTap(_ g: UITapGestureRecognizer) {
        let loc = g.location(in: self)
        if micButton.frame.contains(loc) { return }
        onBarTap?()
    }
}
