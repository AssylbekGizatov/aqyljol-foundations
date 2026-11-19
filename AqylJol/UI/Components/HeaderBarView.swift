import UIKit

final class HeaderBarView: UIView {
    let backButton = UIButton(type: .system)
    let titleLabel = UILabel()
    let rightButton = UIButton(type: .system)

    init(title: String) {
        super.init(frame: .zero)
        backgroundColor = .clear
        
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "arrow.left")
        cfg.baseForegroundColor = .label
        cfg.contentInsets = .init(top: 8, leading: 8, bottom: 8, trailing: 8)
        backButton.configuration = cfg
        backButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(backButton)
        
        titleLabel.text = title
        titleLabel.font = .systemFont(ofSize: 18, weight: .semibold)
        titleLabel.textAlignment = .center
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        addSubview(titleLabel)
        
        rightButton.setTitle(nil, for: .normal)
        rightButton.titleLabel?.font = .systemFont(ofSize: 16, weight: .semibold)
        rightButton.translatesAutoresizingMaskIntoConstraints = false
        addSubview(rightButton)
        
        let top = safeAreaLayoutGuide
        NSLayoutConstraint.activate([
            heightAnchor.constraint(greaterThanOrEqualToConstant: 44),
            
            backButton.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 8),
            backButton.topAnchor.constraint(equalTo: top.topAnchor, constant: 4),
            backButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 36),
            backButton.heightAnchor.constraint(greaterThanOrEqualToConstant: 36),
            
            rightButton.trailingAnchor.constraint(equalTo: trailingAnchor, constant: -8),
            rightButton.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            titleLabel.centerXAnchor.constraint(equalTo: centerXAnchor),
            titleLabel.centerYAnchor.constraint(equalTo: backButton.centerYAnchor),
            
            bottomAnchor.constraint(equalTo: backButton.bottomAnchor, constant: 8)
        ])
    }
    
    @available(*, unavailable)
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
