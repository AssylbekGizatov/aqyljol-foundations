import UIKit
import Foundation

final class LoginViewController: UIViewController {
    private let viewModel: LoginViewModel
    private let scroll = UIScrollView()
    private let content = UIStackView()

    private let loginField = FormFieldView(kind: .text)
    private let passwordField = FormFieldView(kind: .secure)
    private let submit = UIButton(type: .system)
    var onForgotPassword: (() -> Void)?
    
    init(viewModel: LoginViewModel) {
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
        
        loginField.setStyle(title: "auth.login.login".localize(), placeholder: "auth.login.login.ph".localize())
        passwordField.setStyle(title: "auth.login.password".localize(), placeholder: "auth.login.password.ph".localize())
        
        let forgotWrap = UIView()
        let forgot = UIButton(type: .system)
        var linkCfg = UIButton.Configuration.plain()
        linkCfg.title = "auth.forgot".localize()
        linkCfg.baseForegroundColor = DesignTokens.neon2
        linkCfg.contentInsets = .init(top: 0, leading: 0, bottom: 0, trailing: 0)
        forgot.configuration = linkCfg
        forgot.titleLabel?.font = .systemFont(ofSize: 10, weight: .semibold)
        forgot.addAction(UIAction { [weak self] _ in self?.onForgotPassword?() }, for: .touchUpInside)
        
        forgotWrap.addSubview(forgot)
        forgot.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            forgot.topAnchor.constraint(equalTo: forgotWrap.topAnchor),
            forgot.trailingAnchor.constraint(equalTo: forgotWrap.trailingAnchor),
            forgot.bottomAnchor.constraint(equalTo: forgotWrap.bottomAnchor),
            forgot.leadingAnchor.constraint(greaterThanOrEqualTo: forgotWrap.leadingAnchor)
        ])
        
        var cfg = UIButton.Configuration.filled()
        cfg.title = "auth.login.submit".localize()
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
        
        content.addArrangedSubview(loginField)
        content.addArrangedSubview(passwordField)
        content.addArrangedSubview(forgotWrap)
        content.addArrangedSubview(submit)
    }
    
    private func bind() {
        loginField.onEditingChanged = { [weak self] text in self?.viewModel.login = text }
        passwordField.onEditingChanged = { [weak self] text in self?.viewModel.password = text }
        
        viewModel.isSubmitEnabled = { [weak self] ok in
            self?.submit.isEnabled = ok
            self?.submit.alpha = ok ? 1.0 : 0.5
        }
    }
    
    private func updateTexts() {
        if var cfg = submit.configuration {
            cfg.title = "auth.login.submit".localize()
            submit.configuration = cfg
        }
        loginField.setStyle(title: "auth.login.login".localize(), placeholder: "auth.login.login.ph".localize())
        passwordField.setStyle(title: "auth.login.password".localize(), placeholder: "auth.login.password.ph".localize())
    }
    
    func prefill(login: String) {
        loginField.text = login
        viewModel.login = login
    }
}
