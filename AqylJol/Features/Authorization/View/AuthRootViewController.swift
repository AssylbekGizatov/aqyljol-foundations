import UIKit

final class AuthRootViewController: UIViewController {
    private let header = HeaderBarView(title: "auth.title".localize())

    private let switcher = UISegmentedControl(items: [
        "auth.login".localize(), "auth.register".localize()
    ])
    private let container = UIView()

    private lazy var loginVM = LoginViewModel()
    private lazy var registerVM = RegisterViewModel()
    private lazy var loginVC = LoginViewController(viewModel: loginVM)
    private lazy var registerVC = RegisterViewController(viewModel: registerVM)

    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildHeader()
        buildSwitcher()
        buildContainer()
        bindVM()
        switchTo(index: 0)
    }

    private func buildHeader() {
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        header.backButton.isHidden = true
        header.rightButton.isHidden = true
        header.titleLabel.textAlignment = .center
    }

    private func buildSwitcher() {
        switcher.selectedSegmentTintColor = DesignTokens.neon2
        let normalText = [NSAttributedString.Key.foregroundColor: UIColor.secondaryLabel]
        let selectedText = [NSAttributedString.Key.foregroundColor: UIColor.white]
        switcher.setTitleTextAttributes(normalText, for: .normal)
        switcher.setTitleTextAttributes(selectedText, for: .selected)
        switcher.addTarget(self, action: #selector(segChanged), for: .valueChanged)
        switcher.selectedSegmentIndex = 0

        view.addSubview(switcher)
        switcher.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            switcher.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 16),
            switcher.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 20),
            switcher.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -20)
        ])
    }

    private func buildContainer() {
        view.addSubview(container)
        container.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            container.topAnchor.constraint(equalTo: switcher.bottomAnchor, constant: 16),
            container.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            container.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            container.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }

    private func bindVM() {
        loginVM.onSuccess = { [weak self] user in
            self?.showToast("auth.login.ok".localize())
            self?.goToMain()
            NotificationsPermission.requestIfNeeded { [weak self] in
                self?.goToMain()
            }
        }
        loginVM.errorText = { [weak self] message in
            if let message { self?.showToast(message) }
        }
        loginVM.isLoading = { [weak self] loading in
            self?.view.isUserInteractionEnabled = !loading
        }
        loginVC.onForgotPassword = { [weak self] in
            self?.presentReset()
        }
        
        registerVM.onSuccess = { [weak self] user in
            guard let self else { return }
            self.registerVC.resetForm()
            self.switcher.selectedSegmentIndex = 0
            self.switchTo(index: 0)
            self.loginVC.prefill(login: user.email)
            self.showToast("auth.register.ok".localize())
        }
        registerVM.errorText = { [weak self] message in
            if let message { self?.showToast(message) }
        }
        registerVM.isLoading = { [weak self] loading in
            self?.view.isUserInteractionEnabled = !loading
        }
    }
    
    private func goToMain() {
        guard let scene = view.window?.windowScene,
              let win = scene.windows.first else { return }
        let root = MapViewController(viewModel: MapViewModel())
        UIView.transition(with: win, duration: 0.25, options: .transitionCrossDissolve, animations: {
            win.rootViewController = root
        })
    }
    
    private func presentReset() {
        let vm = ResetPasswordViewModel()
        let vc = ResetPasswordViewController(viewModel: vm)
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: true)
    }
    
    @objc private func segChanged() { switchTo(index: switcher.selectedSegmentIndex) }
    
    private func switchTo(index: Int) {
        children.forEach { vc in
            vc.willMove(toParent: nil)
            vc.view.removeFromSuperview()
            vc.removeFromParent()
        }
        let vc = (index == 0) ? loginVC : registerVC
        addChild(vc)
        container.addSubview(vc.view)
        vc.view.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            vc.view.topAnchor.constraint(equalTo: container.topAnchor),
            vc.view.leadingAnchor.constraint(equalTo: container.leadingAnchor),
            vc.view.trailingAnchor.constraint(equalTo: container.trailingAnchor),
            vc.view.bottomAnchor.constraint(equalTo: container.bottomAnchor)
        ])
        vc.didMove(toParent: self)
    }
}

extension UIViewController {
    func showToast(_ text: String) {
        let lbl = PaddingLabel(insets: .init(top: 8, left: 12, bottom: 8, right: 12))
        lbl.text = text
        lbl.textColor = .white
        lbl.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        lbl.layer.cornerRadius = 12
        lbl.layer.masksToBounds = true
        lbl.alpha = 0
        lbl.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(lbl)
        NSLayoutConstraint.activate([
            lbl.centerXAnchor.constraint(equalTo: view.centerXAnchor),
            lbl.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -24)
        ])
        UIView.animate(withDuration: 0.2, animations: { lbl.alpha = 1 }) { _ in
            UIView.animate(withDuration: 0.2, delay: 1.0, options: [], animations: { lbl.alpha = 0 }) { _ in
                lbl.removeFromSuperview()
            }
        }
    }
}
