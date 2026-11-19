import UIKit
import PhotosUI

final class EditProfileViewController: UIViewController, UINavigationControllerDelegate {
    // MARK: - Public API (inject current values if needed)
    var initialFirstName: String = "Izbassar"
    var initialLastName: String  = "Orynbassar"
    var initialRole: String      = "iOS Developer"
    var initialAvatar: UIImage?  = nil
    
    var onSave: ((String, String, String, UIImage?) -> Void)?
    
    // MARK: - UI
    private let header = HeaderBarView(title: "edit.title".localize())
    
    private let scroll = UIScrollView()
    private let content = UIStackView()
    
    private let avatarWrap = UIView()
    private let avatarView = UIImageView()
    private let avatarEditButton = UIButton(type: .system)
    
    private let firstNameField = LabeledFieldView()
    private let lastNameField  = LabeledFieldView()
    private let roleField      = LabeledFieldView()
    
    private var saveButton: UIButton { header.rightButton }
    
    private var keyboardObserverTokens: [NSObjectProtocol] = []
    
    // MARK: - Life cycle
    override func viewDidLoad() {
        super.viewDidLoad()
        view.backgroundColor = .systemBackground

        buildHeader()
        buildScroll()
        buildAvatar()
        buildFields()
        applyInitialValues()
        wireActions()
        updateTexts()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        registerKeyboard()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        unregisterKeyboard()
    }
}

