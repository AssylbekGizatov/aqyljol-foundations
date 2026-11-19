import UIKit
import CoreLocation

final class ChatViewController: UIViewController, CLLocationManagerDelegate, UIGestureRecognizerDelegate {
    // MARK: - UI
    private let header = HeaderBarView(title: "chats.title".localize())
    private let tableView = UITableView(frame: .zero, style: .plain)
    private let inputBar = ChatInputBar()
    
    private let locationManager = CLLocationManager()
    private var lastCoordinate: CLLocationCoordinate2D?

    // constraints
    private var inputBottomC: NSLayoutConstraint!

    // MARK: - VM
    private let vm: ChatViewModel

    // MARK: - Datasource
    private enum Section { case main }
    private var dataSource: UITableViewDiffableDataSource<Section, String>!
    private var messagesById: [String: ChatMessage] = [:]

    // MARK: - Init
    init(viewModel: ChatViewModel) {
        self.vm = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    convenience init(defaultServerURL: URL = URL(string: "https://1bdb3ae05a02.ngrok-free.app")!) {
        let service = ChatServiceHTTP(baseURL: defaultServerURL)
        let repo = ChatRepository()
        let vm = ChatViewModel(repo: repo, service: service)
        self.init(viewModel: vm)
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }

    // MARK: - Life
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        buildUI()
        buildDS()
        wireVM()
        wireInput()
        registerKeyboard()
        registerLangObserver()
        vm.bootstrapAfterLogin()
        
        locationManager.delegate = self
        locationManager.requestWhenInUseAuthorization()
        locationManager.startUpdatingLocation()
        
        tableView.keyboardDismissMode = .onDrag
        
        let tapTV = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardTap(_:)))
        tapTV.cancelsTouchesInView = false
        tapTV.delegate = self
        tableView.addGestureRecognizer(tapTV)
        
        let tapBG = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardTap(_:)))
        tapBG.cancelsTouchesInView = false
        tapBG.delegate = self
        view.addGestureRecognizer(tapBG)
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        vm.startListening()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        vm.stopListening()
    }

    deinit { NotificationCenter.default.removeObserver(self) }
    
    func locationManager(_ manager: CLLocationManager, didUpdateLocations locations: [CLLocation]) {
        lastCoordinate = locations.last?.coordinate
    }
    func locationManager(_ manager: CLLocationManager, didFailWithError error: Error) {
        
    }
    @objc private func dismissKeyboardTap(_ gr: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    func gestureRecognizer(_ gestureRecognizer: UIGestureRecognizer, shouldReceive touch: UITouch) -> Bool {
        
        if let v = touch.view, v.isDescendant(of: inputBar) { return false }
        return true
    }
}

