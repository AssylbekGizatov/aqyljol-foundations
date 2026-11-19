import UIKit

final class ChatMessageCell: UITableViewCell {
    static let reuseId = "ChatMessageCell"

    private let bubble = UIView()
    private let messageLabel = UILabel()
    private let resultsStack = UIStackView()

    private var leadingC: NSLayoutConstraint!
    private var trailingC: NSLayoutConstraint!

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .none
        backgroundColor = .clear

        contentView.layoutMargins = .init(top: 6, left: 12, bottom: 6, right: 12)

        bubble.layer.cornerRadius = 16
        bubble.layer.masksToBounds = true

        messageLabel.numberOfLines = 0
        messageLabel.font = .systemFont(ofSize: 16)

        resultsStack.axis = .vertical
        resultsStack.alignment = .fill
        resultsStack.spacing = 8

        let inner = UIStackView(arrangedSubviews: [messageLabel, resultsStack])
        inner.axis = .vertical
        inner.alignment = .fill
        inner.spacing = 10
        inner.isLayoutMarginsRelativeArrangement = true
        inner.layoutMargins = .init(top: 10, left: 12, bottom: 10, right: 12)

        bubble.addSubview(inner)
        inner.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            inner.topAnchor.constraint(equalTo: bubble.topAnchor),
            inner.leadingAnchor.constraint(equalTo: bubble.leadingAnchor),
            inner.trailingAnchor.constraint(equalTo: bubble.trailingAnchor),
            inner.bottomAnchor.constraint(equalTo: bubble.bottomAnchor)
        ])

        contentView.addSubview(bubble)
        bubble.translatesAutoresizingMaskIntoConstraints = false
        leadingC  = bubble.leadingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.leadingAnchor)
        trailingC = bubble.trailingAnchor.constraint(equalTo: contentView.layoutMarginsGuide.trailingAnchor)

        NSLayoutConstraint.activate([
            bubble.topAnchor.constraint(equalTo: contentView.layoutMarginsGuide.topAnchor),
            bubble.bottomAnchor.constraint(equalTo: contentView.layoutMarginsGuide.bottomAnchor),
            bubble.widthAnchor.constraint(lessThanOrEqualTo: contentView.widthAnchor, multiplier: 0.78),
            leadingC, trailingC
        ])
    }

    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func prepareForReuse() {
        super.prepareForReuse()
        resultsStack.arrangedSubviews.forEach { v in
            resultsStack.removeArrangedSubview(v)
            v.removeFromSuperview()
        }
    }

    func configure(text: String, role: ChatRole, results: [Place]?) {
        
        let isUser = (role == .user)
        messageLabel.textColor = isUser ? .white : .label
        bubble.backgroundColor = isUser ? .systemBlue : .secondarySystemBackground
        
        if isUser {
            leadingC.isActive = false
            trailingC.isActive = true
        } else {
            trailingC.isActive = false
            leadingC.isActive = true
        }
        
        messageLabel.text = text
        
        if let results, !results.isEmpty, !isUser {
            for p in results {
                resultsStack.addArrangedSubview(makePlaceCard(p))
            }
        }
    }

    private func makePlaceCard(_ p: Place) -> UIView {
        
        let card = UIStackView()
        card.axis = .vertical
        card.alignment = .fill
        card.spacing = 6
        card.isLayoutMarginsRelativeArrangement = true
        card.layoutMargins = .init(top: 10, left: 10, bottom: 10, right: 10)
        card.backgroundColor = .tertiarySystemBackground
        card.layer.cornerRadius = 12
        card.layer.borderWidth = 1
        card.layer.borderColor = UIColor.quaternaryLabel.cgColor
        
        let nameL = UILabel()
        nameL.font = .systemFont(ofSize: 15, weight: .semibold)
        nameL.numberOfLines = 1
        nameL.text = p.name
        card.addArrangedSubview(nameL)
        
        func line(_ title: String, _ value: String) -> UILabel {
            let l = UILabel()
            l.font = .systemFont(ofSize: 13)
            l.textColor = .secondaryLabel
            l.numberOfLines = 1
            l.text = "\(title): \(value)"
            return l
        }
        
        card.addArrangedSubview(line("type".localize(), p.type))
        
        card.addArrangedSubview(line("distance".localize(), String(format: "%.1f км", p.distance_km)))
        
        card.addArrangedSubview(line("rating".localize(), String(format: "%.1f ★", p.rating)))
        
        let descTitle = line("describe".localize(), "")
        descTitle.text = "describe".localize() + ":"
        card.addArrangedSubview(descTitle)

        let desc = UILabel()
        desc.font = .systemFont(ofSize: 13)
        desc.textColor = .label
        desc.numberOfLines = 0
        desc.text = p.description
        card.addArrangedSubview(desc)

        return card
    }
}