// MARK: - Build UI
private extension EditProfileViewController {
    func buildHeader() {
        view.addSubview(header)
        header.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            header.topAnchor.constraint(equalTo: view.topAnchor),
            header.leadingAnchor.constraint(equalTo: view.leadingAnchor),
            header.trailingAnchor.constraint(equalTo: view.trailingAnchor)
        ])
        
        header.backButton.addAction(UIAction { [weak self] _ in self?.dismiss(animated: false) }, for: .touchUpInside)
        
        var cfg = UIButton.Configuration.plain()
        cfg.image = UIImage(systemName: "checkmark.circle.fill")
        cfg.preferredSymbolConfigurationForImage = UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
        cfg.baseForegroundColor = DesignTokens.neon2
        cfg.contentInsets = .init(top: 6, leading: 8, bottom: 6, trailing: 8)
        saveButton.configuration = cfg
        saveButton.accessibilityLabel = "save".localize()
        saveButton.addAction(UIAction { [weak self] _ in self?.didTapSave() }, for: .touchUpInside)
        saveButton.isEnabled = true
    }
    
    func buildScroll() {
        scroll.alwaysBounceVertical = true
        view.addSubview(scroll)
        scroll.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            scroll.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 12),
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
            content.topAnchor.constraint(equalTo: scroll.contentLayoutGuide.topAnchor, constant: 16),
            content.leadingAnchor.constraint(equalTo: scroll.frameLayoutGuide.leadingAnchor, constant: 20),
            content.trailingAnchor.constraint(equalTo: scroll.frameLayoutGuide.trailingAnchor, constant: -20),
            content.bottomAnchor.constraint(equalTo: scroll.contentLayoutGuide.bottomAnchor, constant: -24)
        ])
        
        let tap = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboard))
        tap.cancelsTouchesInView = false
        scroll.addGestureRecognizer(tap)
    }

    func buildAvatar() {
        avatarWrap.translatesAutoresizingMaskIntoConstraints = false
        avatarWrap.layer.cornerRadius = 56
        avatarWrap.heightAnchor.constraint(equalToConstant: 112).isActive = true
        avatarWrap.widthAnchor.constraint(equalTo: avatarWrap.heightAnchor).isActive = true
        
        avatarView.contentMode = .scaleAspectFit
        avatarView.layer.masksToBounds = true
        avatarView.backgroundColor = .secondarySystemBackground
        avatarView.translatesAutoresizingMaskIntoConstraints = false

        avatarWrap.addSubview(avatarView)
        NSLayoutConstraint.activate([
            avatarView.topAnchor.constraint(equalTo: avatarWrap.topAnchor),
            avatarView.leadingAnchor.constraint(equalTo: avatarWrap.leadingAnchor),
            avatarView.trailingAnchor.constraint(equalTo: avatarWrap.trailingAnchor),
            avatarView.bottomAnchor.constraint(equalTo: avatarWrap.bottomAnchor)
        ])
        avatarWrap.layoutIfNeeded()
        avatarView.layer.cornerRadius = 56
        
        var ebCfg = UIButton.Configuration.filled()
        ebCfg.image = UIImage(systemName: "camera.fill")
        ebCfg.baseBackgroundColor = DesignTokens.neon2
        ebCfg.baseForegroundColor = .white
        ebCfg.cornerStyle = .capsule
        ebCfg.contentInsets = .init(top: 4, leading: 6, bottom: 4, trailing: 6)
        avatarEditButton.configuration = ebCfg
        avatarEditButton.translatesAutoresizingMaskIntoConstraints = false

        let avatarStack = UIStackView()
        avatarStack.axis = .vertical
        avatarStack.alignment = .center
        avatarStack.spacing = 8

        avatarWrap.addSubview(avatarEditButton)
        NSLayoutConstraint.activate([
            avatarEditButton.trailingAnchor.constraint(equalTo: avatarWrap.trailingAnchor, constant: 4),
            avatarEditButton.bottomAnchor.constraint(equalTo: avatarWrap.bottomAnchor, constant: 4)
        ])
        
        let nameRole = UILabel()
        nameRole.text = "edit.avatar".localize()
        nameRole.font = .systemFont(ofSize: 13)
        nameRole.textColor = .secondaryLabel

        avatarStack.addArrangedSubview(avatarWrap)
        avatarStack.addArrangedSubview(nameRole)

        content.addArrangedSubview(avatarStack)
    }
    
    func buildFields() {
        firstNameField.setStyle(title: "edit.firstName".localize(), placeholder: "edit.firstName.placeholder".localize())
        lastNameField.setStyle(title: "edit.lastName".localize(), placeholder: "edit.lastName.placeholder".localize())
        roleField.setStyle(title: "edit.role".localize(), placeholder: "edit.role.placeholder".localize())

        [firstNameField, lastNameField, roleField].forEach { field in
            content.addArrangedSubview(field)
        }
    }
    
    func applyInitialValues() {
        if let record = UserProfileStore.shared.load() {
            initialFirstName = record.firstName
            initialLastName  = record.lastName
            initialRole      = record.role ?? ""
        }
        
        firstNameField.text = initialFirstName
        lastNameField.text  = initialLastName
        roleField.text      = initialRole
        
        if let img = initialAvatar ?? AvatarStore.shared.load() {
            avatarView.image = img
            avatarView.contentMode = .scaleAspectFill
        } else {
            avatarView.image = UIImage(systemName: "person.fill")
            avatarView.tintColor = .systemGray
            avatarView.contentMode = .scaleAspectFill
        }
        
        validateForm()
    }
    
    func wireActions() {
        avatarEditButton.addAction(UIAction { [weak self] _ in self?.presentImagePicker() }, for: .touchUpInside)
        firstNameField.onEditingChanged = { [weak self] _ in self?.validateForm() }
        lastNameField.onEditingChanged  = { [weak self] _ in self?.validateForm() }
        roleField.onEditingChanged      = { [weak self] _ in self?.validateForm() }
    }
}

// MARK: - Localization
extension EditProfileViewController {
    func updateTexts() {
        header.titleLabel.text = "edit.title".localize()
        
        if var cfg = saveButton.configuration {
            cfg.title = nil
            cfg.image = UIImage(systemName: "checkmark.circle.fill")
            cfg.preferredSymbolConfigurationForImage =
                UIImage.SymbolConfiguration(pointSize: 18, weight: .semibold)
            cfg.baseForegroundColor = DesignTokens.neon2
            saveButton.configuration = cfg
        } else {
            saveButton.setTitle(nil, for: .normal)
            saveButton.setImage(UIImage(systemName: "checkmark.circle.fill"), for: .normal)
            saveButton.tintColor = DesignTokens.neon2
            saveButton.contentEdgeInsets = UIEdgeInsets(top: 6, left: 8, bottom: 6, right: 8)
        }
        saveButton.accessibilityLabel = "save".localize()
        
        firstNameField.setStyle(title: "edit.firstName".localize(),
                                placeholder: "edit.firstName.placeholder".localize())
        lastNameField.setStyle(title: "edit.lastName".localize(),
                               placeholder: "edit.lastName.placeholder".localize())
        roleField.setStyle(title: "edit.role".localize(),
                           placeholder: "edit.role.placeholder".localize())
    }
}