// MARK: - Build
extension ChatViewController {
    func buildUI() {
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        header.backButton.addAction(UIAction { [weak self] _ in
            self?.dismiss(animated: false)
        }, for: .touchUpInside)
        
        tableView.keyboardDismissMode = .interactive
        tableView.separatorStyle = .none
        tableView.contentInset = UIEdgeInsets(top: 12, left: 0, bottom: 12, right: 0)
        tableView.register(ChatMessageCell.self, forCellReuseIdentifier: ChatMessageCell.reuseId)
        tableView.rowHeight = UITableView.automaticDimension
        tableView.estimatedRowHeight = 60

        view.addSubview(inputBar)
        inputBar.translatesAutoresizingMaskIntoConstraints = false
        
        view.addSubview(tableView)
        tableView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            inputBar.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            inputBar.trailingAnchor.constraint(equalTo: view.trailingAnchor),
        ])
        inputBottomC = inputBar.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -15)
        inputBottomC.isActive = true
        NSLayoutConstraint.activate([
            tableView.topAnchor.constraint(equalTo: header.bottomAnchor),
            tableView.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            tableView.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            tableView.bottomAnchor.constraint(equalTo: inputBar.topAnchor)
        ])
    }

    func buildDS() {
        dataSource = UITableViewDiffableDataSource<Section, String>(tableView: tableView) { [weak self] table, indexPath, msgId in
            guard
                let self,
                let msg = self.messagesById[msgId],
                let cell = table.dequeueReusableCell(withIdentifier: ChatMessageCell.reuseId, for: indexPath) as? ChatMessageCell
            else { return UITableViewCell() }

            cell.configure(text: msg.message, role: msg.role, results: msg.results)
            cell.contentView.layoutIfNeeded()
            return cell
        }
        tableView.dataSource = dataSource
    }

    func wireVM() {
        vm.onMessages = { [weak self] msgs in
            guard let self else { return }
            self.messagesById = Dictionary(uniqueKeysWithValues: msgs.map { ($0.id, $0) })

            var snapshot = NSDiffableDataSourceSnapshot<Section, String>()
            snapshot.appendSections([.main])
            snapshot.appendItems(msgs.map { $0.id }, toSection: .main)
            self.dataSource.apply(snapshot, animatingDifferences: true) { [weak self] in
                self?.scrollToBottom(animated: true)
            }
        }

        vm.isBusy = { [weak self] busy in
            self?.inputBar.setBusy(busy)
        }

        vm.errorText = { [weak self] text in
            guard let self, let text, !text.isEmpty else { return }
            if self.presentedViewController is UIAlertController { return }
            let a = UIAlertController(title: "Error", message: text, preferredStyle: .alert)
            a.addAction(UIAlertAction(title: "OK", style: .default))
            self.present(a, animated: true)
        }
    }
    
    func wireInput() {
        inputBar.onSend = { [weak self] text in
            guard let self else { return }
            let lat = self.lastCoordinate?.latitude
            let lon = self.lastCoordinate?.longitude
            print("[Chat] will send:", text, "lat:", lat ?? .nan, "lon:", lon ?? .nan) // 🔎
            self.vm.send(text: text, latitude: lat, longitude: lon)
        }
    }

    func scrollToBottom(animated: Bool) {
        let rows = tableView.numberOfRows(inSection: 0)
        guard rows > 0 else { return }
        let ip = IndexPath(row: rows - 1, section: 0)
        tableView.scrollToRow(at: ip, at: .bottom, animated: animated)
    }
    internal override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        adjustTableInsets()
    }
}

// MARK: - Keyboard
private extension ChatViewController {
    func registerKeyboard() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(kbChange(_:)),
                                               name: UIResponder.keyboardWillChangeFrameNotification,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(kbHide(_:)),
                                               name: UIResponder.keyboardWillHideNotification,
                                               object: nil)
    }

    @objc func kbChange(_ note: Notification) {
        guard
            let info = note.userInfo,
            let frame = info[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect,
            let dur = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }

        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)
        let kb = view.convert(frame, from: nil)
        let overlap = max(0, view.bounds.maxY - kb.minY)

        inputBottomC.constant = -overlap
        UIView.animate(withDuration: dur, delay: 0, options: [curve]) { [weak self] in
            self?.view.layoutIfNeeded()
            self?.adjustTableInsets()
            self?.scrollToBottom(animated: false)
        }
    }
    
    @objc func kbHide(_ note: Notification) {
        guard
            let info = note.userInfo,
            let dur = info[UIResponder.keyboardAnimationDurationUserInfoKey] as? Double,
            let curveRaw = info[UIResponder.keyboardAnimationCurveUserInfoKey] as? UInt
        else { return }
        let curve = UIView.AnimationOptions(rawValue: curveRaw << 16)

        inputBottomC.constant = 0
        UIView.animate(withDuration: dur, delay: 0, options: [curve]) { [weak self] in
            self?.view.layoutIfNeeded()
            self?.adjustTableInsets()
        }
    }
    private func adjustTableInsets() {
        let h = inputBar.systemLayoutSizeFitting(UIView.layoutFittingCompressedSize).height
        let safe = view.safeAreaInsets.bottom
        tableView.contentInset.bottom = h + safe
        tableView.scrollIndicatorInsets.bottom = h + safe
    }
}

// MARK: - Localization
private extension ChatViewController {
    func registerLangObserver() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(onLangChanged),
                                               name: .appLanguageDidChange,
                                               object: nil)
    }
    @objc func onLangChanged() {
        header.titleLabel.text = "chats.title".localize()
        inputBar.refreshLocalization()
    }
    
    func debugPing() {
        let url = URL(string: "http://129.212.141.65:8000/")!
        URLSession.shared.dataTask(with: url) { _, resp, err in
            if let err = err {
                print("[Ping] ❌", err.localizedDescription)
                return
            }
            print("[Ping] ✅", (resp as? HTTPURLResponse)?.statusCode ?? -1)
        }.resume()
    }
}
