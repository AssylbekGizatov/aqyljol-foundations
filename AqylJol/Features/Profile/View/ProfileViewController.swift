import UIKit

final class ProfileViewController: UIViewController {
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        let close = UIButton(type: .system)
        close.setTitle("close".localize(), for: .normal)
        close.titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
        close.addAction(UIAction { [weak self] _ in self?.dismiss(animated: true) }, for: .touchUpInside)

        close.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(close)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -16)
        ])

        let title = UILabel()
        title.text = "profile.title".localize()
        title.font = .systemFont(ofSize: 28, weight: .bold)
        title.translatesAutoresizingMaskIntoConstraints = false
        view.addSubview(title)
        NSLayoutConstraint.activate([
            close.topAnchor.constraint(equalTo: view.safeAreaLayoutGuide.topAnchor, constant: 16),
            close.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 16)
        ])
    }
}
