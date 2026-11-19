import UIKit
import FirebaseAuth
import UserNotifications

final class ProfileTabViewController: UIViewController {
    private let header = HeaderBarView(title: "profile.title".localize())
    
    private var isNotificationsOn = true
    private var isDarkModeOn = (ThemeManager.shared.current == .dark)
    private var languageModal: LanguageModalView?
    private var rowViews: [ProfileRowView] = []
    
    private let nameLabel = UILabel()
    private let roleLabel = UILabel()
    private let avatarImageView = UIImageView()
    private var logoutButton: UIButton?
    private weak var notificationsRowView: ProfileRowView?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground
        
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        header.backButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: false)}, for: .touchUpInside)
        header.rightButton.setImage(UIImage(systemName: "slider.vertical.3"), for: .normal)
        header.rightButton.tintColor = .white
        header.rightButton.addAction(UIAction { [weak self] _ in self?.openEditProfile() }, for: .touchUpInside)
        
        let content = UIStackView()
        content.axis = .vertical
        content.alignment = .fill
        content.spacing = 16
        content.isLayoutMarginsRelativeArrangement = true
        content.layoutMargins = .init(top: 8, left: 16, bottom: 24, right: 16)
        
        view.addSubview(content)
        content.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            content.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
            content.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            content.trailingAnchor.constraint(equalTo: view.trailingAnchor),
            content.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor)
        ])
        
        let avatarWrap = UIView()
        avatarWrap.translatesAutoresizingMaskIntoConstraints = false
        avatarWrap.heightAnchor.constraint(equalToConstant: 112).isActive = true
        avatarWrap.widthAnchor.constraint(equalTo: avatarWrap.heightAnchor).isActive = true
        
        avatarImageView.contentMode = .scaleAspectFill
        avatarImageView.layer.masksToBounds = true
        avatarImageView.translatesAutoresizingMaskIntoConstraints = false
        avatarWrap.addSubview(avatarImageView)
        NSLayoutConstraint.activate([
            avatarImageView.topAnchor.constraint(equalTo: avatarWrap.topAnchor),
            avatarImageView.leadingAnchor.constraint(equalTo: avatarWrap.leadingAnchor),
            avatarImageView.trailingAnchor.constraint(equalTo: avatarWrap.trailingAnchor),
            avatarImageView.bottomAnchor.constraint(equalTo: avatarWrap.bottomAnchor)
        ])
        
        nameLabel.font = .systemFont(ofSize: 22, weight: .semibold)
        nameLabel.textAlignment = .center
        
        roleLabel.textColor = .secondaryLabel
        roleLabel.font = .systemFont(ofSize: 14)
        roleLabel.textAlignment = .center
        
        let head = UIStackView(arrangedSubviews: [avatarWrap, nameLabel, roleLabel])
        head.axis = .vertical
        head.alignment = .center
        head.spacing = 8
        content.addArrangedSubview(head)
        
        let kinds: [ProfileRowKind] = [
            .notifications(isOn: isNotificationsOn),
            .languages(current: currentLanguageText()),
            .darkMode(isOn: isDarkModeOn)
        ]
        
        let list = UIStackView()
        list.axis = .vertical
        list.alignment = .fill
        list.spacing = 10
        content.addArrangedSubview(list)
        
        var darkRowView: ProfileRowView?
        var langRowView: ProfileRowView?
        
        for kind in kinds {
            let row = ProfileRowView(kind: kind)
            
            switch kind {
            case .notifications:
                notificationsRowView = row
                row.onToggleChanged = { [weak self] isOn in
                    self?.handleNotificationToggle(isOn: isOn)
                }
                syncNotificationSwitchFromSystem()
                
            case .languages:
                langRowView = row
                row.addAction(UIAction { [weak self, weak row] _ in
                    guard let self else { return }
                    let modal = LanguageModalView()
                    self.languageModal = modal
                    modal.translatesAutoresizingMaskIntoConstraints = false
                    self.view.addSubview(modal)
                    self.view.bringSubviewToFront(modal)
                    NSLayoutConstraint.activate([
                        modal.centerXAnchor.constraint(equalTo: self.view.centerXAnchor),
                        modal.centerYAnchor.constraint(equalTo: self.view.centerYAnchor),
                        modal.widthAnchor.constraint(equalTo: self.view.widthAnchor, multiplier: 0.8),
                        modal.heightAnchor.constraint(equalToConstant: 330)
                    ])
                    modal.onCancel = { [weak self] in
                        self?.languageModal?.removeFromSuperview(); self?.languageModal = nil
                    }
                    modal.onSubmit = { [weak self, weak row] lang in
                        guard let self else { return }
                        UserDefaults.standard.set([lang.rawValue], forKey: "AppleLanguages")
                        UserDefaults.standard.synchronize()
                        NotificationCenter.default.post(name: .appLanguageDidChange, object: nil)
                        self.updateTexts()
                        row?.setTitleText("settings.language".localize())
                        row?.setDetailText(self.currentLanguageText())
                        self.languageModal?.removeFromSuperview()
                        self.languageModal = nil
                    }
                }, for: .primaryActionTriggered)
                
            case .darkMode:
                darkRowView = row
                row.onToggleChanged = { [weak self, weak row] isOn in
                    guard let self else { return }
                    self.isDarkModeOn = isOn
                    ThemeManager.shared.set(isOn ? .dark : .light)
                    row?.setDarkModeState(isOn)
                }
            }
            
            list.addArrangedSubview(row)
            rowViews.append(row)
        }
        
        let spacer = UIView()
        spacer.setContentHuggingPriority(.defaultLow, for: .vertical)
        spacer.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        content.addArrangedSubview(spacer)
        
        let logout = UIButton(type: .system)
        var cfg = UIButton.Configuration.filled()
        cfg.title = "logout".localize()
        cfg.baseBackgroundColor = .systemRed
        cfg.baseForegroundColor = .white
        cfg.cornerStyle = .large
        cfg.contentInsets = .init(top: 12, leading: 16, bottom: 12, trailing: 16)
        logout.configuration = cfg
        logout.layer.cornerRadius = DesignTokens.cornerPill
        logout.layer.masksToBounds = true
        logout.addAction(UIAction { [weak self] _ in
            do { try Auth.auth().signOut() } catch {
                print("signOut error:", error)
            }
            UserProfileStore.shared.clear()
            AvatarStore.shared.clear()
            ChatLocalStore.shared.clear()
            self?.resetToAuth()
        }, for: .touchUpInside)
        self.logoutButton = logout
        
        content.addArrangedSubview(logout)
        logout.heightAnchor.constraint(greaterThanOrEqualToConstant: 48).isActive = true
        let footer = UIStackView()
        footer.axis = .vertical
        footer.alignment = .center
        footer.spacing = 6
        
        let versionLabel = UILabel()
        versionLabel.text = appVersionString()
        versionLabel.font = .monospacedSystemFont(ofSize: 12, weight: .semibold)
        versionLabel.textColor = .secondaryLabel
        versionLabel.textAlignment = .center
        
        let brandPill = UIView()
        brandPill.backgroundColor = .tertiarySystemBackground
        brandPill.layer.cornerRadius = DesignTokens.cornerPill
        brandPill.layer.borderColor = DesignTokens.neon2.cgColor
        brandPill.layer.borderWidth = 1
        
        let brandStack = UIStackView()
        brandStack.axis = .horizontal
        brandStack.alignment = .center
        brandStack.spacing = 8
        brandStack.isLayoutMarginsRelativeArrangement = true
        brandStack.layoutMargins = .init(top: 8, left: 14, bottom: 8, right: 14)
        
        let spark = UIImageView(image: UIImage(systemName: "sparkles"))
        spark.tintColor = DesignTokens.neon2
        
        let brandLabel = UILabel()
        let brandText = NSMutableAttributedString(string: "Aqyl Jol AI")
        brandText.addAttribute(.kern, value: 0.6, range: NSRange(location: 0, length: brandText.length))
        brandLabel.attributedText = brandText
        brandLabel.font = .systemFont(ofSize: 14, weight: .semibold)
        brandLabel.textColor = DesignTokens.neon2
        brandLabel.textAlignment = .center
        
        brandStack.addArrangedSubview(spark)
        brandStack.addArrangedSubview(brandLabel)
        
        brandPill.addSubview(brandStack)
        brandStack.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            brandStack.topAnchor.constraint(equalTo: brandPill.topAnchor),
            brandStack.leadingAnchor.constraint(equalTo: brandPill.leadingAnchor),
            brandStack.trailingAnchor.constraint(equalTo: brandPill.trailingAnchor),
            brandStack.bottomAnchor.constraint(equalTo: brandPill.bottomAnchor)
        ])
        
        content.addArrangedSubview(footer)
        footer.addArrangedSubview(versionLabel)
        footer.addArrangedSubview(brandPill)
        brandPill.heightAnchor.constraint(greaterThanOrEqualToConstant: 36).isActive = true
        
        darkRowView?.setDarkModeState(isDarkModeOn)
        langRowView?.setDetailText(currentLanguageText())
        langRowView?.setTitleText("settings.language".localize())
        
        updateTexts()
        applyProfileFromStore()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        applyProfileFromStore()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        avatarImageView.layer.cornerRadius = avatarImageView.bounds.width / 2
    }
    
    // MARK: - Helpers
    private func appVersionString() -> String {
        if let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            return "\(v) v"
        }
        return "1.0.0 v"
    }
    
    private func currentLanguageText() -> String {
        let code = (UserDefaults.standard.array(forKey: "AppleLanguages")?.first as? String) ?? "en"
        let locale = Locale(identifier: code)
        return locale.localizedString(forLanguageCode: code)?.capitalized ?? code
    }
    
    private func applyProfileFromStore() {
        guard let r = UserProfileStore.shared.load() else {
            nameLabel.text = " "
            roleLabel.text = " "
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.contentMode = .scaleAspectFit
            avatarImageView.tintColor = .systemGray
            return
        }
        
        let fullName = [r.firstName, r.lastName].joined(separator: " ").trimmingCharacters(in: .whitespaces)
        nameLabel.text = fullName.isEmpty ? " " : fullName
        
        if let role = r.role, !role.isEmpty {
            roleLabel.text = role
        } else {
            roleLabel.text = " "
        }
        
        if let img = AvatarStore.shared.load() {
            avatarImageView.image = img
            avatarImageView.contentMode = .scaleAspectFill
        } else {
            avatarImageView.image = UIImage(systemName: "person.crop.circle.fill")
            avatarImageView.contentMode = .scaleAspectFit
            avatarImageView.tintColor = .systemGray
        }
    }
    
    private func updateTexts() {
        header.titleLabel.text = "profile.title".localize()
        if let btn = logoutButton {
            if var cfg = btn.configuration {
                cfg.title = "logout".localize()
                btn.configuration = cfg
            } else {
                btn.setTitle("logout".localize(), for: .normal)
            }
        }
        rowViews.forEach { $0.refreshLocalization() }
    }
    
    private func openEditProfile() {
        let vc = EditProfileViewController()
        if let r = UserProfileStore.shared.load() {
            vc.initialFirstName = r.firstName
            vc.initialLastName  = r.lastName
            vc.initialRole      = r.role ?? ""
        }
        vc.initialAvatar = AvatarStore.shared.load()
        
        vc.onSave = { [weak self] _, _, _, savedImage in
            if let img = savedImage {
                self?.avatarImageView.image = img
                self?.avatarImageView.contentMode = .scaleAspectFill
            }
            self?.applyProfileFromStore()
        }
        vc.modalPresentationStyle = .fullScreen
        present(vc, animated: false)
    }
    
    private func resetToAuth() {
        guard let scene = view.window?.windowScene,
              let win = scene.windows.first else { return }
        let root = AuthRootViewController()
        UIView.transition(with: win, duration: 0.25, options: .transitionCrossDissolve, animations: {
            win.rootViewController = root
        })
    }
    
    private func syncNotificationSwitchFromSystem() {
        UNUserNotificationCenter.current().getNotificationSettings { [weak self] settings in
            guard let self = self else { return }
            let isAllowed: Bool
            switch settings.authorizationStatus {
            case .authorized, .provisional, .ephemeral:
                isAllowed = true
            case .denied, .notDetermined:
                isAllowed = false
            @unknown default:
                isAllowed = false
            }
            DispatchQueue.main.async {
                self.isNotificationsOn = isAllowed
                self.notificationsRowView?.setSwitchOn(isAllowed)
            }
        }
    }
    
    private func handleNotificationToggle(isOn: Bool) {
        let center = UNUserNotificationCenter.current()
        center.getNotificationSettings { [weak self] settings in
            guard let self else { return }
            
            if isOn {
                switch settings.authorizationStatus {
                case .notDetermined:
                    center.requestAuthorization(options: [.alert, .badge, .sound]) { granted, _ in
                        DispatchQueue.main.async {
                            if granted {
                                UIApplication.shared.registerForRemoteNotifications()
                                self.setUserPrefNotificationsEnabled(true)
                                self.isNotificationsOn = true
                                self.notificationsRowView?.setSwitchOn(true)
                            } else {
                                self.setUserPrefNotificationsEnabled(false)
                                self.isNotificationsOn = false
                                self.notificationsRowView?.setSwitchOn(false)
                            }
                        }
                    }
                case .denied:
                    DispatchQueue.main.async {
                        self.notificationsRowView?.setSwitchOn(false)
                        self.setUserPrefNotificationsEnabled(false)
                        self.isNotificationsOn = false
                        self.presentNotificationsDeniedAlert()
                    }
                case .authorized, .provisional, .ephemeral:
                    DispatchQueue.main.async {
                        UIApplication.shared.registerForRemoteNotifications()
                        self.setUserPrefNotificationsEnabled(true)
                        self.isNotificationsOn = true
                        self.notificationsRowView?.setSwitchOn(true)
                    }
                @unknown default:
                    DispatchQueue.main.async {
                        self.setUserPrefNotificationsEnabled(false)
                        self.isNotificationsOn = false
                        self.notificationsRowView?.setSwitchOn(false)
                    }
                }
            } else {
                DispatchQueue.main.async {
                    self.setUserPrefNotificationsEnabled(false)
                    self.isNotificationsOn = false
                    UIApplication.shared.unregisterForRemoteNotifications()
                    center.removeAllPendingNotificationRequests()
                    center.removeAllDeliveredNotifications()
                    self.notificationsRowView?.setSwitchOn(false)
                }
            }
        }
    }
    
    private func presentNotificationsDeniedAlert() {
        let a = UIAlertController(
            title: "settings.notifications".localize(),
            message: "notifications.denied.explain".localize(),
            preferredStyle: .alert
        )
        a.addAction(UIAlertAction(title: "common.cancel".localize(), style: .cancel))
        a.addAction(UIAlertAction(title: "settings.open".localize(), style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }))
        present(a, animated: true)
    }
    
    private func presentTurnOffInfoAlert() {
        let a = UIAlertController(
            title: "settings.notifications".localize(),
            message: "notifications.turnoff.info".localize(),
            preferredStyle: .alert
        )
        a.addAction(UIAlertAction(title: "common.ok".localize(), style: .default))
        a.addAction(UIAlertAction(title: "settings.open".localize(), style: .default, handler: { _ in
            if let url = URL(string: UIApplication.openSettingsURLString),
               UIApplication.shared.canOpenURL(url) {
                UIApplication.shared.open(url)
            }
        }))
        present(a, animated: true)
    }
    
    private let notificationsPrefKey = "settings.notifications.enabled"
    
    private func userPrefNotificationsEnabled() -> Bool {
        if UserDefaults.standard.object(forKey: notificationsPrefKey) == nil { return true }
        return UserDefaults.standard.bool(forKey: notificationsPrefKey)
    }
    private func setUserPrefNotificationsEnabled(_ on: Bool) {
        UserDefaults.standard.set(on, forKey: notificationsPrefKey)
    }
}
