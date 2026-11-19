import UIKit

final class ResetPasswordViewController: UIViewController {
    private let viewModel: ResetPasswordViewModel
    init(viewModel: ResetPasswordViewModel) { self.viewModel = viewModel; super.init(nibName: nil, bundle: nil) }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    private let header = HeaderBarView(title: "auth.reset.title".localize())
    private let content = UIStackView()
    private let emailField = FormFieldView(kind: .text)
    private let hintLabel = UILabel()
    private let submit = UIButton(type: .system)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildHeader()
        buildForm()
        bind()
        updateTexts()
    }

    private func buildHeader() {
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        header.backButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)
        header.rightButton.isHidden = true
    }

    private func buildForm() {
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = .init(top: 24, left: 20, bottom: 24, right: 20)

        view.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 76),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(lessThanOrEqualTo: view.bottomAnchor)
        ])

        emailField.setStyle(title: "auth.reset.email".localize(), placeholder: "auth.reset.email.ph".localize())

        hintLabel.numberOfLines = 0
        hintLabel.font = .systemFont(ofSize: 13)
        hintLabel.textColor = .secondaryLabel

        var cfg = UIButton.Configuration.filled()
        cfg.title = "auth.reset.submit".localize()
        cfg.baseBackgroundColor = DesignTokens.neon2
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        submit.configuration = cfg
        submit.layer.cornerRadius = DesignTokens.cornerPill
        submit.layer.masksToBounds = true
        submit.isEnabled = false
        submit.alpha = 0.5
        submit.addAction(UIAction { [weak self] _ in self?.viewModel.submit() }, for: .touchUpInside)

        content.addArrangedSubview(emailField)
        content.addArrangedSubview(hintLabel)
        content.addArrangedSubview(submit)
    }

    private func bind() {
        emailField.onEditingChanged = { [weak self] t in self?.viewModel.email = t }
        viewModel.isSubmitEnabled = { [weak self] ok in
            self?.submit.isEnabled = ok
            self?.submit.alpha = ok ? 1.0 : 0.5
        }
        viewModel.isLoading = { [weak self] loading in
            self?.view.isUserInteractionEnabled = !loading
        }
        viewModel.errorText = { [weak self] text in
            if let t = text { self?.showToast(t) }
        }
        viewModel.onSuccess = { [weak self] email in
            self?.showToast("auth.reset.sent".localize())
            self?.dismiss(animated: true)
        }
    }

    private func updateTexts() {
        header.titleLabel.text = "auth.reset.title".localize()
        emailField.setStyle(title: "auth.reset.email".localize(), placeholder: "auth.reset.email.ph".localize())
        hintLabel.text = "auth.reset.hint".localize()
        if var cfg = submit.configuration { cfg.title = "auth.reset.submit".localize(); submit.configuration = cfg }
    }
}