// MARK: - Actions
private extension EditProfileViewController {
    func didTapSave() {
        let fn = firstNameField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let ln = lastNameField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        let rl = roleField.text.trimmingCharacters(in: .whitespacesAndNewlines)
        
        saveButton.isEnabled = false
        let svc = AuthService()
        svc.updateProfile(firstName: fn, lastName: ln, role: rl.isEmpty ? nil : rl) { [weak self] result in
            guard let self else { return }
            self.saveButton.isEnabled = true
            switch result {
            case .success:
                if var record = UserProfileStore.shared.load() {
                    record.firstName = fn
                    record.lastName  = ln
                    record.role      = rl.isEmpty ? nil : rl
                    UserProfileStore.shared.save(record)
                }
                
                if let img = self.avatarView.image {
                    AvatarStore.shared.save(img) { [weak self] in
                        guard let self else { return }
                        self.onSave?(fn, ln, rl, img)
                        self.dismiss(animated: false)
                    }
                } else {
                    self.onSave?(fn, ln, rl, nil)
                    self.dismiss(animated: false)
                }
            case .failure(let error):
                self.showToast(error.localizedDescription)
            }
        }
    }
    
    func validateForm() {
        let allFilled = !firstNameField.text.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !lastNameField.text.trimmingCharacters(in: .whitespaces).isEmpty &&
                        !roleField.text.trimmingCharacters(in: .whitespaces).isEmpty
        saveButton.isEnabled = allFilled
        saveButton.alpha = allFilled ? 1.0 : 0.5
    }
    
    @objc func dismissKeyboard() { view.endEditing(false) }
}

// MARK: - Image Picking
extension EditProfileViewController: UIImagePickerControllerDelegate {
    func presentImagePicker() {
        let sheet = UIAlertController(title: nil, message: nil, preferredStyle: .actionSheet)
        sheet.addAction(UIAlertAction(title: "edit.photo.choose".localize(), style: .default, handler: { [weak self] _ in
            self?.pickFromLibrary()
        }))
        if UIImagePickerController.isSourceTypeAvailable(.camera) {
            sheet.addAction(UIAlertAction(title: "edit.photo.camera".localize(), style: .default, handler: { [weak self] _ in
                self?.pickFromCamera()
            }))
        }
        sheet.addAction(UIAlertAction(title: "cancel".localize(), style: .cancel))
        present(sheet, animated: true)
    }
    
    func pickFromLibrary() {
        let picker = UIImagePickerController()
        picker.sourceType = .photoLibrary
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func pickFromCamera() {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.cameraCaptureMode = .photo
        picker.delegate = self
        present(picker, animated: true)
    }
    
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        picker.dismiss(animated: false)
        if let img = info[.editedImage] as? UIImage ?? info[.originalImage] as? UIImage {
            avatarView.image = img
        }
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: false)
    }
}

// MARK: - Keyboard handling
private extension EditProfileViewController {
    func registerKeyboard() {
        let willShow = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillShowNotification, object: nil, queue: .main) { [weak self] note in
            guard let self, let frame = note.userInfo?[UIResponder.keyboardFrameEndUserInfoKey] as? CGRect else { return }
            let bottom = frame.height - self.view.safeAreaInsets.bottom
            self.scroll.contentInset.bottom = bottom + 12
            self.scroll.verticalScrollIndicatorInsets.bottom = bottom
        }
        let willHide = NotificationCenter.default.addObserver(forName: UIResponder.keyboardWillHideNotification, object: nil, queue: .main) { [weak self] _ in
            guard let self else { return }
            self.scroll.contentInset.bottom = 0
            self.scroll.verticalScrollIndicatorInsets.bottom = 0
        }
        keyboardObserverTokens = [willShow, willHide]
    }
    
    func unregisterKeyboard() {
        keyboardObserverTokens.forEach { NotificationCenter.default.removeObserver($0) }
        keyboardObserverTokens.removeAll()
    }
}

