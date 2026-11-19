import Foundation
import FirebaseAuth

final class LoginViewModel {
    var login: String = "" { didSet { recalc() } }
    var password: String = "" { didSet { recalc() } }
    
    var isSubmitEnabled: ((Bool) -> Void)?
    var isLoading: ((Bool) -> Void)?
    var errorText: ((String?) -> Void)?
    var onSuccess: ((UserRecord) -> Void)?

    private let auth: AuthServicing
    init(auth: AuthServicing = AuthService()) { self.auth = auth }

    private func recalc() {
        let ok = !login.trimmingCharacters(in: .whitespaces).isEmpty &&
                 !password.isEmpty && password.count >= 6
        isSubmitEnabled?(ok)
    }

    func submit() {
        isLoading?(true)
        errorText?(nil)
        auth.signIn(email: login, password: password) { [weak self] result in
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
        case AuthErrorCode.wrongPassword.rawValue: return "Wrong password"
        case AuthErrorCode.invalidEmail.rawValue: return "Invalid email"
        case AuthErrorCode.userNotFound.rawValue: return "User not found"
        default: return error.localizedDescription
        }
    }
}
