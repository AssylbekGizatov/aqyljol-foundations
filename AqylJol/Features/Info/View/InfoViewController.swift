import UIKit

final class InfoViewController: UIViewController {
    
    // MARK: - UI
    private let closeButton = UIButton(type: .system)
    private let titleLabel = UILabel()
    private let subtitleLabel = UILabel()
    
    // MARK: - Rating
    private let ratingRow = UIStackView()
    private var starImageViews: [UIImageView] = []
    private let ratingValueLabel = UILabel()
    private let reviewsCountLabel = UILabel()
    private let ratingBottomPadding = UIView()
    
    // MARK: - Address
    private let addressChip = UIControl()
    private let addressIcon = UIImageView(image: UIImage(systemName: "mappin.and.ellipse"))
    private let addressTextLabel = UILabel()
    
    // MARK: - Time
    private var isCompact = false
    private var lastHoursLines: [String]? = nil
    private let hoursTitleLabel = UILabel()
    private let hoursStack = UIStackView()
    
    private let root = UIStackView()
    
    // MARK: - VM
    private let viewModel: InfoViewModeling
    var onClose: (() -> Void)?
    
    // MARK: - Init
    init(viewModel: InfoViewModeling) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("Use init(viewModel:)") }
    
    // MARK: - Lifecycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        setupUI()
        bindViewModel()
    }
    
    // MARK: - Setup
    private func setupUI() {
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
        closeButton.addAction(UIAction { [weak self] _ in self?.viewModel.didTapClose() }, for: .touchUpInside)
        closeButton.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            closeButton.widthAnchor.constraint(equalToConstant: 32),
            closeButton.heightAnchor.constraint(equalToConstant: 32)
        ])
        
        titleLabel.font = .systemFont(ofSize: 20, weight: .semibold)
        titleLabel.textColor = .label
        titleLabel.numberOfLines = 2
        titleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        titleLabel.setContentCompressionResistancePriority(.required, for: .vertical)
        
        subtitleLabel.font = .systemFont(ofSize: 15, weight: .regular)
        subtitleLabel.textColor = .secondaryLabel
        subtitleLabel.numberOfLines = 1
        subtitleLabel.setContentHuggingPriority(.defaultHigh, for: .vertical)
        subtitleLabel.setContentCompressionResistancePriority(.defaultHigh, for: .vertical)
        
        let spacer = UIView()
        let headerRow = UIStackView(arrangedSubviews: [titleLabel, spacer, closeButton])
        headerRow.axis = .horizontal
        headerRow.alignment = .center
        headerRow.spacing = 8
        
        ratingRow.axis = .horizontal
        ratingRow.alignment = .center
        ratingRow.distribution = .fill
        ratingRow.spacing = 6
        starImageViews.removeAll(keepingCapacity: true)
        let starSize: CGFloat = 18
        for _ in 0..<5 {
            let iv = UIImageView()
            iv.contentMode = .scaleAspectFit
            iv.tintColor = .systemYellow
            iv.translatesAutoresizingMaskIntoConstraints = false
            iv.widthAnchor.constraint(equalToConstant: starSize).isActive = true
            iv.heightAnchor.constraint(equalToConstant: starSize).isActive = true
            ratingRow.addArrangedSubview(iv)
            starImageViews.append(iv)
        }
        ratingValueLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        ratingValueLabel.textColor = .label
        ratingValueLabel.setContentHuggingPriority(.required, for: .horizontal)
        ratingValueLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingRow.addArrangedSubview(ratingValueLabel)

        reviewsCountLabel.font = .systemFont(ofSize: 13, weight: .regular)
        reviewsCountLabel.textColor = .secondaryLabel
        reviewsCountLabel.setContentHuggingPriority(.required, for: .horizontal)
        reviewsCountLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
        ratingRow.addArrangedSubview(reviewsCountLabel)

        ratingBottomPadding.translatesAutoresizingMaskIntoConstraints = false
        ratingBottomPadding.heightAnchor.constraint(equalToConstant: 12).isActive = true
        
        let isLight = traitCollection.userInterfaceStyle != .dark
        addressChip.backgroundColor = isLight ? .secondarySystemBackground : DesignTokens.glass
        addressChip.layer.cornerRadius = 12
        addressChip.layer.borderWidth  = 1
        addressChip.layer.borderColor  = (isLight ? UIColor.systemGray4 : DesignTokens.stroke).cgColor
        addressChip.layer.masksToBounds = true
        addressChip.addAction(UIAction { [weak self] _ in self?.copyAddress() }, for: .touchUpInside)

        addressIcon.contentMode = .scaleAspectFit
        addressIcon.tintColor = isLight ? UIColor.secondaryLabel : DesignTokens.labelFaint
        addressIcon.setContentHuggingPriority(.required, for: .horizontal)
        addressIcon.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            addressIcon.widthAnchor.constraint(equalToConstant: 18),
            addressIcon.heightAnchor.constraint(equalToConstant: 18)
        ])

        addressTextLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        addressTextLabel.textColor = .label
        addressTextLabel.numberOfLines = 0

        let chipRow = UIStackView(arrangedSubviews: [addressIcon, addressTextLabel])
        chipRow.axis = .horizontal
        chipRow.alignment = .center
        chipRow.spacing = 8

        addressChip.addSubview(chipRow)
        chipRow.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            chipRow.topAnchor.constraint(equalTo: addressChip.topAnchor, constant: 10),
            chipRow.bottomAnchor.constraint(equalTo: addressChip.bottomAnchor, constant: -10),
            chipRow.leadingAnchor.constraint(equalTo: addressChip.leadingAnchor, constant: 12),
            chipRow.trailingAnchor.constraint(equalTo: addressChip.trailingAnchor, constant: -12)
        ])
        
        hoursTitleLabel.text = "opening_hours".localize()
        hoursTitleLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        hoursTitleLabel.textColor = DesignTokens.neon
        hoursStack.axis = .vertical
        hoursStack.alignment = .fill
        hoursStack.spacing = 6
        hoursTitleLabel.isHidden = true
        hoursStack.isHidden      = true
        
        root.axis = .vertical
        root.spacing = 8
        root.addArrangedSubview(headerRow)
        root.addArrangedSubview(subtitleLabel)
        root.addArrangedSubview(ratingRow)
        root.addArrangedSubview(ratingBottomPadding)
        root.addArrangedSubview(addressChip)
        root.addArrangedSubview(hoursTitleLabel)
        root.addArrangedSubview(hoursStack)

        view.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 6),
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            root.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor, constant: -4)
        ])
    }


    
    // MARK: - Binding
    private func bindViewModel() {
        viewModel.onRender = { [weak self] data in
            guard let self else { return }

            titleLabel.text = data.title

            let sub = (data.subtitle ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            subtitleLabel.text = sub
            subtitleLabel.isHidden = sub.isEmpty || data.isSubtitleHidden

            let full  = (data.fullAddress ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let short = (data.address ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
            let chipText = full.isEmpty ? short : full
            addressTextLabel.text = chipText
            addressChip.isHidden  = chipText.isEmpty

            updateRatingStars(value: data.rating)
            if let r = data.rating {
                ratingValueLabel.text = String(format:"%.1f", r)
                ratingValueLabel.isHidden = false
            } else {
                ratingValueLabel.text = nil
                ratingValueLabel.isHidden = true
            }
            if let c = data.reviewsCount, c > 0 {
                reviewsCountLabel.text = "\u{2009}\(c) оценок"
                reviewsCountLabel.isHidden = false
            } else {
                reviewsCountLabel.text = nil
                reviewsCountLabel.isHidden = true
            }
            ratingRow.isHidden = (data.rating == nil && (data.reviewsCount ?? 0) == 0)
            
            self.lastHoursLines = data.weeklyHoursLines
            self.renderHours(lines: self.lastHoursLines)
        }
        
        viewModel.onClose = { [weak self] in self?.onClose?() }
    }
    
    // MARK: - Stars
    private func updateRatingStars(value: Float?) {
        let v = max(0, min(5, value ?? 0))
        let fullCount = Int(floor(v))
        let hasHalf = (v - Float(fullCount)) >= 0.5
        for (i, iv) in starImageViews.enumerated() {
            if i < fullCount {
                iv.image = UIImage(systemName: "star.fill")
            } else if i == fullCount && hasHalf {
                iv.image = UIImage(systemName: "star.leadinghalf.filled")
                    ?? UIImage(systemName: "star.lefthalf.fill")
                    ?? UIImage(systemName: "star")
            } else {
                iv.image = UIImage(systemName: "star")
            }
        }
    }
    
    // MARK: - Address copy
    private func copyAddress() {
        let t = (addressTextLabel.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        guard !t.isEmpty else { return }
        UIPasteboard.general.string = t
        
        let toast = UILabel()
        toast.text = "copied".localize()
        toast.font = .systemFont(ofSize: 12, weight: .semibold)
        toast.textColor = .white
        toast.textAlignment = .center
        toast.backgroundColor = DesignTokens.neon2.withAlphaComponent(0.95)
        toast.layer.cornerRadius = 12
        toast.layer.masksToBounds = true
        
        view.addSubview(toast)
        toast.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            toast.centerXAnchor.constraint(equalTo: addressChip.centerXAnchor),
            toast.bottomAnchor.constraint(equalTo: addressChip.topAnchor, constant: -8),
            toast.widthAnchor.constraint(greaterThanOrEqualToConstant: 110),
            toast.heightAnchor.constraint(equalToConstant: 28)
        ])
        toast.alpha = 0
        UIView.animate(withDuration: 0.18, animations: {
            toast.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.25, delay: 0.9, options: [], animations: {
                toast.alpha = 0
            }) { _ in
                toast.removeFromSuperview()
            }
        }
        UISelectionFeedbackGenerator().selectionChanged()
    }
    
    // MARK: - Hours render
    private func renderHours(lines: [String]?) {
        hoursStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        if isCompact {
            hoursTitleLabel.isHidden = true
            hoursStack.isHidden = true
            return
        }
        guard let lines, !lines.isEmpty else {
            hoursTitleLabel.isHidden = true
            hoursStack.isHidden = true
            return
        }
        hoursTitleLabel.isHidden = false
        hoursStack.isHidden = false
        
        let todayIdx = currentWeekdayIndexMon0()
        for (idx, line) in lines.enumerated() {
            let parts = line.split(separator: ":", maxSplits: 1, omittingEmptySubsequences: false)
            let dayText = parts.first?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
            let hoursText = (parts.count > 1 ? parts[1] : "").trimmingCharacters(in: .whitespacesAndNewlines)
            
            let row = UIView()
            let dayLabel = UILabel()
            dayLabel.font = .systemFont(ofSize: 13, weight: .semibold)
            dayLabel.text = dayText
            dayLabel.textColor = .secondaryLabel
            dayLabel.setContentHuggingPriority(.required, for: .horizontal)
            dayLabel.setContentCompressionResistancePriority(.required, for: .horizontal)
            
            let valueLabel = UILabel()
            valueLabel.font = .systemFont(ofSize: 13, weight: .regular)
            valueLabel.text = hoursText.isEmpty ? "—" : hoursText
            valueLabel.textColor = .label
            valueLabel.numberOfLines = 1
            
            let rowStack = UIStackView(arrangedSubviews: [dayLabel, valueLabel])
            rowStack.axis = .horizontal
            rowStack.alignment = .center
            rowStack.spacing = 10
            
            row.addSubview(rowStack)
            rowStack.translatesAutoresizingMaskIntoConstraints = false
            NSLayoutConstraint.activate([
                rowStack.topAnchor.constraint(equalTo: row.topAnchor, constant: 8),
                rowStack.bottomAnchor.constraint(equalTo: row.bottomAnchor, constant: -8),
                rowStack.leadingAnchor.constraint(equalTo: row.leadingAnchor, constant: 12),
                rowStack.trailingAnchor.constraint(equalTo: row.trailingAnchor, constant: -12)
            ])
            
            if idx == todayIdx {
                row.backgroundColor = DesignTokens.glass
                row.layer.cornerRadius = 12
                dayLabel.textColor = DesignTokens.neon
                valueLabel.textColor = DesignTokens.neon2
                row.layer.shadowColor = DesignTokens.neon2.withAlphaComponent(0.7).cgColor
                row.layer.shadowRadius = 10
                row.layer.shadowOpacity = 0.25
                row.layer.shadowOffset = CGSize(width: 0, height: 2)
            }
            hoursStack.addArrangedSubview(row)
        }
    }
    
    private func currentWeekdayIndexMon0() -> Int {
        let wd = Calendar.current.component(.weekday, from: Date())
        return (wd == 1) ? 6 : (wd - 2)
    }
    func setCompactMode(_ compact: Bool) {
        guard isCompact != compact else { return }
        isCompact = compact
        if compact {
            hoursTitleLabel.isHidden = true
            hoursStack.isHidden      = true
            hoursStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
        } else {
            renderHours(lines: lastHoursLines)
        }
    }
}
