import Foundation
import FirebaseAuth
import Firebase

final class RegisterViewModel {
    var firstName: String = "" { didSet { recalc() } }
    var lastName: String = "" { didSet { recalc() } }
    var role: String = "" { didSet { } }
    var login: String = "" { didSet { recalc() } }
    var password: String = "" { didSet { recalc() } }
    var passwordRepeat: String = "" { didSet { recalc() } }
    
    var isSubmitEnabled: ((Bool) -> Void)?
    var passwordMismatchVisible: ((Bool) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var errorText: ((String?) -> Void)?
    var onSuccess: ((UserRecord) -> Void)?

    private let auth: AuthServicing
    init(auth: AuthServicing = AuthService()) { self.auth = auth }

    private func recalc() {
        let hasNames = !firstName.trimmingCharacters(in: .whitespaces).isEmpty &&
                       !lastName.trimmingCharacters(in: .whitespaces).isEmpty
        let loginOK = !login.trimmingCharacters(in: .whitespaces).isEmpty
        let passOK = password.count >= 6
        let same = (!password.isEmpty || !passwordRepeat.isEmpty) ? (password == passwordRepeat) : false
        passwordMismatchVisible?(!same && (!password.isEmpty || !passwordRepeat.isEmpty))
        isSubmitEnabled?(hasNames && loginOK && passOK && same)
    }

    func submit() {
        isLoading?(true)
        errorText?(nil)
        auth.signUp(email: login, password: password, firstName: firstName, lastName: lastName, role: role.isEmpty ? nil : role) { [weak self] result in
            guard let self else { return }
            self.isLoading?(false)
            switch result {
            case .success(let record): self.onSuccess?(record)
            case .failure(let err):    self.errorText?(Self.map(err))
            }
        }
    }

    private static func map(_ error: Error) -> String {
        let ns = error as NSError
        switch ns.code {
        case AuthErrorCode.emailAlreadyInUse.rawValue: return "Email already in use"
        case AuthErrorCode.invalidEmail.rawValue: return "Invalid email"
        case AuthErrorCode.weakPassword.rawValue: return "Weak password"
        default: return error.localizedDescription
        }
    }
}