// MARK: - LabeledFieldView
private final class LabeledFieldView: UIView, UITextFieldDelegate {
    var onEditingChanged: ((String) -> Void)?
    
    private let titleLabel = UILabel()
    private let fieldBG = UIView()
    private let textField = UITextField()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        build()
    }
    required init?(coder: NSCoder) { fatalError("init(coder:) has not been implemented") }
    
    func setStyle(title: String, placeholder: String) {
        titleLabel.text = title
        textField.attributedPlaceholder = NSAttributedString(string: placeholder, attributes: [
            .foregroundColor: UIColor.tertiaryLabel
        ])
    }
    
    var text: String {
        get { textField.text ?? "" }
        set { textField.text = newValue }
    }
    
    private func build() {
        titleLabel.font = .systemFont(ofSize: 13, weight: .semibold)
        titleLabel.textColor = DesignTokens.labelDim
        
        fieldBG.backgroundColor = .secondarySystemBackground
        fieldBG.layer.cornerRadius = DesignTokens.cornerPill
        fieldBG.layer.borderColor = DesignTokens.stroke.cgColor
        fieldBG.layer.borderWidth = 1
        
        textField.font = .systemFont(ofSize: 16)
        textField.textColor = UIColor.label
        textField.clearButtonMode = .whileEditing
        textField.autocapitalizationType = .words
        textField.autocorrectionType = .no
        textField.returnKeyType = .done
        textField.delegate = self
        textField.addTarget(self, action: #selector(editingChanged), for: .editingChanged)
        
        let h = UIStackView()
        h.axis = .horizontal
        h.alignment = .center
        h.spacing = 8
        h.isLayoutMarginsRelativeArrangement = true
        h.layoutMargins = .init(top: 12, left: 14, bottom: 12, right: 14)
        
        h.addArrangedSubview(textField)
        
        addSubview(titleLabel)
        addSubview(fieldBG)
        addSubview(h)
        
        titleLabel.translatesAutoresizingMaskIntoConstraints = false
        fieldBG.translatesAutoresizingMaskIntoConstraints = false
        h.translatesAutoresizingMaskIntoConstraints = false
        
        NSLayoutConstraint.activate([
            titleLabel.topAnchor.constraint(equalTo: topAnchor),
            titleLabel.leadingAnchor.constraint(equalTo: leadingAnchor, constant: 4),
            titleLabel.trailingAnchor.constraint(lessThanOrEqualTo: trailingAnchor),
            
            fieldBG.topAnchor.constraint(equalTo: titleLabel.bottomAnchor, constant: 6),
            fieldBG.leadingAnchor.constraint(equalTo: leadingAnchor),
            fieldBG.trailingAnchor.constraint(equalTo: trailingAnchor),
            fieldBG.heightAnchor.constraint(greaterThanOrEqualToConstant: 48),
            
            h.topAnchor.constraint(equalTo: fieldBG.topAnchor),
            h.leadingAnchor.constraint(equalTo: fieldBG.leadingAnchor),
            h.trailingAnchor.constraint(equalTo: fieldBG.trailingAnchor),
            h.bottomAnchor.constraint(equalTo: fieldBG.bottomAnchor),
            
            bottomAnchor.constraint(equalTo: fieldBG.bottomAnchor)
        ])
    }
    
    func textFieldDidBeginEditing(_ textField: UITextField) {
        fieldBG.layer.borderColor = DesignTokens.neon2.cgColor
        fieldBG.layer.borderWidth = 1.5
    }
    func textFieldDidEndEditing(_ textField: UITextField) {
        fieldBG.layer.borderColor = DesignTokens.stroke.cgColor
        fieldBG.layer.borderWidth = 1
    }
    @objc private func editingChanged() {
        onEditingChanged?(textField.text ?? "")
    }
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        textField.resignFirstResponder(); return true
    }
}
