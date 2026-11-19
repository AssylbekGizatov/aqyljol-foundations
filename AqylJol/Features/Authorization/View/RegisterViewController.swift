import Foundation
import UIKit

final class RegisterViewController: UIViewController {
    private let viewModel: RegisterViewModel
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let firstNameField = FormFieldView(kind: .text)
    private let lastNameField  = FormFieldView(kind: .text)
    private let roleField      = FormFieldView(kind: .text)
    private let loginField     = FormFieldView(kind: .text)
    private let passwordField  = FormFieldView(kind: .secure)
    private let repeatField    = FormFieldView(kind: .secure)
    
    private let mismatchLabel = UILabel()
    private let submit = UIButton(type: .system)

    init(viewModel: RegisterViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        build()
        bind()
        updateTexts()
    }

    private func build() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: view.topAnchor),
            scroll.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            scroll.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            scroll.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])

        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        scroll.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 24),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor)
        ])

        firstNameField.setStyle(title: "auth.reg.first".localize(), placeholder: "auth.reg.first.ph".localize())
        lastNameField.setStyle(title: "auth.reg.last".localize(), placeholder: "auth.reg.last.ph".localize())
        roleField.setStyle(title: "auth.reg.role".localize(), placeholder: "auth.reg.role.ph".localize())
        loginField.setStyle(title: "auth.reg.login".localize(), placeholder: "auth.reg.login.ph".localize())
        passwordField.setStyle(title: "auth.reg.password".localize(), placeholder: "auth.reg.password.ph".localize())
        repeatField.setStyle(title: "auth.reg.repeat".localize(), placeholder: "auth.reg.repeat.ph".localize())

        mismatchLabel.textColor = .systemRed
        mismatchLabel.font = .systemFont(ofSize: 12, weight: .semibold)
        mismatchLabel.text = "auth.reg.mismatch".localize()
        mismatchLabel.isHidden = true

        var cfg = UIButton.Configuration.filled()
        cfg.title = "auth.reg.submit".localize()
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

        content.addArrangedSubview(firstNameField)
        content.addArrangedSubview(lastNameField)
        content.addArrangedSubview(roleField)
        content.addArrangedSubview(loginField)
        content.addArrangedSubview(passwordField)
        content.addArrangedSubview(repeatField)
        content.addArrangedSubview(mismatchLabel)
        content.addArrangedSubview(submit)
    }

    private func bind() {
        firstNameField.onEditingChanged = { [weak self] t in self?.viewModel.firstName = t }
        lastNameField.onEditingChanged  = { [weak self] t in self?.viewModel.lastName  = t }
        roleField.onEditingChanged      = { [weak self] t in self?.viewModel.role      = t }
        loginField.onEditingChanged     = { [weak self] t in self?.viewModel.login     = t }
        passwordField.onEditingChanged  = { [weak self] t in self?.viewModel.password  = t }
        repeatField.onEditingChanged    = { [weak self] t in self?.viewModel.passwordRepeat = t }

        viewModel.passwordMismatchVisible = { [weak self] show in self?.mismatchLabel.isHidden = !show }
        viewModel.isSubmitEnabled = { [weak self] ok in
            self?.submit.isEnabled = ok
            self?.submit.alpha = ok ? 1.0 : 0.5
        }
    }

    private func updateTexts() {
        if var cfg = submit.configuration { cfg.title = "auth.reg.submit".localize(); submit.configuration = cfg }
        firstNameField.setStyle(title: "auth.reg.first".localize(), placeholder: "auth.reg.first.ph".localize())
        lastNameField.setStyle(title: "auth.reg.last".localize(), placeholder: "auth.reg.last.ph".localize())
        roleField.setStyle(title: "auth.reg.role".localize(), placeholder: "auth.reg.role.ph".localize())
        loginField.setStyle(title: "auth.reg.login".localize(), placeholder: "auth.reg.login.ph".localize())
        passwordField.setStyle(title: "auth.reg.password".localize(), placeholder: "auth.reg.password.ph".localize())
        repeatField.setStyle(title: "auth.reg.repeat".localize(), placeholder: "auth.reg.repeat.ph".localize())
        mismatchLabel.text = "auth.reg.mismatch".localize()
    }
    
    func resetForm() {
        firstNameField.text = ""
        lastNameField.text  = ""
        roleField.text      = ""
        loginField.text     = ""
        passwordField.text  = ""
        repeatField.text    = ""
        
        viewModel.firstName = ""
        viewModel.lastName  = ""
        viewModel.role      = ""
        viewModel.login     = ""
        viewModel.password  = ""
        viewModel.passwordRepeat = ""
        mismatchLabel.isHidden = true
    }
}
