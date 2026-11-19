import UIKit
import DGis

final class SearchPanelViewController: UIViewController,
                                       UITableViewDataSource,
                                       UITableViewDelegate,
                                       UITextFieldDelegate {
    private let searchInput = EditableSearchFieldView()
    private let cancelButton = UIButton(type: .system)
    private let tableView = UITableView(frame: .zero, style: .plain)
    
    var searchManager: ISearchManager?
    
    private var searchBuilder: SearchQueryBuilder?
    private var suggests: [Suggest] = []
    private var suggestCancellable: DGis.Cancellable?
    private var addressCache: [Int: String] = [:]
    private var querySeq: Int = 0
    
    var onSelectObject: ((DirectoryObject) -> Void)?
    var onCancel: (() -> Void)?
    var onRequestVoiceCapture: ((_ completion: @escaping (String) -> Void) -> Void)?
    var onRequestExpandToHigh: (() -> Void)?
    
    var initialQuery: String? {
        didSet { if isViewLoaded { applyInitialQuery() } }
    }
    // MARK: - Lifecycle
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        DispatchQueue.main.async {
            self.searchInput.textField.becomeFirstResponder()
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        searchInput.textField.delegate = self
        searchInput.textField.placeholder = "search.placeholder".localize()
        searchInput.textField.addTarget(self, action: #selector(onTextChanged(_:)), for: .editingChanged)
        
        searchInput.onMicTap = { [weak self] in
            guard let self else { return }
            self.view.endEditing(true)
            self.onRequestVoiceCapture? { [weak self] text in
                guard let self else { return }
                let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
                guard !trimmed.isEmpty else { return }
                self.setQueryAndSearch(trimmed)
            }
        }
        
        var cfg = UIButton.Configuration.plain()
        var title = AttributedString("cancel".localize())
        title.font = .systemFont(ofSize: 16, weight: .semibold)
        cfg.attributedTitle = title
        cfg.contentInsets = NSDirectionalEdgeInsets(top: 4, leading: 6, bottom: 4, trailing: 6)
        cancelButton.configuration = cfg
        cancelButton.tintColor = DesignTokens.neon2
        cancelButton.setContentHuggingPriority(.required, for: .horizontal)
        cancelButton.setContentCompressionResistancePriority(.required, for: .horizontal)
        cancelButton.widthAnchor.constraint(greaterThanOrEqualToConstant: 44).isActive = true
        cancelButton.addAction(UIAction { [weak self] _ in
            self?.onCancel?()
        }, for: .touchUpInside)
        
        let topBar = UIStackView(arrangedSubviews: [searchInput, cancelButton])
        topBar.axis = .horizontal
        topBar.alignment = .fill
        topBar.spacing = 6
        topBar.setContentHuggingPriority(.required, for: .vertical)
        topBar.setContentCompressionResistancePriority(.required, for: .vertical)
        
        searchInput.setContentHuggingPriority(.defaultLow, for: .horizontal)
        searchInput.setContentCompressionResistancePriority(.defaultHigh, for: .horizontal)
        
        tableView.dataSource = self
        tableView.delegate = self
        tableView.backgroundColor = .clear
        tableView.estimatedRowHeight = 68
        tableView.rowHeight = UITableView.automaticDimension
        tableView.sectionHeaderHeight = 0.001
        tableView.sectionFooterHeight = 0.001
        tableView.tableFooterView = UIView(frame: .init(x: 0, y: 0, width: 1, height: 0.01))
        tableView.register(SuggestTripleLineCell.self, forCellReuseIdentifier: SuggestTripleLineCell.reuseID)
        
        let stack = UIStackView(arrangedSubviews: [topBar, tableView])
        stack.axis = .vertical
        stack.spacing = 12
        
        view.addSubview(stack)
        stack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            stack.topAnchor.constraint(equalTo: view.topAnchor, constant: 12),
            stack.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 12),
            stack.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -12),
            stack.bottomAnchor.constraint(equalTo: view.bottomAnchor, constant: -12)
        ])
        
        applyInitialQuery()
    }
    
    // MARK: - Helpers
    private func applyInitialQuery() {
        let text = initialQuery ?? ""
        searchInput.textField.text = text
        onTextChanged(searchInput.textField)
    }
    
    func setQueryAndSearch(_ text: String) {
        searchInput.textField.text = text
        onTextChanged(searchInput.textField)
    }
    
    // MARK: - Text & Suggest
    @objc private func onTextChanged(_ tf: UITextField) {
        let text = (tf.text ?? "").trimmingCharacters(in: .whitespacesAndNewlines)
        searchInput.updateRightButtons(forText: text)
        
        guard !text.isEmpty else {
            suggestCancellable?.cancel()
            suggests.removeAll()
            tableView.reloadData()
            searchBuilder = nil
            return
        }
        
        searchBuilder = SearchQueryBuilder.fromQueryText(queryText: text)
        let sb = SuggestQueryBuilder.fromQueryText(queryText: text).setLimit(limit: 10)
        let q = sb.build()
        
        let mySeq = { querySeq &+= 1; return querySeq }()
        suggestCancellable?.cancel()
        
        guard let sm = searchManager else { return }
        let future = sm.suggest(query: q)
        suggestCancellable = future.sinkOnMainThread(
            receiveValue: { [weak self] (result: SuggestResult) in
                guard let self else { return }
                guard mySeq == self.querySeq else { return }
                self.suggests = result.suggests
                self.tableView.reloadData()
            },
            failure: { error in
                print("🟥 suggest error:", error)
            }
        )
        print("Step1 → builder from text:", text)
    }
    
    // MARK: - UITextFieldDelegate
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder()
        print("🔎 start search for:", textField.text ?? "")
        return true
    }
    
    // MARK: - Table
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int { suggests.count }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(
            withIdentifier: SuggestTripleLineCell.reuseID,
            for: indexPath
        ) as? SuggestTripleLineCell else {
            assertionFailure("Wrong cell registered for \(SuggestTripleLineCell.reuseID)")
            return UITableViewCell()
        }
        
        let s = suggests[indexPath.row]
        cell.titleLabel.text = s.title.text
        cell.subtitleLabel.text = s.subtitle.text
        
        if let cached = addressCache[s.hashValue] {
            cell.addressLabel.text = cached
            cell.addressLabel.isHidden = cached.isEmpty
        } else {
            var addr = ""
            if case .objectHandler(let h) = s.handler, let obj = h?.item {
                addr = obj.address?.addressComment ?? ""
            }
            addressCache[s.hashValue] = addr
            cell.addressLabel.text = addr
            cell.addressLabel.isHidden = addr.isEmpty
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let s = suggests[indexPath.row]
        switch s.handler {
        case .objectHandler(let h):
            if let obj = h?.item {
                onSelectObject?(obj)
            }
        case .performSearchHandler(let h):
            if let _ = h?.searchQuery {
                print("🔎 performSearchHandler tapped — тут позже откроем экран результатов")
                // TODO: onPerformSearch?(query)
            }
        case .incompleteTextHandler(let h):
            if let q = h?.queryText {
                searchInput.textField.text = q
                onTextChanged(searchInput.textField)
            }
        default:
            break
        }
    }
}
