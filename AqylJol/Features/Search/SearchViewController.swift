import UIKit

final class SearchViewController: UIViewController, UITableViewDataSource, UITableViewDelegate {
    private let searchInput = EditableSearchFieldView()
    private let menuButton  = UIButton(type: .system)
    private let tableView   = UITableView(frame: .zero, style: .plain)
    var onOpenVoiceCapture: (() -> Void)?
    var onOpenSearchSheet: (() -> Void)?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .clear
        
        searchInput.textField.placeholder = "search.placeholder".localize()
        searchInput.textField.isUserInteractionEnabled = false
        searchInput.removeTarget(nil, action: nil, for: .allEvents)
        let tap = UITapGestureRecognizer(target: self, action: #selector(didTapSearchBar))
        searchInput.addGestureRecognizer(tap)
        searchInput.onMicTap = { [weak self] in
            self?.onOpenVoiceCapture?()
        }
        
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "line.3.horizontal")
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 10, leading: 10, bottom: 10, trailing: 10)
        menuButton.configuration = cfg
        menuButton.tintColor = .label
        menuButton.backgroundColor = .secondarySystemBackground
        menuButton.layer.cornerRadius = 12
        NSLayoutConstraint.activate([
            menuButton.widthAnchor.constraint(equalToConstant: 44),
            menuButton.heightAnchor.constraint(equalToConstant: 44)
        ])
        // НАДО РЕШИТЬ! УДАЛИТЬ ИЛИ ОСТАВЛЯЕМ?
        menuButton.addAction(UIAction { _ in
            print("☰ menu tapped (stub)")
        }, for: .touchUpInside)
        
        let top = UIStackView(arrangedSubviews: [searchInput, menuButton])
        top.axis = .horizontal
        top.spacing = 8
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.tableFooterView = UIView()
        
        let root = UIStackView(arrangedSubviews: [top, tableView])
        root.axis = .vertical
        root.spacing = 12
        view.addSubview(root)
        root.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            root.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),   // ★
            root.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            root.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            root.bottomAnchor.constraint(equalTo: view.bottomAnchor)
        ])
    }
    
    @objc private func didTapSearchBar() {
        onOpenSearchSheet?()
    }
    
    // MARK: - Table placeholders
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { 0 }
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        UITableViewCell(style: .subtitle, reuseIdentifier: nil)
    }
}
