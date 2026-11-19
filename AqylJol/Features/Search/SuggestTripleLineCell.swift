import UIKit

final class SuggestTripleLineCell: UITableViewCell {
    static let reuseID = "SuggestCell"
    let iconView = UIImageView()
    let titleLabel = UILabel()
    let subtitleLabel = UILabel()
    let addressLabel = UILabel()
    
    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        selectionStyle = .default
        accessoryType = .disclosureIndicator
        
        iconView.image = UIImage(systemName: "mappin.and.ellipse")
        iconView.setContentHuggingPriority(.required, for: .horizontal)
        iconView.tintColor = tintColor
        
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.numberOfLines = 2
        
        subtitleLabel.font = .systemFont(ofSize: 12, weight: .regular)
        subtitleLabel.numberOfLines = 1
        
        addressLabel.font = .systemFont(ofSize: 12, weight: .regular)
        addressLabel.textColor = .secondaryLabel
        addressLabel.numberOfLines = 1
        
        let v = UIStackView(arrangedSubviews: [titleLabel, subtitleLabel, addressLabel])
        v.axis = .vertical
        v.spacing = 2
        
        let h = UIStackView(arrangedSubviews: [iconView, v])
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 12
        
        contentView.addSubview(h)
        h.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            h.topAnchor.constraint(equalTo: contentView.topAnchor, constant: 10),
            h.bottomAnchor.constraint(equalTo: contentView.bottomAnchor, constant: -10),
            h.leadingAnchor.constraint(equalTo: contentView.leadingAnchor, constant: 16),
            h.trailingAnchor.constraint(equalTo: contentView.trailingAnchor, constant: -16),
            iconView.widthAnchor.constraint(equalToConstant: 20),
            iconView.heightAnchor.constraint(equalToConstant: 20)
        ])
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
}
